"""
core/task_router.py
--------------------
Routes tasks to the correct Ollama client.

Hardware:  RTX 3050 (4 GB VRAM, CUDA) + Ryzen 5 5500U CPU
           AMD iGPU shares system RAM — not used for inference

─────────────────────────────────────────────────────────────────────────────
  llama3.1:8b  (SMART)  — RTX 3050 partial + CPU overflow
    num_gpu=99 → Ollama CUDA auto-fits ~24 of 32 layers on GPU (~3.5 GB),
    remaining layers overflow to CPU automatically.
    ctx=4096 → KV-cache ~0.5 GB

  llama3.2:3b  (FAST)   — RTX 3050 full
    num_gpu=99 → all 28 layers fit in ~2 GB VRAM, nothing on CPU.
    ctx=4096 → KV-cache ~0.2 GB

  BGE-M3 (embeddings)   — RTX 3050
    ~0.5 GB, handled by Ollama separately via /api/embed.

  Peak VRAM: BGE-M3 (0.5) + 8b GPU layers (3.5) = ~4.0 GB ✅
─────────────────────────────────────────────────────────────────────────────
"""
from core.llm_client import OllamaClient
from config.settings import settings

# ── Singleton clients ──────────────────────────────────────────────────────────

llm_client_smart = OllamaClient(
    model=settings.OLLAMA_MODEL_SMART,
    gpu_layers=settings.SMART_GPU_LAYERS,   # 99 → auto-max on RTX 3050
    num_ctx=settings.SMART_NUM_CTX,         # 4096
    num_predict=settings.SMART_NUM_PREDICT, # 2048
)

llm_client_fast = OllamaClient(
    model=settings.OLLAMA_MODEL_FAST,
    gpu_layers=settings.FAST_GPU_LAYERS,    # 99 → fully on RTX 3050
    num_ctx=settings.FAST_NUM_CTX,          # 4096
    num_predict=settings.FAST_NUM_PREDICT,  # 1024
)

# ── Task classification ────────────────────────────────────────────────────────

_FAST_TASKS = {
    "chat",
    "chatbot",
    "rag_chat",
    "translation",
    "safety_score",
    "checklist",
    "group_chat",
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
    if task in _FAST_TASKS:
        return llm_client_fast
    if task in _SMART_TASKS:
        return llm_client_smart
    return llm_client_fast  # safe default