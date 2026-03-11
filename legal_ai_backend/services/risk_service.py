import json
import asyncio
from core.task_router import get_client
from core.embeddings import embeddings_manager
from core.vector_store import vector_store
from utils.helpers import estimate_risk_score
from utils.logging import app_logger as logger
from models.schemas import RiskAnalysisResponse, RedFlag
from config.settings import settings


RISK_SYSTEM_PROMPT = """You are a legal risk analyst specializing in contract review.
Identify risky clauses, unfair terms, and legal red flags in contracts.
Be thorough and precise. Always respond with valid JSON only."""

RISK_QUERIES = [
    "penalty clause liquidated damages fine",
    "automatic renewal termination without notice",
    "non-compete restriction liability waiver",
    "indemnification hold harmless unlimited liability",
    "arbitration dispute resolution governing law jurisdiction",
    "unilateral modification sole discretion hidden fees",
]

RED_FLAG_PATTERNS = [
    "automatic renewal", "sole discretion", "non-refundable",
    "waive all rights", "unlimited liability", "indemnify and hold harmless",
    "liquidated damages", "penalty", "non-compete", "perpetual license",
    "unilateral modification", "binding arbitration", "class action waiver",
    "jurisdiction outside", "without notice", "in perpetuity",
]


def _clean_json_response(response: str) -> str:
    cleaned = response.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    return cleaned.strip()


class RiskService:

    async def _retrieve_risk_context(self, document_id: str, full_text: str) -> str:
        """RAG retrieval focused on risk-related chunks."""
        seen = set()
        relevant_chunks = []

        for query in RISK_QUERIES:
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
                logger.warning(f"Risk query '{query[:30]}' failed: {type(e).__name__}: {e}")
                continue

        if not relevant_chunks:
            # Fallback — all chunks from ChromaDB
            logger.warning(f"Risk RAG failed for {document_id}, using all chunks")
            relevant_chunks = vector_store.get_all_chunks(document_id)

        if not relevant_chunks:
            # Last resort — full text slice
            logger.warning(f"ChromaDB fallback failed for risk {document_id}, using full_text")
            return full_text[:settings.ANALYSIS_TEXT_LIMIT]

        context = "\n\n---\n\n".join(relevant_chunks)
        logger.info(
            f"Risk context: {len(relevant_chunks)} chunks, "
            f"{len(context)} chars for doc {document_id}"
        )
        return context

    async def analyze_risk(self, document_id: str, full_text: str) -> RiskAnalysisResponse:
        # ✅ RAG retrieval — faster and more focused than full text
        context = await self._retrieve_risk_context(document_id, full_text)
        client = get_client("risk")

        prompt = f"""Analyze this legal document for risks and red flags.

DOCUMENT:
{context}

Find risks including: penalty clauses, automatic renewal, one-sided termination, non-compete, hidden fees, unlimited liability, rights waiver, unfair arbitration, unusual jurisdiction.

For each risk found provide a JSON object with:
- flag_type: short risk name
- description: why it is risky (1-2 sentences)
- extracted_text: the clause text (max 80 words)
- severity: "low", "medium", or "high"
- page_reference: integer page number or null

IMPORTANT: Return ONLY raw JSON. No markdown. No explanation. Start with {{ end with }}.

{{"detected_red_flags": [{{"flag_type": "...", "description": "...", "extracted_text": "...", "severity": "high|medium|low", "page_reference": null}}], "risk_summary": "2-3 sentence overall assessment"}}"""

        response = await client.generate(prompt, RISK_SYSTEM_PROMPT)

        try:
            data = json.loads(_clean_json_response(response))
        except Exception:
            logger.warning("Risk JSON parse failed, using keyword scan fallback")
            data = {
                "detected_red_flags": self._keyword_scan(full_text),
                "risk_summary": "Automated keyword scan completed. Review highlighted clauses carefully.",
            }

        red_flags = [
            RedFlag(
                flag_type=f.get("flag_type", "Unknown"),
                description=f.get("description", ""),
                extracted_text=f.get("extracted_text", ""),
                severity=f.get("severity", "medium"),
                page_reference=f.get("page_reference"),
            )
            for f in data.get("detected_red_flags", [])
        ]

        score_data = estimate_risk_score([{"severity": f.severity} for f in red_flags])

        return RiskAnalysisResponse(
            document_id=document_id,
            risk_score=score_data["risk_score"],
            risk_level=score_data["risk_level"],
            detected_red_flags=red_flags,
            risk_summary=data.get("risk_summary", ""),
        )

    def _keyword_scan(self, text: str) -> list:
        text_lower = text.lower()
        found = []
        for pattern in RED_FLAG_PATTERNS:
            if pattern in text_lower:
                idx = text_lower.find(pattern)
                snippet = text[max(0, idx - 50): idx + 150].strip()
                found.append({
                    "flag_type": pattern.replace(" ", "_").title(),
                    "description": f"Document contains '{pattern}' language which may be risky.",
                    "extracted_text": snippet,
                    "severity": "medium",
                    "page_reference": None,
                })
        return found


risk_service = RiskService()