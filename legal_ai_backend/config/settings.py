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
    OLLAMA_TIMEOUT: int = 180

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

    # ✅ FIX: LLM text limits (were missing — caused the 3 errors)
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