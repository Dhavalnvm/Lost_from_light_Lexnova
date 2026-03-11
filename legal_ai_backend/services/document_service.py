import os
import json
import re
import aiofiles
from pathlib import Path
from typing import Optional
from fastapi import UploadFile

from config.settings import settings
from core.document_parser import document_parser
from core.embeddings import embeddings_manager
from core.vector_store import vector_store
from core.task_router import get_client
from utils.helpers import generate_document_id, is_allowed_file, chunk_text, clean_text
from utils.logging import app_logger as logger
from models.schemas import (
    UploadDocumentResponse,
    DocumentSummaryResponse,
    ClauseItem,
    ExplanationMode,
)

_document_registry: dict = {}

SUMMARY_SYSTEM_PROMPT = """You are a legal document expert. Your role is to analyze legal documents
and explain them clearly. Always be accurate, thorough, and helpful.
Never give personal legal advice — instead explain what the document says."""

SUMMARY_QUERIES = [
    "what is this document about and its main purpose",
    "key obligations and duties of the parties",
    "rights and entitlements of each party",
    "important clauses terms and conditions",
    "payment penalties termination and liability",
]


def _extract_json(response: str) -> dict:
    """
    Robustly extract a JSON object from an LLM response.

    Tries in order:
      1. Direct parse (already clean JSON)
      2. Strip markdown code fences (```json ... ``` or ``` ... ```)
      3. Find first { ... } block via brace counting
      4. Regex search for JSON object pattern
    """
    text = response.strip()

    # 1. Direct parse
    try:
        return json.loads(text)
    except Exception:
        pass

    # 2. Strip markdown fences
    stripped = re.sub(r'^```(?:json)?\s*', '', text, flags=re.IGNORECASE)
    stripped = re.sub(r'\s*```$', '', stripped).strip()
    try:
        return json.loads(stripped)
    except Exception:
        pass

    # 3. Find first complete { ... } block by counting braces
    start = text.find('{')
    if start != -1:
        depth = 0
        for i, ch in enumerate(text[start:], start=start):
            if ch == '{':
                depth += 1
            elif ch == '}':
                depth -= 1
                if depth == 0:
                    try:
                        return json.loads(text[start:i + 1])
                    except Exception:
                        break

    # 4. Regex fallback — grab anything that looks like a JSON object
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        try:
            return json.loads(match.group())
        except Exception:
            pass

    raise ValueError("No valid JSON object found in LLM response")


