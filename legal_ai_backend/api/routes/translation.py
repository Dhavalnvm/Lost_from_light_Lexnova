from fastapi import APIRouter, HTTPException
from models.schemas import TranslateRequest, TranslateResponse
from services.translation_service import translation_service
from utils.logging import app_logger as logger


router = APIRouter(prefix="/api/v1", tags=["Translation"])


@router.post(
    "/translate-response",
    response_model=TranslateResponse,
    summary="Translate text to a target language",
    description=(
        "Translates any text into the specified language. "
        "Supported: English, Hindi, Marathi, Spanish, French, German, Arabic, Chinese, Japanese, Portuguese."
    ),
)
async def translate_response(request: TranslateRequest):
    if not request.text.strip():
        raise HTTPException(status_code=400, detail="text cannot be empty")
    if not request.target_language.strip():
        raise HTTPException(status_code=400, detail="target_language is required")
    try:
        return await translation_service.translate(
            text=request.text,
            target_language=request.target_language,
            source_language=request.source_language or "auto",
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Translation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/supported-languages",
    summary="List all supported languages for translation",
)
async def get_supported_languages():
    return translation_service.get_supported_languages()
