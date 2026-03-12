"""
services/checklist_service.py
------------------------------
Feature C: Smart Document Checklist
Based on document type (rental, employment, loan, etc.), generates a
dynamic checklist of expected clauses with status: present / missing / warning.
Uses 3b model (fast task).
"""
import json
from core.task_router import get_client
from utils.helpers import clean_json_response
from utils.logging import app_logger as logger

CHECKLIST_SYSTEM = """You are a legal document expert. Your job is to review a contract
and produce a clear, actionable checklist of what's present, missing, or concerning.
Make it simple enough for someone who has never read a contract before."""

# Standard clauses expected per document type
EXPECTED_CLAUSES = {
    "rental":        ["Rent amount & due date", "Security deposit terms", "Notice period for termination",
                      "Maintenance responsibilities", "Allowed use of property", "Renewal terms",
                      "Penalty for late payment", "Dispute resolution", "Entry rights of landlord"],
    "employment":    ["Start date & designation", "Salary & payment schedule", "Notice period",
                      "Leave policy", "Non-disclosure agreement", "Non-compete clause",
                      "Termination conditions", "Benefits & perks", "Probation period", "Dispute resolution"],
    "loan":          ["Loan amount", "Interest rate (APR)", "Repayment schedule",
                      "Prepayment penalty", "Late payment fee", "Collateral / security",
                      "Default consequences", "Governing law", "Processing fees"],
    "business":      ["Scope of services", "Payment terms", "Delivery timeline",
                      "Intellectual property rights", "Confidentiality clause", "Termination rights",
                      "Liability limitation", "Dispute resolution", "Governing law"],
    "insurance":     ["Coverage amount & type", "Premium schedule", "Exclusions list",
                      "Claim process", "Cancellation policy", "Renewal terms", "Grace period"],
    "nda":           ["Definition of confidential info", "Duration of confidentiality",
                      "Permitted disclosures", "Return/destruction of info",
                      "Remedies for breach", "Governing law"],
    "general":       ["Parties identification", "Effective date", "Scope / purpose",
                      "Payment terms", "Termination clause", "Dispute resolution",
                      "Governing law", "Signatures"],
}


def _detect_doc_type(text: str, provided_type: str = "") -> str:
    text_lower = text.lower()
    if provided_type:
        return provided_type
    if any(w in text_lower for w in ["rent", "tenant", "landlord", "lease", "premises"]):
        return "rental"
    if any(w in text_lower for w in ["employee", "employer", "employment", "salary", "designation"]):
        return "employment"
    if any(w in text_lower for w in ["loan", "borrower", "lender", "repayment", "interest rate"]):
        return "loan"
    if any(w in text_lower for w in ["insurance", "insurer", "policy", "premium", "claim"]):
        return "insurance"
    if any(w in text_lower for w in ["confidential", "non-disclosure", "proprietary"]):
        return "nda"
    if any(w in text_lower for w in ["services", "vendor", "supplier", "deliverable"]):
        return "business"
    return "general"


class ChecklistService:

    async def generate_checklist(
        self,
        document_id: str,
        full_text: str,
        doc_type: str = "",
    ) -> dict:
        client = get_client("checklist")
        detected_type = _detect_doc_type(full_text, doc_type)
        expected = EXPECTED_CLAUSES.get(detected_type, EXPECTED_CLAUSES["general"])
        expected_str = "\n".join(f"- {c}" for c in expected)

        prompt = f"""
Review this legal document and check which standard clauses are present, missing, or concerning.

DOCUMENT TYPE: {detected_type}

DOCUMENT:
{full_text[:4500]}

Check for these standard clauses:
{expected_str}

For EACH item above, determine:
- item: the clause name
- status: "present" | "missing" | "warning"
  - "present" = clearly found and seems fair
  - "warning" = found but has a problem (unfair terms, vague language, etc.)
  - "missing" = not found in the document
- explanation: what was found OR what's missing (max 30 words, plain English)
- action: what the person should do (max 25 words) — only needed for "missing" and "warning"

Also:
- checklist_score: 0-100 (percentage of expected clauses present and fair)
- summary: 2-sentence overall assessment

Respond ONLY in valid JSON:
{{
  "document_type": "{detected_type}",
  "checklist_score": 75,
  "summary": "...",
  "items": [
    {{
      "item": "Rent amount & due date",
      "status": "present",
      "explanation": "Rent is ₹15,000/month due on the 5th.",
      "action": null
    }},
    {{
      "item": "Notice period for termination",
      "status": "missing",
      "explanation": "No notice period is specified.",
      "action": "Ask the landlord to add a 30-day notice clause before signing."
    }}
  ]
}}
"""
        response = await client.generate(prompt, CHECKLIST_SYSTEM, temperature=0.2)

        try:
            cleaned = clean_json_response(response)
            data = json.loads(cleaned)
        except Exception:
            logger.warning("Checklist JSON parse failed — building fallback")
            data = self._fallback_checklist(detected_type, expected)

        data["document_id"] = document_id
        return data

    def _fallback_checklist(self, doc_type: str, expected: list) -> dict:
        return {
            "document_type": doc_type,
            "checklist_score": 0,
            "summary": "Checklist could not be generated automatically. Please review clauses manually.",
            "items": [
                {"item": item, "status": "missing", "explanation": "Could not verify.", "action": "Review manually."}
                for item in expected
            ],
        }


checklist_service = ChecklistService()