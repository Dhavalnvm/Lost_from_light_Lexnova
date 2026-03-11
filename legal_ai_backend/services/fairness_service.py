import json
from core.task_router import get_client
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


def _clean_json_response(response: str) -> str:
    cleaned = response.strip()
    if cleaned.startswith("```json"):
        cleaned = cleaned[7:]
    elif cleaned.startswith("```"):
        cleaned = cleaned[3:]
    if cleaned.endswith("```"):
        cleaned = cleaned[:-3]
    return cleaned.strip()


class FairnessService:

    async def analyze_fairness(
        self, document_id: str, full_text: str
    ) -> ClauseFairnessResponse:
        # Use increased text limit + smart (8b) model
        text_sample = full_text[:settings.ANALYSIS_TEXT_LIMIT]
        client = get_client("fairness")

        benchmarks_str = json.dumps(
            {k: {"typical": v["typical"], "description": v["description"]}
             for k, v in CLAUSE_BENCHMARKS.items()},
            indent=2,
        )

        prompt = f"""
Analyze this legal document and compare its clauses against standard industry benchmarks.

DOCUMENT:
{text_sample}

INDUSTRY BENCHMARKS:
{benchmarks_str}

For each relevant clause type you find in the document:
1. Extract the actual contract value/term
2. Compare it to the typical benchmark
3. Rate fairness: "Fair", "Unfair", "Slightly Unfair", or "Very Unfair"
4. Provide a brief AI insight explaining the comparison

Also give an overall_fairness rating: "Fair", "Mostly Fair", "Mixed", "Mostly Unfair", or "Unfair"

Respond ONLY with valid JSON:
{{
  "overall_fairness": "...",
  "clauses_analyzed": [
    {{
      "clause_type": "...",
      "contract_value": "exact value/term from document",
      "typical_standard": "industry benchmark",
      "fairness_rating": "Fair|Unfair|Slightly Unfair|Very Unfair",
      "ai_insight": "explanation",
      "severity": "low|medium|high"
    }}
  ]
}}
"""

        response = await client.generate(prompt, FAIRNESS_SYSTEM_PROMPT)

        try:
            data = json.loads(_clean_json_response(response))
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