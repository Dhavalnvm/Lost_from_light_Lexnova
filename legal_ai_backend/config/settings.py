from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    # App
    APP_NAME: str = "LexNova Legal AI Backend"
    APP_VERSION: str = "2.0.0"
    DEBUG: bool = False

    # Ollama
    OLLAMA_BASE_URL: str = "http://localhost:11434"
    OLLAMA_MODEL: str = "llama3.2:3b"
    OLLAMA_MODEL_SMART: str = "llama3.1:8b"
    OLLAMA_MODEL_FAST: str = "llama3.2:3b"
    OLLAMA_TIMEOUT: int = 240

    # ── GPU Strategy ───────────────────────────────────────────────────────────
    #
    # Hardware:
    #   RTX 3050   → 4 GB GDDR6  (NVIDIA CUDA — primary inference GPU)
    #   Ryzen iGPU → shared RAM  (AMD — leave for OS, not used for inference)
    #   CPU        → auto overflow when VRAM is full
    #
    # Model VRAM usage (Q4_K_M quantization):
    #   BGE-M3  567M  → ~0.5 GB  always resident on RTX 3050
    #   llama3.2:3b   → ~2.0 GB  fits fully on RTX 3050
    #   llama3.1:8b   → ~4.7 GB  partially on RTX 3050, overflow layers → CPU
    #
    # num_gpu=99 tells Ollama: "put as many layers as possible on GPU,
    # automatically overflow the rest to CPU". With CUDA this is reliable.
    # The AMD iGPU is NOT used — mixing CUDA + ROCm for a single model
    # adds latency from cross-bus transfers, not a win.
    #
    # Peak VRAM usage (worst case — 8b running):
    #   BGE-M3 (~0.5 GB) + 8b GPU layers (~3.5 GB) = ~4.0 GB  ✅ fits
    #
    SMART_GPU_LAYERS: int = 99   # Ollama auto-fits 8b — overflow to CPU
    FAST_GPU_LAYERS: int = 99    # 3b fits fully on RTX 3050

    # ── Context windows ────────────────────────────────────────────────────────
    # Smaller ctx = smaller KV-cache = more VRAM left for model weights.
    # 4096 is plenty for legal document Q&A.
    SMART_NUM_CTX: int = 4096
    FAST_NUM_CTX: int = 4096

    # ── Output token limits ────────────────────────────────────────────────────
    SMART_NUM_PREDICT: int = 2048   # 8b: detailed but bounded
    FAST_NUM_PREDICT: int = 1024    # 3b: concise

    # MongoDB
    MONGODB_URI: str = "mongodb+srv://nocap7884_db_user:WXNZFlDBR8gUDkiU@cluster0.g7kk8z4.mongodb.net/?appName=Cluster0"
    MONGODB_DB_NAME: str = "lexnova"

    # JWT Auth
    JWT_SECRET_KEY: str = "lexnova-secret-key-change-in-production-2024"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 24 * 7

    # ChromaDB
    CHROMA_PERSIST_DIR: str = "storage/chroma_db"
    CHROMA_COLLECTION_NAME: str = "legal_documents"

    # Embeddings
    EMBEDDING_MODEL: str = "bge-m3:567m"

    # Storage
    UPLOAD_DIR: str = "storage/documents"
    MAX_FILE_SIZE_MB: int = 50

    # Chunking
    CHUNK_SIZE: int = 1000
    CHUNK_OVERLAP: int = 100

    # LLM text limits
    SUMMARY_TEXT_LIMIT: int = 15000
    ANALYSIS_TEXT_LIMIT: int = 10000

    # Logging
    LOG_DIR: str = "logs"
    LOG_LEVEL: str = "INFO"

    class Config:
        env_file = ".env"


settings = Settings()

Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
Path(settings.CHROMA_PERSIST_DIR).mkdir(parents=True, exist_ok=True)
Path(settings.LOG_DIR).mkdir(parents=True, exist_ok=True)