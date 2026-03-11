from fastapi import APIRouter, HTTPException
from models.schemas import LegalChatRequest, LegalChatResponse
from services.chatbot_service import legal_chatbot_service
from utils.logging import app_logger as logger


router = APIRouter(prefix="/api/v1", tags=["AI Legal Chatbot"])


@router.post(
    "/legal-chat",
    response_model=LegalChatResponse,
    summary="Ask a general legal question",
    description=(
        "AI-powered legal chatbot for general legal questions. "
        "Not tied to any specific uploaded document. "
        "Supports multi-turn conversations and multiple languages."
    ),
)
async def legal_chat(request: LegalChatRequest):
    if not request.user_message.strip():
        raise HTTPException(status_code=400, detail="user_message cannot be empty")
    try:
        return await legal_chatbot_service.chat(
            user_message=request.user_message,
            conversation_history=request.conversation_history,
            language=request.language or "English",
        )
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Legal chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
