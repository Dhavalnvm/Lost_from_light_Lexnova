"""
services/rewrite_service.py
----------------------------
Feature B: Clause Rewriting Suggestions
For every risky or unfair clause, produce:
  original → why it's risky → safe rewrite → negotiation tip
Uses 8b model (deep reasoning task).
"""
import json
from core.task_router import get_client
from utils.logging import app_logger as logger

REWRITE_SYSTEM = """You are a senior contract attorney and plain-language expert.
Your job is to rewrite dangerous contract clauses into fair, balanced versions
while keeping the legal intent intact. Provide practical negotiation advice."""

TONE_INSTRUCTIONS = {
    "firm":     "Use assertive, direct language. The rewrite should strongly protect the signer's rights.",
    "polite":   "Use collaborative, respectful language. The rewrite should still protect rights but be approachable.",
    "standard": "Use balanced, professional legal language appropriate for standard contracts.",
}


class RewriteService:

    async def get_rewrite_suggestions(
        self,
        document_id: str,
        full_text: str,
        tone: str = "standard",
    ) -> dict:
        """
        Identify risky / unfair clauses and suggest safer rewrites.
        tone: "firm" | "polite" | "standard"
        """
        client = get_client("rewrite")
        tone_instr = TONE_INSTRUCTIONS.get(tone, TONE_INSTRUCTIONS["standard"])

        prompt = f"""
Analyse this legal document and identify every clause that is risky, unfair, or one-sided.

DOCUMENT:
{full_text[:5000]}

TONE: {tone_instr}

For each risky clause found, provide:
- clause_type: short label (e.g., "Non-Compete", "Penalty Clause")
- original_text: the exact clause text from the document (max 100 words)
- risk_reason: plain-English explanation of why it's risky/unfair (max 50 words)
- risk_level: "high" | "medium" | "low"
- suggested_rewrite: a safer, balanced version of the clause ({tone} tone, max 100 words)
- negotiation_tip: what to say when negotiating this clause (max 40 words, practical advice)
- what_to_do_if_refused: what the signer should do if the other party refuses to change it (max 30 words)

Also provide:
- overall_assessment: 2-sentence summary of contract safety
- total_risky_clauses: count
- rewrite_difficulty: "Easy" | "Moderate" | "Hard" (how hard it will be to negotiate changes)

Respond ONLY in valid JSON:
{{
  "overall_assessment": "...",
  "total_risky_clauses": 4,
  "rewrite_difficulty": "Moderate",
  "suggestions": [
    {{
      "clause_type": "...",
      "original_text": "...",
      "risk_reason": "...",
      "risk_level": "high",
      "suggested_rewrite": "...",
      "negotiation_tip": "...",
      "what_to_do_if_refused": "..."
    }}
  ]
}}
"""
        response = await client.generate(prompt, REWRITE_SYSTEM, temperature=0.25)

        try:
            cleaned = response.strip().strip("```json").strip("```").strip()
            data = json.loads(cleaned)
        except Exception:
            logger.warning("Rewrite JSON parse failed — fallback")
            data = {
                "overall_assessment": "Unable to complete rewrite analysis. Review clauses manually.",
                "total_risky_clauses": 0,
                "rewrite_difficulty": "Unknown",
                "suggestions": [],
            }

        data["document_id"] = document_id
        data["tone"] = tone
        return data


rewrite_service = RewriteService()