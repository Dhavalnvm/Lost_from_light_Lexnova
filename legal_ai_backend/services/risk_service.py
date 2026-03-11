import json
import re
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

# ✅ FIX: removed "binding arbitration" and "jurisdiction outside" —
# these are standard in international contracts and caused false HIGH flags
RED_FLAG_PATTERNS = [
    "automatic renewal", "sole discretion", "non-refundable",
    "waive all rights", "unlimited liability", "indemnify and hold harmless",
    "liquidated damages", "penalty", "non-compete", "perpetual license",
    "unilateral modification", "class action waiver",
    "without notice", "in perpetuity",
]


def _extract_json(response: str) -> dict:
    """
    Robustly extract a JSON object from an LLM response.
    Tries direct parse → strip fences → brace counting → regex.
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

    # 3. Brace counting — find first complete { } block
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

    # 4. Regex fallback
    match = re.search(r'\{[\s\S]*\}', text)
    if match:
        try:
            return json.loads(match.group())
        except Exception:
            pass

    raise ValueError("No valid JSON object found in LLM response")


def _detect_international_context(text: str) -> bool:
    """Returns True if doc appears to be international/cross-border."""
    signals = [
        "icc", "lcia", "siac", "uncitral", "international arbitration",
        "cross-border", "foreign jurisdiction", "english law", "singapore law",
        "new york law", "governing law", "laws of", "courts of",
    ]
    text_lower = text.lower()
    return sum(1 for s in signals if s in text_lower) >= 2


def _detect_doc_type(text: str) -> str:
    """Detect document type to apply appropriate risk benchmarks."""
    text_lower = text.lower()
    if any(w in text_lower for w in ["employment", "employee", "employer", "salary", "notice period"]):
        return "employment"
    if any(w in text_lower for w in ["rent", "lease", "landlord", "tenant", "premises"]):
        return "rental"
    if any(w in text_lower for w in ["loan", "borrower", "lender", "repayment", "interest rate"]):
        return "loan"
    if any(w in text_lower for w in ["software", "saas", "license", "subscription", "api"]):
        return "software"
    if any(w in text_lower for w in ["partnership", "shareholder", "vendor", "service agreement"]):
        return "business"
    return "general"


class RiskService:

    async def _retrieve_risk_context(self, document_id: str, full_text: str) -> str:
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
            logger.warning(f"Risk RAG failed for {document_id}, using all chunks")
            relevant_chunks = vector_store.get_all_chunks(document_id)

        if not relevant_chunks:
            logger.warning(f"ChromaDB fallback failed for risk {document_id}, using full_text")
            return full_text[:settings.ANALYSIS_TEXT_LIMIT]

        context = "\n\n---\n\n".join(relevant_chunks)
        logger.info(
            f"Risk context: {len(relevant_chunks)} chunks, "
            f"{len(context)} chars for doc {document_id}"
        )
        return context

    async def analyze_risk(self, document_id: str, full_text: str) -> RiskAnalysisResponse:
        context = await self._retrieve_risk_context(document_id, full_text)
        client = get_client("risk")

        is_international = _detect_international_context(full_text)
        doc_type = _detect_doc_type(full_text)

        international_note = ""
        if is_international:
            international_note = """
IMPORTANT — INTERNATIONAL CONTRACT DETECTED:
- Do NOT flag foreign jurisdiction, foreign governing law, or international arbitration as risks.
- ICC, LCIA, SIAC, UNCITRAL arbitration clauses are STANDARD in international contracts — do NOT flag them.
- Only flag jurisdiction/arbitration if it is unusually one-sided or clearly abusive.
"""

        prompt = f"""Analyze this {doc_type} contract for genuine legal risks and red flags.

DOCUMENT:
{context}

{international_note}

CRITICAL RULES:
1. Only flag clauses EXPLICITLY WRITTEN in the document. NEVER flag the absence of a protective clause as a risk.
2. Do NOT invent risks. If a clause is standard for a {doc_type} contract, do NOT flag it.
3. severity must reflect actual harm: "high" = serious financial/legal harm, "medium" = unfair but manageable, "low" = minor concern.
4. A document with fair standard clauses should have 0-2 flags, NOT 5-10.

WHAT TO FLAG:
- Unlimited or uncapped liability on the signing party
- Automatic renewal with no opt-out or very short notice window
- Unilateral right to modify terms without consent
- Non-compete clauses that are unreasonably broad (geography/duration)
- Waiver of all legal rights or class action rights
- Hidden fees or charges not clearly disclosed
- Penalty clauses disproportionate to actual damages

WHAT NOT TO FLAG:
- Standard arbitration clauses (even binding arbitration)
- Standard jurisdiction/governing law clauses
- Normal termination provisions with reasonable notice
- Standard indemnification that is mutual or limited
- Any clause that is merely absent from the document

Return ONLY raw JSON. No markdown. Start with {{ end with }}.

{{"detected_red_flags": [{{"flag_type": "...", "description": "...", "extracted_text": "...", "severity": "high|medium|low", "page_reference": null}}], "risk_summary": "2-3 sentence overall assessment"}}"""

        response = await client.generate(prompt, RISK_SYSTEM_PROMPT)

        try:
            data = _extract_json(response)
            logger.info(f"Risk JSON parsed successfully for {document_id}")
        except Exception as e:
            logger.warning(f"Risk JSON parse failed for {document_id}: {e}")
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
            if isinstance(f, dict)
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
        """Fallback keyword scan — only used when LLM JSON parse fails."""
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