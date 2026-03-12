"""
services/comparison_service.py
--------------------------------
Feature A: Contract Safety Comparison
Compares two uploaded documents and produces a clause-by-clause safety diff.
Uses 8b model (heavy reasoning task).
"""
import json
from core.task_router import get_client
from utils.helpers import clean_json_response
from utils.logging import app_logger as logger

COMPARISON_SYSTEM = """You are an expert legal analyst specialising in contract safety evaluation.
Compare two contracts objectively. Your goal: tell someone (with no legal background)
which contract protects them better and exactly why."""


class ComparisonService:

    async def compare_contracts(
        self,
        doc_id_a: str,
        text_a: str,
        filename_a: str,
        doc_id_b: str,
        text_b: str,
        filename_b: str,
    ) -> dict:
        """
        Side-by-side safety comparison. Returns structured JSON with:
        - overall winner + percentage safer
        - per-clause comparison items (better / worse / similar)
        - actionable verdict
        """
        client = get_client("comparison")

        prompt = f"""
Compare these two legal contracts for safety and fairness from the perspective of the person signing them.

CONTRACT A ({filename_a}):
{text_a[:4000]}

CONTRACT B ({filename_b}):
{text_b[:4000]}

Analyse ALL key clause types: payment terms, termination, liability, penalties, non-compete,
dispute resolution, renewal, confidentiality, indemnification, IP rights, governing law.

For each clause type found in either document, provide:
- clause_type: the clause name
- contract_a_text: what Contract A says (brief, max 60 words)
- contract_b_text: what Contract B says (brief, max 60 words)
- winner: "A" | "B" | "tie"
- outcome: "better" | "worse" | "similar"  (from Contract A's perspective)
- reason: plain-English explanation of WHY A is better/worse (max 40 words)
- severity: "high" | "medium" | "low"

Also compute:
- contract_a_safety_score: 0-100 integer
- contract_b_safety_score: 0-100 integer
- winner: "A" | "B" | "tie"
- percentage_difference: positive integer (how much safer the winner is)
- verdict: 1-2 sentence actionable conclusion for a non-lawyer
- key_differences: list of 3-5 most impactful differences (strings)

Respond ONLY in valid JSON:
{{
  "contract_a_safety_score": 72,
  "contract_b_safety_score": 55,
  "winner": "A",
  "percentage_difference": 17,
  "verdict": "...",
  "key_differences": ["...", "..."],
  "clause_comparisons": [
    {{
      "clause_type": "...",
      "contract_a_text": "...",
      "contract_b_text": "...",
      "winner": "A",
      "outcome": "better",
      "reason": "...",
      "severity": "high"
    }}
  ]
}}
"""
        response = await client.generate(prompt, COMPARISON_SYSTEM, temperature=0.2)

        try:
            cleaned = clean_json_response(response)
            data = json.loads(cleaned)
        except Exception:
            logger.warning("Comparison JSON parse failed — using fallback")
            data = self._fallback(doc_id_a, doc_id_b)

        data["doc_id_a"] = doc_id_a
        data["doc_id_b"] = doc_id_b
        data["filename_a"] = filename_a
        data["filename_b"] = filename_b
        return data

    def _fallback(self, doc_id_a: str, doc_id_b: str) -> dict:
        return {
            "contract_a_safety_score": 50,
            "contract_b_safety_score": 50,
            "winner": "tie",
            "percentage_difference": 0,
            "verdict": "Unable to fully compare documents. Please review manually.",
            "key_differences": [],
            "clause_comparisons": [],
        }


comparison_service = ComparisonService()