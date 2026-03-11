"""
Task router — maps analysis tasks to the appropriate LLM client.

  Smart (llama3.1:8b)  → tasks requiring deep reasoning & legal analysis
  Fast  (llama3.2:3b)  → tasks requiring speed, simple generation, or conversation

Both models run on the RTX 3050 concurrently:
  - 3b fully on GPU  (~2.0 GB VRAM)
  - 8b partial GPU   (~4.7 GB VRAM, overflow to DDR5 RAM)
"""

from core.llm_client import llm_client_smart, llm_client_fast

# ─── Task → Model mapping ─────────────────────────────────────────────────────

_TASK_MAP = {
    # Heavy reasoning → 8b
    "summary":     llm_client_smart,
    "risk":        llm_client_smart,
    "fairness":    llm_client_smart,

    # Fast / conversational → 3b
    "chatbot":     llm_client_fast,
    "translation": llm_client_fast,
    "safety":      llm_client_fast,   # safety score is mostly math, LLM only for recs
    "guidance":    llm_client_fast,
    "chat":        llm_client_fast,   # RAG chat — retrieval does the heavy lifting
}


def get_client(task: str):
    """
    Return the appropriate OllamaClient for a given task name.
    Falls back to smart client for unknown tasks.
    """
    client = _TASK_MAP.get(task.lower(), llm_client_smart)
    return client