from pydantic_settings import BaseSettings
from pathlib import Path


class Settings(BaseSettings):
    # App
    APP_NAME: str = "Legal AI Backend"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Ollama
    OLLAMA_BASE_URL: str = "http://localhost:11434"

    # Dual model config
    # 8b  → deep reasoning: summary, risk analysis, clause fairness
    # 3b  → fast tasks:     chatbot, translation, safety score
    OLLAMA_MODEL_SMART: str = "llama3.1:8b"   # RTX 3050 — partial GPU offload
    OLLAMA_MODEL_FAST: str = "llama3.2:3b"    # RTX 3050 — fully on GPU

    # Keep OLLAMA_MODEL as alias for health-check / legacy use
    @property
    def OLLAMA_MODEL(self) -> str:
        return self.OLLAMA_MODEL_SMART

    OLLAMA_TIMEOUT: int = 120

    # ChromaDB
    CHROMA_PERSIST_DIR: str = "storage/chroma_db"
    CHROMA_COLLECTION_NAME: str = "legal_documents"

    # Embeddings
    EMBEDDING_MODEL: str = "bge-m3:567m"

    # Storage
    UPLOAD_DIR: str = "storage/documents"
    MAX_FILE_SIZE_MB: int = 50

    # Chunking — increased limits for RTX 3050 + 8b model
    CHUNK_SIZE: int = 1000
    CHUNK_OVERLAP: int = 100

    # Text limits for LLM context (8b has 128k context — use more of it)
    SUMMARY_TEXT_LIMIT: int = 15000
    ANALYSIS_TEXT_LIMIT: int = 10000

    # Logging
    LOG_DIR: str = "logs"
    LOG_LEVEL: str = "INFO"

    class Config:
        env_file = ".env"


settings = Settings()

# Ensure directories exist
Path(settings.UPLOAD_DIR).mkdir(parents=True, exist_ok=True)
Path(settings.CHROMA_PERSIST_DIR).mkdir(parents=True, exist_ok=True)
Path(settings.LOG_DIR).mkdir(parents=True, exist_ok=True)