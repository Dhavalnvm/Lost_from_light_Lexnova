from typing import List, Dict, Optional, Any
from config.settings import settings
from utils.logging import app_logger as logger

# In-memory cache: document_id → chunk count, populated on add_document_chunks
_chunk_count_cache: Dict[str, int] = {}


class VectorStore:
    """ChromaDB-backed vector store for document chunks."""

    def __init__(self):
        self._client = None
        self._collection = None

    def _init_client(self):
        if self._client is None:
            try:
                import chromadb
                self._client = chromadb.PersistentClient(path=settings.CHROMA_PERSIST_DIR)
                self._collection = self._client.get_or_create_collection(
                    name=settings.CHROMA_COLLECTION_NAME,
                    metadata={"hnsw:space": "cosine"},
                )
                logger.info("ChromaDB initialized successfully")
            except ImportError:
                raise ImportError("chromadb required: pip install chromadb")

    @property
    def collection(self):
        self._init_client()
        return self._collection

    def add_document_chunks(
        self,
        document_id: str,
        chunks: List[str],
        embeddings: List[List[float]],
        metadata: Optional[Dict[str, Any]] = None,
    ) -> None:
        """Store document chunks with their embeddings."""
        if not chunks:
            return

        base_meta = metadata or {}
        ids = [f"{document_id}_chunk_{i}" for i in range(len(chunks))]
        metadatas = [
            {**base_meta, "document_id": document_id, "chunk_index": i}
            for i in range(len(chunks))
        ]

        self.collection.add(
            ids=ids,
            documents=chunks,
            embeddings=embeddings,
            metadatas=metadatas,
        )
        _chunk_count_cache[document_id] = len(chunks)
        logger.info(f"Stored {len(chunks)} chunks for document {document_id}")

    def query_similar_chunks(
        self,
        query_embedding: List[float],
        document_id: str,
        n_results: int = 5,
    ) -> List[str]:
        """Retrieve the most relevant chunks for a query within a document."""
        # Use cached count — avoids a full ChromaDB .get() on every RAG query
        available = _chunk_count_cache.get(document_id) or self._count_document_chunks(document_id)
        clamped = min(n_results, available)
        if clamped == 0:
            return []
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=clamped,
            where={"document_id": document_id},
        )
        documents = results.get("documents", [[]])[0]
        logger.debug(f"Retrieved {len(documents)} chunks for doc {document_id}")
        return documents

    def get_all_chunks(self, document_id: str) -> List[str]:
        """Retrieve all chunks for a document."""
        results = self.collection.get(
            where={"document_id": document_id},
            include=["documents"],
        )
        return results.get("documents", [])

    def _count_document_chunks(self, document_id: str) -> int:
        results = self.collection.get(where={"document_id": document_id})
        return len(results.get("ids", []))

    def delete_document(self, document_id: str) -> None:
        """Delete all chunks for a document."""
        results = self.collection.get(where={"document_id": document_id})
        ids = results.get("ids", [])
        if ids:
            self.collection.delete(ids=ids)
            logger.info(f"Deleted {len(ids)} chunks for document {document_id}")
        _chunk_count_cache.pop(document_id, None)

    def document_exists(self, document_id: str) -> bool:
        return self._count_document_chunks(document_id) > 0


vector_store = VectorStore()