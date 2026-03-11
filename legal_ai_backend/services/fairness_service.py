import json
from core.task_router import get_client
from utils.logging import app_logger as logger
from models.schemas import ClauseFairnessResponse, ClauseFairnessItem
from config.settings import settings


FAIRNESS_SYSTEM_PROMPT = """You are a legal contract fairness expert.
Only analyze clauses that are explicitly present in the document.
Never invent or assume clauses that are not there.
Respond with valid JSON only. No markdown. No explanation."""


BENCHMARKS_BY_TYPE = {
    "employment": {
        "notice_period":             {"typical": "30–90 days", "keywords": ["notice period", "written notice", "days notice", "advance notice"]},
        "non_compete_duration":      {"typical": "6–12 months, limited geographic scope", "keywords": ["non-compete", "not compete", "competing business", "restrictive covenant"]},
        "intellectual_property":     {"typical": "Work-for-hire IP to employer; personal IP retained by employee", "keywords": ["intellectual property", "work product", "work for hire", "ip ownership"]},
        "termination_without_cause": {"typical": "Either party with 30–60 days notice", "keywords": ["terminate for convenience", "termination without cause", "at will"]},
        "probation_period":          {"typical": "3–6 months", "keywords": ["probation", "probationary period", "trial period"]},
    },
    "rental": {
        "security_deposit":          {"typical": "1–3 months rent", "keywords": ["security deposit", "refundable deposit", "caution deposit", "advance deposit"]},
        "notice_period":             {"typical": "30–60 days for termination", "keywords": ["notice period", "written notice", "vacate", "days notice"]},
        "late_payment_penalty":      {"typical": "1–2% per month on overdue rent", "keywords": ["late payment", "overdue", "penalty for delay", "interest on overdue"]},
        "rent_escalation":           {"typical": "5–10% annual increase or CPI-linked", "keywords": ["rent increase", "escalation", "revision of rent", "hike", "enhanced rent"]},
        "maintenance_responsibility": {"typical": "Minor repairs by tenant; major structural by landlord", "keywords": ["maintenance", "repairs", "upkeep", "fixture"]},
    },
    "loan": {
        "interest_rate":             {"typical": "Market rate; fixed or floating clearly disclosed", "keywords": ["interest rate", "rate of interest", "annual percentage"]},
        "prepayment_penalty":        {"typical": "0–2% of outstanding principal", "keywords": ["prepayment", "foreclosure charge", "early repayment", "prepay"]},
        "late_payment_penalty":      {"typical": "2–3% of overdue amount per month", "keywords": ["late payment", "overdue", "penal interest", "default interest"]},
        "collateral":                {"typical": "Proportionate to loan amount", "keywords": ["collateral", "security", "pledge", "hypothecation", "mortgage"]},
        "cross_default":             {"typical": "Limited to same lender's facilities", "keywords": ["cross default", "cross-default", "event of default"]},
    },
    "business": {
        "limitation_of_liability":   {"typical": "Capped at contract value or 12 months fees", "keywords": ["limitation of liability", "liability cap", "maximum liability", "aggregate liability"]},
        "indemnification":           {"typical": "Mutual indemnification for own negligence/breach", "keywords": ["indemnif", "hold harmless", "defend and indemnify"]},
        "termination_for_convenience": {"typical": "Either party with 30–60 days notice", "keywords": ["terminate for convenience", "termination without cause"]},
        "arbitration":               {"typical": "Mutual binding arbitration, shared costs, neutral venue", "keywords": ["arbitration", "dispute resolution", "binding arbitration"]},
        "contract_renewal":          {"typical": "Optional with 30-day written notice", "keywords": ["auto renew", "automatic renewal", "evergreen", "renewal"]},
        "payment_terms":             {"typical": "Net 30–60 days", "keywords": ["payment terms", "net 30", "net 60", "invoice", "due date"]},
    },
    "software": {
        "limitation_of_liability":   {"typical": "Capped at 12 months subscription fees", "keywords": ["limitation of liability", "liability cap", "maximum liability"]},
        "data_privacy":              {"typical": "GDPR/applicable law compliant; user data not sold", "keywords": ["data", "privacy", "personal information", "gdpr", "user data"]},
        "service_availability":      {"typical": "99.5%+ uptime SLA with remedies", "keywords": ["uptime", "sla", "availability", "service level"]},
        "termination":               {"typical": "30-day notice; data export right on termination", "keywords": ["termination", "cancellation", "end of subscription"]},
        "ip_ownership":              {"typical": "Vendor retains platform IP; customer retains their data", "keywords": ["intellectual property", "ip ownership", "work product", "license"]},
    },
    "general": {
        "limitation_of_liability":   {"typical": "Capped at contract value", "keywords": ["limitation of liability", "liability cap", "maximum liability"]},
        "indemnification":           {"typical": "Mutual indemnification for own acts", "keywords": ["indemnif", "hold harmless"]},
        "dispute_resolution":        {"typical": "Negotiation → Mediation → Arbitration/Litigation", "keywords": ["dispute", "arbitration", "mediation", "jurisdiction"]},
        "termination":               {"typical": "Mutual right with reasonable notice", "keywords": ["termination", "cancellation", "end of agreement"]},
        "governing_law":             {"typical": "Jurisdiction agreed by both parties", "keywords": ["governing law", "jurisdiction", "applicable law"]},
    },
}


def _clean_json_response(response: str) -> str:
    cleaned = response.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    return cleaned.strip()


