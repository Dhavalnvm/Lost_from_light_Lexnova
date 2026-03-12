"""
services/version_diff_service.py
----------------------------------
Feature D: Contract Version Comparison (v1 vs v2)
Identifies what changed between two versions of the same contract type,
flags whether new version is more or less favorable.
Uses 8b model (heavy reasoning task).
"""
import json
from core.task_router import get_client
from utils.logging import app_logger as logger

DIFF_SYSTEM = """You are a legal expert specialising in contract revision analysis.
Your job is to compare two versions of the same contract and clearly explain
what changed, whether changes are favorable or unfavorable to the signer,
and what they should watch out for."""


class VersionDiffService:

    async def compare_versions(
        self,
        document_id_v1: str,
        text_v1: str,
        filename_v1: str,
        document_id_v2: str,
        text_v2: str,
        filename_v2: str,
    ) -> dict:
        """
        Compare v1 and v2 of the same contract.
        Returns structured diff with favorability rating for each change.
        """
        client = get_client("version_diff")

        prompt = f"""
Compare these two versions of the same contract type. Identify what changed between them.

VERSION 1 ({filename_v1}):
{text_v1[:3500]}

VERSION 2 ({filename_v2}):
{text_v2[:3500]}

For each change detected, provide:
- clause_type: which clause changed
- change_type: "added" | "removed" | "modified"
- v1_text: what it said in version 1 (max 60 words, or "Not present" if new)
- v2_text: what it says in version 2 (max 60 words, or "Removed" if deleted)
- favorability: "more_favorable" | "less_favorable" | "neutral"
  (from the SIGNER'S perspective — is v2 better or worse for them?)
- impact: "high" | "medium" | "low"
- plain_explanation: explain the change in plain English (max 50 words)

Also:
- overall_verdict: is v2 better or worse overall for the signer?
  "significantly_better" | "slightly_better" | "neutral" | "slightly_worse" | "significantly_worse"
- summary: 2-sentence human summary of the most important changes
- favorable_changes: count of changes that help the signer
- unfavorable_changes: count of changes that hurt the signer
- new_restrictions_added: list of new restrictions added in v2 (strings, may be empty)
- rights_removed: list of rights removed in v2 (strings, may be empty)

Respond ONLY in valid JSON:
{{
  "overall_verdict": "slightly_worse",
  "summary": "...",
  "favorable_changes": 2,
  "unfavorable_changes": 4,
  "new_restrictions_added": ["..."],
  "rights_removed": ["..."],
  "changes": [
    {{
      "clause_type": "Notice Period",
      "change_type": "modified",
      "v1_text": "30 days notice required",
      "v2_text": "60 days notice required",
      "favorability": "less_favorable",
      "impact": "high",
      "plain_explanation": "You now need to give twice as much notice before leaving."
    }}
  ]
}}
"""
        response = await client.generate(prompt, DIFF_SYSTEM, temperature=0.2)

        try:
            cleaned = response.strip().strip("```json").strip("```").strip()
            data = json.loads(cleaned)
        except Exception:
            logger.warning("Version diff JSON parse failed — fallback")
            data = {
                "overall_verdict": "neutral",
                "summary": "Version comparison could not be completed. Review manually.",
                "favorable_changes": 0,
                "unfavorable_changes": 0,
                "new_restrictions_added": [],
                "rights_removed": [],
                "changes": [],
            }

        data["document_id_v1"] = document_id_v1
        data["document_id_v2"] = document_id_v2
        data["filename_v1"] = filename_v1
        data["filename_v2"] = filename_v2
        return data


version_diff_service = VersionDiffService()