class DocumentService:

    async def upload_and_process(self, file: UploadFile) -> UploadDocumentResponse:
        if not is_allowed_file(file.filename):
            raise ValueError(f"Unsupported file type: {file.filename}")

        doc_id = generate_document_id()
        file_ext = Path(file.filename).suffix.lower()
        save_path = os.path.join(settings.UPLOAD_DIR, f"{doc_id}{file_ext}")

        async with aiofiles.open(save_path, "wb") as out_file:
            content = await file.read()
            if len(content) > settings.MAX_FILE_SIZE_MB * 1024 * 1024:
                raise ValueError(f"File exceeds {settings.MAX_FILE_SIZE_MB}MB limit")
            await out_file.write(content)

        logger.info(f"File saved: {save_path}")

        full_text, page_count, page_texts = document_parser.parse(save_path)
        full_text = clean_text(full_text)

        chunks = chunk_text(full_text)
        if not chunks:
            raise ValueError("Could not extract any text from the document")

        embeddings = await embeddings_manager.embed_texts(chunks)

        metadata = {
            "filename": file.filename,
            "file_path": save_path,
            "page_count": page_count,
            "total_chunks": len(chunks),
        }
        vector_store.add_document_chunks(doc_id, chunks, embeddings, metadata)

        _document_registry[doc_id] = {
            "doc_id": doc_id,
            "filename": file.filename,
            "file_path": save_path,
            "page_count": page_count,
            "page_texts": page_texts,
            "full_text": full_text,
            "chunks": chunks,
        }

        logger.info(f"Document processed: {doc_id}, pages={page_count}, chunks={len(chunks)}")

        return UploadDocumentResponse(
            document_id=doc_id,
            filename=file.filename,
            number_of_pages=page_count,
            number_of_chunks=len(chunks),
            file_type=file_ext,
            status="success",
            message="Document uploaded and processed successfully",
        )

    def get_document(self, document_id: str) -> Optional[dict]:
        return _document_registry.get(document_id)

    def _require_document(self, document_id: str) -> dict:
        doc = self.get_document(document_id)
        if not doc:
            raise KeyError(f"Document not found: {document_id}")
        return doc

    async def _retrieve_summary_context(self, document_id: str) -> str:
        seen = set()
        relevant_chunks = []

        for query in SUMMARY_QUERIES:
            try:
                query_embedding = await embeddings_manager.embed_query(query)
                chunks = vector_store.query_similar_chunks(
                    query_embedding=query_embedding,
                    document_id=document_id,
                    n_results=3,
                )
                for chunk in chunks:
                    key = chunk[:80]
                    if key not in seen:
                        seen.add(key)
                        relevant_chunks.append(chunk)
            except Exception as e:
                logger.warning(f"Summary query '{query[:30]}' failed: {type(e).__name__}: {e}")
                continue

        if not relevant_chunks:
            logger.warning(f"RAG retrieval failed for {document_id}, falling back to all chunks")
            relevant_chunks = vector_store.get_all_chunks(document_id)

        if not relevant_chunks:
            logger.warning(f"ChromaDB fallback failed, using full_text for {document_id}")
            doc = self._require_document(document_id)
            return doc["full_text"][:settings.SUMMARY_TEXT_LIMIT]

        context = "\n\n---\n\n".join(relevant_chunks)
        logger.info(
            f"Summary context: {len(relevant_chunks)} chunks, "
            f"{len(context)} chars for doc {document_id}"
        )
        return context

    async def get_summary(
        self, document_id: str, mode: ExplanationMode = ExplanationMode.student
    ) -> DocumentSummaryResponse:
        doc = self._require_document(document_id)
        client = get_client("summary")

        mode_instructions = {
            ExplanationMode.beginner: (
                "Explain this document in very simple language as if explaining to someone "
                "with no legal knowledge. Use short sentences. Avoid all legal jargon."
            ),
            ExplanationMode.student: (
                "Explain this document with moderate detail. Use clear language but you "
                "can use some legal terms if you define them. Be comprehensive."
            ),
            ExplanationMode.professional: (
                "Provide a detailed legal analysis with precise legal terminology. "
                "Identify key legal obligations, rights, and risks with accuracy."
            ),
        }

        context = await self._retrieve_summary_context(document_id)

        prompt = f"""
{mode_instructions[mode]}

DOCUMENT EXCERPTS (most relevant sections):
{context}

Based on these excerpts, provide:
1. OVERALL SUMMARY: A clear summary of what this document is about
2. KEY OBLIGATIONS: What the parties must do
3. KEY RIGHTS: What rights each party has
4. IMPORTANT CLAUSES: The most important clauses found

CRITICAL: Return ONLY a raw JSON object. Do NOT wrap in markdown. Do NOT add any text before or after.
Start your response with {{ and end with }}.

Required format:
{{"summary": "...", "key_obligations": ["...", "..."], "key_rights": ["...", "..."], "important_clauses": [{{"clause_type": "...", "extracted_text": "..."}}]}}
"""

        response = await client.generate(prompt, SUMMARY_SYSTEM_PROMPT)

        try:
            data = _extract_json(response)
            logger.info(f"Summary JSON parsed successfully for {document_id}")
        except Exception as e:
            logger.warning(f"Summary JSON parse failed for {document_id}: {e}")
            logger.debug(f"Raw LLM response: {response[:500]}")
            # Fallback: use raw text as summary text only — NOT the whole JSON blob
            data = {
                "summary": re.sub(r'\{[\s\S]*\}', '', response).strip()[:800] or
                           "Summary could not be parsed. Please review the document manually.",
                "key_obligations": [],
                "key_rights": [],
                "important_clauses": [],
            }

        clauses = [
            ClauseItem(
                clause_type=c.get("clause_type", "Unknown"),
                extracted_text=c.get("extracted_text", ""),
                page_number=c.get("page_number"),
            )
            for c in data.get("important_clauses", [])
            if isinstance(c, dict)
        ]

        return DocumentSummaryResponse(
            document_id=document_id,
            mode=mode.value,
            summary=data.get("summary", ""),
            page_summaries=[],
            important_clauses=clauses,
            key_obligations=data.get("key_obligations", []),
            key_rights=data.get("key_rights", []),
        )


document_service = DocumentService()