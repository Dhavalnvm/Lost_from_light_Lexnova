import json
from core.task_router import get_client
from utils.helpers import estimate_risk_score
from utils.logging import app_logger as logger
from models.schemas import RiskAnalysisResponse, RedFlag
from config.settings import settings


RISK_SYSTEM_PROMPT = """You are a legal risk analyst specializing in contract review. 
Your task is to identify risky clauses, unfair terms, and legal red flags in contracts. 
Be thorough and precise."""


RED_FLAG_PATTERNS = [
    "automatic renewal",
    "sole discretion",
    "non-refundable",
    "waive all rights",
    "unlimited liability",
    "indemnify and hold harmless",
    "liquidated damages",
    "penalty",
    "non-compete",
    "perpetual license",
    "unilateral modification",
    "binding arbitration",
    "class action waiver",
    "jurisdiction outside",
    "without notice",
    "in perpetuity",
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

    async def analyze_risk(self, document_id: str, full_text: str) -> RiskAnalysisResponse:
        # Use increased text limit + smart (8b) model
        text_sample = full_text[:settings.ANALYSIS_TEXT_LIMIT]
        client = get_client("risk")

        prompt = f"""
Analyze the following legal document for risks and red flags.

DOCUMENT:
{text_sample}

Identify ALL of the following types of risks if present:
1. High penalty clauses
2. Automatic renewal with no opt-out
3. One-sided termination rights
4. Overly broad non-compete restrictions
5. Hidden fees or charges
6. Liability transfer to weaker party
7. Unlimited indemnification
8. Waiver of important rights
9. Unfair dispute resolution
10. Unusual governing law provisions

For each risk found, provide:
- flag_type: short name of the risk
- description: what makes it risky
- extracted_text: the exact clause text (max 150 words)
- severity: "low", "medium", or "high"
- page_reference: page number if identifiable (or null)

Also provide a risk_summary: a 2-3 sentence overall risk assessment.

Respond ONLY with valid JSON in this format:
{{
  "detected_red_flags": [
    {{
      "flag_type": "...",
      "description": "...",
      "extracted_text": "...",
      "severity": "high|medium|low",
      "page_reference": null
    }}
  ],
  "risk_summary": "..."
}}
"""

        response = await client.generate(prompt, RISK_SYSTEM_PROMPT)

        try:
            data = json.loads(_clean_json_response(response))
        except Exception:
            logger.warning("Risk analysis JSON parse failed, using fallback keyword scan")
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
        """Fallback: keyword-based red flag scan."""
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