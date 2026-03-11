import httpx
from typing import List
from config.settings import settings
from utils.logging import app_logger as logger


class EmbeddingsManager:
    """Manages embeddings via Ollama (bge-m3 or any Ollama embedding model)."""

    async def embed_texts(self, texts: List[str]) -> List[List[float]]:
        if not texts:
            return []
        logger.debug(f"Generating embeddings for {len(texts)} chunks via Ollama")
        try:
            async with httpx.AsyncClient(timeout=60) as client:
                response = await client.post(
                    f"{settings.OLLAMA_BASE_URL}/api/embed",
                    json={"model": settings.EMBEDDING_MODEL, "input": texts}
                )
                response.raise_for_status()
                return response.json()["embeddings"]
        except httpx.TimeoutException:
            logger.error("Embedding timed out — Ollama busy with LLM inference")
            raise
        except httpx.ConnectError:
            logger.error(f"Cannot connect to Ollama at {settings.OLLAMA_BASE_URL}")
            raise
        except Exception as e:
            logger.error(f"Embedding failed: {type(e).__name__}: {e}")
            raise

    async def embed_query(self, query: str) -> List[float]:
        logger.debug("Generating query embedding via Ollama")
        results = await self.embed_texts([query])
        return results[0]


embeddings_manager = EmbeddingsManager()