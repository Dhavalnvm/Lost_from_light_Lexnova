from typing import List, Dict
from core.llm_client import llm_client
from core.embeddings import embeddings_manager
from core.vector_store import vector_store
from utils.logging import app_logger as logger
from models.schemas import ChatWithDocumentResponse, SafetyScoreResponse


RAG_SYSTEM_PROMPT = """You are a legal document assistant. You help users understand their 
legal documents by answering questions based ONLY on the document content provided to you.

Rules:
- Answer ONLY from the provided document context
- If the answer is not in the document, say "This information is not found in the document"
- Never give personal legal advice
- Be clear, concise, and accurate
- Cite relevant sections when possible"""


class ChatService:

    async def chat_with_document(
        self,
        document_id: str,
        user_question: str,
        conversation_history: List[Dict[str, str]] = None,
    ) -> ChatWithDocumentResponse:
        """RAG-powered Q&A over a specific document."""
        # Get query embedding
        query_embedding = embeddings_manager.embed_query(user_question)

        # Retrieve relevant chunks
        relevant_chunks = vector_store.query_similar_chunks(
            query_embedding=query_embedding,
            document_id=document_id,
            n_results=5,
        )

        if not relevant_chunks:
            return ChatWithDocumentResponse(
                document_id=document_id,
                user_question=user_question,
                ai_response="I could not find relevant content in this document to answer your question.",
                source_chunks=[],
            )

        context = "\n\n---\n\n".join(relevant_chunks)

        prompt = f"""Based on the following document excerpts, answer the user's question.

DOCUMENT CONTEXT:
{context}

USER QUESTION: {user_question}

Provide a clear, accurate answer based only on the document content above."""

        history = conversation_history or []
        response = await llm_client.generate_with_history(
            user_message=prompt,
            conversation_history=history,
            system_prompt=RAG_SYSTEM_PROMPT,
        )

        logger.info(f"Chat response generated for doc {document_id}, question length={len(user_question)}")

        return ChatWithDocumentResponse(
            document_id=document_id,
            user_question=user_question,
            ai_response=response,
            source_chunks=relevant_chunks[:3],
        )

    async def calculate_safety_score(
        self,
        document_id: str,
        risk_score: int,
        fairness_issues: int,
        total_red_flags: int,
        high_severity_flags: int,
    ) -> SafetyScoreResponse:
        """Calculate an overall contract safety score."""

        # Safety is inverse of risk
        base_safety = 100 - risk_score

        # Deduct for fairness issues
        fairness_deduction = min(20, fairness_issues * 5)

        # Deduct for high severity flags
        severity_deduction = min(15, high_severity_flags * 5)

        safety_score = max(0, base_safety - fairness_deduction - severity_deduction)

        # Determine level
        if safety_score >= 70:
            risk_level = "Low"
        elif safety_score >= 40:
            risk_level = "Medium"
        else:
            risk_level = "High"

        # Generate recommendations
        recommendations = []
        if high_severity_flags > 0:
            recommendations.append(
                f"⚠️ {high_severity_flags} high-severity clause(s) detected — consult a lawyer before signing"
            )
        if fairness_issues > 2:
            recommendations.append("📊 Multiple clauses are outside standard benchmarks — negotiate key terms")
        if total_red_flags > 5:
            recommendations.append("🚩 Numerous red flags — have the contract reviewed professionally")
        if safety_score >= 70:
            recommendations.append("✅ Contract appears generally safe — review highlighted clauses anyway")

        return SafetyScoreResponse(
            document_id=document_id,
            safety_score=safety_score,
            risk_level=risk_level,
            score_breakdown={
                "base_score": base_safety,
                "risk_score_contribution": risk_score,
                "fairness_deduction": fairness_deduction,
                "severity_deduction": severity_deduction,
                "total_red_flags": total_red_flags,
                "high_severity_flags": high_severity_flags,
            },
            recommendations=recommendations,
        )


chat_service = ChatService()
