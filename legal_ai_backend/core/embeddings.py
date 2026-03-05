import asyncio
import httpx
from typing import List
from config.settings import settings
from utils.logging import app_logger as logger


class EmbeddingsManager:
    """Manages embeddings via Ollama (bge-m3 or any Ollama embedding model)."""

    async def _embed_async(self, texts: List[str]) -> List[List[float]]:
        async with httpx.AsyncClient(timeout=60) as client:
            response = await client.post(
                f"{settings.OLLAMA_BASE_URL}/api/embed",
                json={"model": settings.EMBEDDING_MODEL, "input": texts}
            )
            response.raise_for_status()
            return response.json()["embeddings"]

    def embed_texts(self, texts: List[str]) -> List[List[float]]:
        """Generate embeddings for a list of text strings."""
        if not texts:
            return []
        logger.debug(f"Generating embeddings for {len(texts)} chunks via Ollama")
        return asyncio.run(self._embed_async(texts))

    def embed_query(self, query: str) -> List[float]:
        """Generate a single query embedding."""
        logger.debug(f"Generating query embedding via Ollama")
        return asyncio.run(self._embed_async([query]))[0]


embeddings_manager = EmbeddingsManager()