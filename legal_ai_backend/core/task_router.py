from core.llm_client import OllamaClient
from utils.logging import app_logger as logger

# ── Singleton clients ──────────────────────────────────────────────────────────
llm_client_smart = OllamaClient(model="llama3.1:8b")   # heavy reasoning
llm_client_fast  = OllamaClient(model="llama3.2:3b")   # fast tasks

# ── Task classification ────────────────────────────────────────────────────────
_FAST_TASKS = {
    "chat",
    "chatbot",
    "rag_chat",
    "translation",
    "safety_score",
    "checklist",
}

_SMART_TASKS = {
    "summary",
    "risk",
    "fairness",
    "comparison",
    "rewrite",
    "version_diff",
}


def get_client(task: str) -> OllamaClient:
    """Return the appropriate Ollama client for the given task type."""
    if task in _FAST_TASKS:
        return llm_client_fast
    if task in _SMART_TASKS:
        return llm_client_smart
    logger.warning(f"Unknown task type '{task}' — defaulting to smart client")
    return llm_client_smart