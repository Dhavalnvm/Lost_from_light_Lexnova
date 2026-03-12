import os
import json
import aiofiles
from pathlib import Path
from typing import Optional
from fastapi import UploadFile

from config.settings import settings
from core.document_parser import document_parser
from core.embeddings import embeddings_manager
from core.vector_store import vector_store
from core.llm_client import llm_client
from utils.helpers import generate_document_id, is_allowed_file, chunk_text, clean_text
from utils.logging import app_logger as logger
from models.schemas import (
    UploadDocumentResponse,
    DocumentSummaryResponse,
    PageSummary,
    ClauseItem,
    ExplanationMode,
)


# In-memory document registry (use Redis/DB in production)
_document_registry: dict = {}


SUMMARY_SYSTEM_PROMPT = """You are a legal document expert. Your role is to analyze legal documents 
and explain them clearly. Always be accurate, thorough, and helpful. 
Never give personal legal advice — instead explain what the document says."""

CLAUSE_TYPES = [
    "Payment Terms",
    "Termination Clause",
    "Liability Clause",
    "Confidentiality Clause",
    "Non-Compete Clause",
    "Penalty Clause",
    "Renewal Clause",
    "Governing Law",
    "Dispute Resolution",
    "Indemnification Clause",
    "Force Majeure",
    "Intellectual Property",
]


class DocumentService:

    async def upload_and_process(self, file: UploadFile) -> UploadDocumentResponse:
        """Accept upload, parse, chunk, embed, and store in vector DB."""
        if not is_allowed_file(file.filename):
            raise ValueError(f"Unsupported file type: {file.filename}")

        doc_id = generate_document_id()
        file_ext = Path(file.filename).suffix.lower()
        save_path = os.path.join(settings.UPLOAD_DIR, f"{doc_id}{file_ext}")

        # Save file to disk
        async with aiofiles.open(save_path, "wb") as out_file:
            content = await file.read()
            if len(content) > settings.MAX_FILE_SIZE_MB * 1024 * 1024:
                raise ValueError(f"File exceeds {settings.MAX_FILE_SIZE_MB}MB limit")
            await out_file.write(content)

        logger.info(f"File saved: {save_path}")

        # Parse document
        full_text, page_count, page_texts = document_parser.parse(save_path)
        full_text = clean_text(full_text)

        # Chunk text
        chunks = chunk_text(full_text)
        if not chunks:
            raise ValueError("Could not extract any text from the document")

        # Generate embeddings
        embeddings = embeddings_manager.embed_texts(chunks)

        # Store in ChromaDB
        metadata = {
            "filename": file.filename,
            "file_path": save_path,
            "page_count": page_count,
            "total_chunks": len(chunks),
        }
        vector_store.add_document_chunks(doc_id, chunks, embeddings, metadata)

        # Register document
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

    async def get_summary(
        self, document_id: str, mode: ExplanationMode = ExplanationMode.student
    ) -> DocumentSummaryResponse:
        doc = self._require_document(document_id)
        full_text = doc["full_text"][:6000]  # context window safety

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

        prompt = f"""
{mode_instructions[mode]}

DOCUMENT TEXT:
{full_text}

Please provide:
1. OVERALL SUMMARY: A clear summary of what this document is about
2. KEY OBLIGATIONS: What the parties must do (bullet points)  
3. KEY RIGHTS: What rights each party has (bullet points)
4. IMPORTANT CLAUSES: List the most important clauses found

Format your response as JSON with keys:
"summary", "key_obligations" (list), "key_rights" (list), "important_clauses" (list of {{"clause_type": ..., "extracted_text": ...}})
"""

        response = await llm_client.generate(prompt, SUMMARY_SYSTEM_PROMPT)

        # Parse JSON response
        try:
            cleaned = response.strip().strip("```json").strip("```").strip()
            data = json.loads(cleaned)
        except Exception:
            # Fallback: construct a basic response from raw text
            data = {
                "summary": response[:500],
                "key_obligations": [],
                "key_rights": [],
                "important_clauses": [],
            }

        # Generate page-level summaries
        page_summaries = []
        for i, page_text in enumerate(doc["page_texts"][:10]):  # cap at 10 pages
            if not page_text.strip():
                continue
            page_prompt = f"Summarize this page of a legal document in 2-3 sentences:\n\n{page_text[:1500]}"
            page_summary = await llm_client.generate(page_prompt, SUMMARY_SYSTEM_PROMPT)
            page_summaries.append(PageSummary(page_number=i + 1, summary=page_summary))

        clauses = [
            ClauseItem(
                clause_type=c.get("clause_type", "Unknown"),
                extracted_text=c.get("extracted_text", ""),
                page_number=c.get("page_number"),
            )
            for c in data.get("important_clauses", [])
        ]

        return DocumentSummaryResponse(
            document_id=document_id,
            mode=mode.value,
            summary=data.get("summary", ""),
            page_summaries=page_summaries,
            important_clauses=clauses,
            key_obligations=data.get("key_obligations", []),
            key_rights=data.get("key_rights", []),
        )


document_service = DocumentService()
