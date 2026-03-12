import json
from core.task_router import get_client
from core.embeddings import embeddings_manager
from core.vector_store import vector_store
from utils.helpers import clean_json_response
from utils.logging import app_logger as logger
from models.schemas import ClauseFairnessResponse, ClauseFairnessItem
from config.settings import settings


FAIRNESS_SYSTEM_PROMPT = """You are a legal contract fairness expert.
Compare contract clauses against industry standard benchmarks and explain if they are fair,
unfair, or unusual. Be objective and cite typical industry standards."""


CLAUSE_BENCHMARKS = {
    "late_payment_penalty": {
        "typical": "1–2% per month",
        "description": "Late payment penalty / interest rate",
        "keywords": ["late payment", "interest on overdue", "penalty for delay", "overdue interest"],
    },
    "security_deposit": {
        "typical": "1–2 months rent",
        "description": "Security / refundable deposit amount",
        "keywords": ["security deposit", "refundable deposit", "caution deposit", "advance deposit"],
    },
    "non_compete_duration": {
        "typical": "6–12 months post-employment",
        "description": "Non-compete restriction period",
        "keywords": ["non-compete", "non compete", "not compete", "competing business", "restrictive covenant"],
    },
    "notice_period": {
        "typical": "30–90 days",
        "description": "Contract termination notice period",
        "keywords": ["notice period", "written notice", "days notice", "advance notice"],
    },
    "contract_renewal": {
        "typical": "Optional with 30-day written notice",
        "description": "Contract renewal terms",
        "keywords": ["auto renew", "automatic renewal", "evergreen clause", "renewal clause"],
    },
    "limitation_of_liability": {
        "typical": "Capped at contract value or 12 months fees",
        "description": "Liability limitation amount",
        "keywords": ["limitation of liability", "liability cap", "maximum liability", "aggregate liability"],
    },
    "termination_for_convenience": {
        "typical": "Either party with 30–60 days notice",
        "description": "Right to terminate without cause",
        "keywords": ["terminate for convenience", "termination without cause", "at will termination"],
    },
    "intellectual_property": {
        "typical": "Work-for-hire IP assigned to employer; personal IP retained by employee",
        "description": "Intellectual property ownership",
        "keywords": ["intellectual property", "work product", "work for hire", "ip ownership", "copyright assignment"],
    },
    "arbitration": {
        "typical": "Mutual binding arbitration with shared costs",
        "description": "Dispute resolution via arbitration",
        "keywords": ["arbitration", "dispute resolution", "binding arbitration", "arbitral proceedings"],
    },
    "indemnification": {
        "typical": "Mutual indemnification for own negligence/breach",
        "description": "Indemnification obligations",
        "keywords": ["indemnif", "hold harmless", "defend and indemnify"],
    },
}

# RAG queries targeting clause-relevant sections
FAIRNESS_QUERIES = [
    "penalty late payment interest charges fees",
    "security deposit refundable advance",
    "non-compete restriction post-employment",
    "termination notice period without cause",
    "automatic renewal evergreen clause",
    "limitation of liability liability cap",
    "indemnification hold harmless",
    "arbitration dispute resolution",
    "intellectual property ownership work for hire",
]


class FairnessService:

    async def _retrieve_fairness_context(self, document_id: str, full_text: str) -> str:
        """RAG retrieval focused on clause-fairness-relevant sections."""
        seen = set()
        relevant_chunks = []

        for query in FAIRNESS_QUERIES:
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
                logger.warning(f"Fairness query '{query[:30]}' failed: {type(e).__name__}: {e}")
                continue

        if not relevant_chunks:
            logger.warning(f"Fairness RAG failed for {document_id}, using all chunks")
            relevant_chunks = vector_store.get_all_chunks(document_id)

        if not relevant_chunks:
            logger.warning(f"ChromaDB fallback failed for fairness {document_id}, using full_text")
            return full_text[:settings.ANALYSIS_TEXT_LIMIT]

        context = "\n\n---\n\n".join(relevant_chunks)
        logger.info(
            f"Fairness context: {len(relevant_chunks)} chunks, "
            f"{len(context)} chars for doc {document_id}"
        )
        return context

    async def analyze_fairness(
        self, document_id: str, full_text: str
    ) -> ClauseFairnessResponse:
        # Fix #5 — was raw full_text slice; now uses RAG for relevant clause chunks
        context = await self._retrieve_fairness_context(document_id, full_text)
        client = get_client("fairness")

        benchmarks_str = json.dumps(
            {k: {"typical": v["typical"], "description": v["description"]}
             for k, v in CLAUSE_BENCHMARKS.items()},
            indent=2,
        )

        prompt = f"""
Analyze this legal document and compare its clauses against standard industry benchmarks.

DOCUMENT:
{context}

INDUSTRY BENCHMARKS:
{benchmarks_str}

For each relevant clause type you find in the document:
1. Extract the actual contract value/term
2. Compare it to the typical benchmark
3. Rate fairness: "Fair", "Unfair", "Slightly Unfair", or "Very Unfair"
4. Provide a brief AI insight explaining the comparison

Also give an overall_fairness rating: "Fair", "Mostly Fair", "Mixed", "Mostly Unfair", or "Unfair"

IMPORTANT: Return ONLY raw JSON. No markdown, no explanation, no code fences. Start with {{ and end with }}.

Format:
{{"overall_fairness": "...", "clauses_analyzed": [{{"clause_type": "...", "contract_value": "...", "typical_standard": "...", "fairness_rating": "Fair|Unfair|Slightly Unfair|Very Unfair", "ai_insight": "...", "severity": "low|medium|high"}}]}}
"""

        response = await client.generate(prompt, FAIRNESS_SYSTEM_PROMPT)

        try:
            data = json.loads(clean_json_response(response))
        except Exception:
            logger.warning("Fairness JSON parse failed, using keyword fallback")
            data = self._keyword_fallback(full_text)

        clauses = [
            ClauseFairnessItem(
                clause_type=c.get("clause_type", "Unknown"),
                contract_value=c.get("contract_value", "Not specified"),
                typical_standard=c.get("typical_standard", "Varies"),
                fairness_rating=c.get("fairness_rating", "Unclear"),
                ai_insight=c.get("ai_insight", ""),
                severity=c.get("severity", "medium"),
            )
            for c in data.get("clauses_analyzed", [])
        ]

        return ClauseFairnessResponse(
            document_id=document_id,
            overall_fairness=data.get("overall_fairness", "Unclear"),
            clauses_analyzed=clauses,
        )

    def _keyword_fallback(self, text: str) -> dict:
        text_lower = text.lower()
        clauses = []
        for key, bench in CLAUSE_BENCHMARKS.items():
            for kw in bench["keywords"]:
                if kw in text_lower:
                    idx = text_lower.find(kw)
                    snippet = text[max(0, idx): idx + 200].strip()
                    clauses.append({
                        "clause_type": bench["description"],
                        "contract_value": snippet[:100],
                        "typical_standard": bench["typical"],
                        "fairness_rating": "Unclear",
                        "ai_insight": f"Clause detected. Compare with typical standard: {bench['typical']}",
                        "severity": "medium",
                    })
                    break
        return {"overall_fairness": "Requires Review", "clauses_analyzed": clauses}


fairness_service = FairnessService()