def _detect_doc_type(text: str) -> str:
    text_lower = text.lower()
    if any(w in text_lower for w in ["employee", "employer", "salary", "wages", "employment"]):
        return "employment"
    if any(w in text_lower for w in ["tenant", "landlord", "rent", "lease", "premises", "rental"]):
        return "rental"
    if any(w in text_lower for w in ["borrower", "lender", "loan", "repayment", "mortgage", "emi"]):
        return "loan"
    if any(w in text_lower for w in ["software", "saas", "subscription", "end user", "platform", "api"]):
        return "software"
    if any(w in text_lower for w in ["vendor", "service", "deliverable", "milestone", "statement of work"]):
        return "business"
    if any(w in text_lower for w in ["partnership", "shareholder", "equity", "joint venture", "director"]):
        return "business"
    return "general"


def _detect_international(text: str) -> bool:
    text_lower = text.lower()
    intl_signals = [
        "icc", "lcia", "siac", "uncitral", "international arbitration",
        "international", "cross-border", "usd", "eur", "gbp",
        "laws of england", "laws of singapore", "laws of new york",
        "laws of india", "laws of uae", "laws of germany",
        "foreign currency", "incoterms", "export", "import",
    ]
    hits = sum(1 for s in intl_signals if s in text_lower)
    return hits >= 2


def _get_benchmarks_for_type(doc_type: str) -> dict:
    return BENCHMARKS_BY_TYPE.get(doc_type, BENCHMARKS_BY_TYPE["general"])


# Clauses whose ABSENCE actually benefits the signing party
ABSENCE_FAVORABLE = {
    "rent_escalation":           "No rent escalation clause found — this is favorable for the tenant as the landlord cannot automatically increase rent.",
    "prepayment_penalty":        "No prepayment penalty found — favorable for the borrower; you can repay early without extra cost.",
    "non_compete_duration":      "No non-compete clause found — favorable; you are free to work anywhere after this contract ends.",
    "limitation_of_liability":   "No liability cap found — note this cuts both ways; neither party has capped exposure.",
    "cross_default":             "No cross-default clause found — favorable; a default on one agreement won't trigger this one.",
}


class FairnessService:

    async def analyze_fairness(
        self, document_id: str, full_text: str
    ) -> ClauseFairnessResponse:
        text_sample = full_text[:settings.ANALYSIS_TEXT_LIMIT]
        client = get_client("fairness")

        doc_type = _detect_doc_type(full_text)
        is_international = _detect_international(full_text)
        benchmarks = _get_benchmarks_for_type(doc_type)

        benchmarks_str = json.dumps(
            {k: {"typical": v["typical"]} for k, v in benchmarks.items()},
            indent=2,
        )

        intl_note = ""
        if is_international:
            intl_note = """
NOTE — INTERNATIONAL CONTRACT: Foreign governing law, international arbitration clauses
(ICC, LCIA, SIAC, UNCITRAL), and foreign currency terms are STANDARD — rate them "Fair".
"""

        prompt = f"""You are reviewing a {doc_type} contract.
{intl_note}

CRITICAL RULES:
1. ONLY analyze clause types that have explicit text in the document.
2. If a clause type is NOT mentioned in the document, skip it entirely. Do not invent it.
3. "No X mentioned" is NOT a clause — do not include it in your analysis.
4. Rate only what you can read in the actual document text.

DOCUMENT:
{text_sample}

INDUSTRY BENCHMARKS FOR {doc_type.upper()} CONTRACTS:
{benchmarks_str}

For each clause type ACTUALLY PRESENT in the document:
1. Extract the actual value/term from the document text
2. Compare to the benchmark
3. Rate fairness: "Fair", "Slightly Unfair", "Unfair", or "Very Unfair"
4. Write a 1-2 sentence insight explaining the comparison with specific numbers/terms

Overall fairness rating: "Fair", "Mostly Fair", "Mixed", "Mostly Unfair", or "Unfair"

Return ONLY raw JSON. No markdown. Start with {{ end with }}.

{{"overall_fairness": "...", "clauses_analyzed": [{{"clause_type": "human readable name", "contract_value": "exact text/value from the document", "typical_standard": "benchmark value", "fairness_rating": "Fair|Slightly Unfair|Unfair|Very Unfair", "ai_insight": "explanation with specifics", "severity": "low|medium|high"}}]}}"""

        response = await client.generate(prompt, FAIRNESS_SYSTEM_PROMPT, temperature=0.0)

        try:
            data = json.loads(_clean_json_response(response))
        except Exception:
            logger.warning("Fairness JSON parse failed, using keyword fallback")
            data = self._keyword_fallback(full_text, doc_type)

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
            # Filter out any hallucinated "not mentioned" entries that slipped through
            if "not mention" not in c.get("contract_value", "").lower()
            and "not specify" not in c.get("contract_value", "").lower()
            and "no specific" not in c.get("contract_value", "").lower()
        ]

        return ClauseFairnessResponse(
            document_id=document_id,
            overall_fairness=data.get("overall_fairness", "Unclear"),
            clauses_analyzed=clauses,
        )

    def _keyword_fallback(self, text: str, doc_type: str = "general") -> dict:
        text_lower = text.lower()
        benchmarks = _get_benchmarks_for_type(doc_type)
        clauses = []
        for key, bench in benchmarks.items():
            for kw in bench.get("keywords", []):
                if kw in text_lower:
                    idx = text_lower.find(kw)
                    snippet = text[max(0, idx): idx + 200].strip()
                    clauses.append({
                        "clause_type": key.replace("_", " ").title(),
                        "contract_value": snippet[:120],
                        "typical_standard": bench["typical"],
                        "fairness_rating": "Unclear",
                        "ai_insight": f"Clause detected. Compare with typical standard: {bench['typical']}",
                        "severity": "medium",
                    })
                    break
        return {"overall_fairness": "Requires Manual Review", "clauses_analyzed": clauses}


fairness_service = FairnessService()