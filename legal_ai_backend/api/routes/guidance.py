from fastapi import APIRouter, HTTPException
from models.schemas import RequiredDocumentsResponse
from services.guidance_service import guidance_service
from utils.logging import app_logger as logger


router = APIRouter(prefix="/api/v1", tags=["Documents Guidance"])


@router.get(
    "/required-documents/{category}",
    response_model=RequiredDocumentsResponse,
    summary="Get required documents for a legal process",
    description=(
        "Returns the list of required documents, where to obtain them, "
        "and step-by-step instructions for a given category. "
        "Available categories: housing, loan, employment, business, education, "
        "insurance, digital, personal"
    ),
)
async def get_required_documents(category: str):
    try:
        return guidance_service.get_required_documents(category)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Guidance error for {category}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get(
    "/document-categories",
    summary="List all available document guidance categories",
    description="Returns all available categories for the required documents guidance feature.",
)
async def list_categories():
    return guidance_service.get_all_categories()
