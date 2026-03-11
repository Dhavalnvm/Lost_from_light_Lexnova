"""
services/comparison_service.py
Contract Safety Comparison — fixed JSON parsing and uses 3b model for reliability.
"""
import json
import re
from core.task_router import get_client
from utils.logging import app_logger as logger


COMPARISON_SYSTEM = """You are an expert legal analyst specialising in contract safety evaluation.
Compare two contracts objectively. Tell someone (with no legal background) which contract
protects them better and exactly why. Respond ONLY in valid JSON."""


def _clean_json_response(response: str) -> str:
    """Robustly extract JSON from LLM response — handles markdown fences and leading text."""
    cleaned = response.strip()
    # Remove markdown fences
    if "```json" in cleaned:
        cleaned = cleaned.split("```json", 1)[1]
        cleaned = cleaned.split("```")[0]
    elif "```" in cleaned:
        cleaned = cleaned.split("```", 1)[1]
        cleaned = cleaned.split("```")[0]
    cleaned = cleaned.strip()

    # Find JSON object boundaries if LLM added preamble text
    start = cleaned.find("{")
    end = cleaned.rfind("}")
    if start != -1 and end != -1 and end > start:
        cleaned = cleaned[start:end + 1]

    return cleaned.strip()


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
        # Use fast 3b model — 8b was timing out and causing 50/50 fallback
        client = get_client("chatbot")

        # Trim texts to fit context window comfortably
        text_a_trimmed = text_a[:3000]
        text_b_trimmed = text_b[:3000]

        prompt = f"""Compare these two legal contracts for safety and fairness from the perspective of the person signing them.

CONTRACT A — {filename_a}:
{text_a_trimmed}

CONTRACT B — {filename_b}:
{text_b_trimmed}

For each major clause type present in either document, compare them.
Clause types to look for: payment terms, termination, liability, penalties,
notice period, renewal, dispute resolution, indemnification, governing law.

IMPORTANT: Only compare clauses that actually appear in the documents.
If a clause is absent from both, skip it.

Assign safety scores based on how well each contract protects the signing party:
- 80-100: Balanced and protective
- 60-79: Mostly fair with minor concerns
- 40-59: Some unfair terms
- 20-39: Several problematic clauses
- 0-19: Highly risky

Return ONLY this exact JSON structure, no markdown, no explanation:

{{
  "contract_a_safety_score": 65,
  "contract_b_safety_score": 58,
  "winner": "A",
  "percentage_difference": 7,
  "verdict": "Contract A offers slightly better protections due to clearer termination terms and capped penalties.",
  "key_differences": ["Contract A has a defined notice period; Contract B does not", "Contract B has higher late payment penalties"],
  "clause_comparisons": [
    {{
      "clause_type": "Termination Notice",
      "contract_a_text": "30 days written notice required",
      "contract_b_text": "No notice period specified",
      "winner": "A",
      "outcome": "better",
      "reason": "Contract A gives you time to prepare; B could end abruptly",
      "severity": "high"
    }}
  ]
}}"""

        response = await client.generate(prompt, COMPARISON_SYSTEM, temperature=0.0)

        try:
            cleaned = _clean_json_response(response)
            data = json.loads(cleaned)
            # Validate required keys exist
            required = ["contract_a_safety_score", "contract_b_safety_score", "winner", "verdict"]
            if not all(k in data for k in required):
                raise ValueError("Missing required keys in response")
        except Exception as e:
            logger.warning(f"Comparison JSON parse failed ({e}) — using partial fallback")
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
            "verdict": "The AI could not complete a detailed comparison for these documents. Please try again or review the documents individually using the Analyzer.",
            "key_differences": [],
            "clause_comparisons": [],
        }


comparison_service = ComparisonService()