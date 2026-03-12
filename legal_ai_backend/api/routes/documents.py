from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import JSONResponse

from models.schemas import (
    UploadDocumentResponse,
    DocumentSummaryResponse,
    RiskAnalysisResponse,
    ClauseFairnessResponse,
    SafetyScoreResponse,
    ChatWithDocumentRequest,
    ChatWithDocumentResponse,
    ExplanationMode,
)
from services.document_service import document_service
from services.risk_service import risk_service
from services.fairness_service import fairness_service
from services.chat_service import chat_service
from utils.logging import app_logger as logger


router = APIRouter(prefix="/api/v1", tags=["Document Analyzer"])


# ─── Upload ────────────────────────────────────────────────────────────────────

@router.post(
    "/upload-document",
    response_model=UploadDocumentResponse,
    summary="Upload and process a legal document",
    description=(
        "Accepts PDF, DOCX, or image files. Extracts text (with OCR fallback), "
        "generates embeddings, stores in ChromaDB, and returns a document_id."
    ),
)
async def upload_document(file: UploadFile = File(...)):
    try:
        result = await document_service.upload_and_process(file)
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=f"Document processing failed: {str(e)}")


# ─── Summary ───────────────────────────────────────────────────────────────────

@router.get(
    "/document-summary/{document_id}",
    response_model=DocumentSummaryResponse,
    summary="Get AI-generated document summary",
    description=(
        "Returns plain-language summary, page summaries, detected clauses, "
        "obligations and rights. Supports beginner / student / professional modes."
    ),
)
async def get_document_summary(
    document_id: str,
    mode: ExplanationMode = Query(
        ExplanationMode.student,
        description="Explanation complexity: beginner | student | professional",
    ),
):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        return await document_service.get_summary(document_id, mode)
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Summary error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Risk Analysis ─────────────────────────────────────────────────────────────

@router.get(
    "/risk-analysis/{document_id}",
    response_model=RiskAnalysisResponse,
    summary="Detect risks and red flags in the document",
    description=(
        "Analyzes the document for high penalties, one-sided clauses, hidden fees, "
        "liability transfers, and other red flags. Returns a risk score 0–100."
    ),
)
async def get_risk_analysis(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        return await risk_service.analyze_risk(document_id, doc["full_text"])
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Risk analysis error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Clause Fairness ───────────────────────────────────────────────────────────

@router.get(
    "/clause-fairness/{document_id}",
    response_model=ClauseFairnessResponse,
    summary="Compare contract clauses against standard benchmarks",
    description=(
        "Compares key clauses (e.g. security deposit, non-compete, penalties) "
        "against typical legal standards and returns fairness ratings with AI insights."
    ),
)
async def get_clause_fairness(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        return await fairness_service.analyze_fairness(document_id, doc["full_text"])
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Fairness analysis error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Safety Score ──────────────────────────────────────────────────────────────

@router.get(
    "/safety-score/{document_id}",
    response_model=SafetyScoreResponse,
    summary="Get the overall contract safety score",
    description=(
        "Runs risk analysis + fairness comparison and computes a composite "
        "Contract Safety Score from 0–100 with recommendations."
    ),
)
async def get_safety_score(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        # Run both analyses
        risk_result = await risk_service.analyze_risk(document_id, doc["full_text"])
        fairness_result = await fairness_service.analyze_fairness(document_id, doc["full_text"])

        total_red_flags = len(risk_result.detected_red_flags)
        high_severity = sum(1 for f in risk_result.detected_red_flags if f.severity == "high")
        unfair_clauses = sum(
            1 for c in fairness_result.clauses_analyzed
            if "unfair" in c.fairness_rating.lower()
        )

        return await chat_service.calculate_safety_score(
            document_id=document_id,
            risk_score=risk_result.risk_score,
            fairness_issues=unfair_clauses,
            total_red_flags=total_red_flags,
            high_severity_flags=high_severity,
        )
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Safety score error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Chat With Document (RAG) ──────────────────────────────────────────────────

@router.post(
    "/chat-with-document",
    response_model=ChatWithDocumentResponse,
    summary="Ask questions about an uploaded document (RAG)",
    description=(
        "Retrieves relevant document chunks from ChromaDB and uses the LLM to answer "
        "the user's question grounded in the document content."
    ),
)
async def chat_with_document(request: ChatWithDocumentRequest):
    doc = document_service.get_document(request.document_id)
    if not doc:
        raise HTTPException(
            status_code=404, detail=f"Document '{request.document_id}' not found"
        )
    if not request.user_question.strip():
        raise HTTPException(status_code=400, detail="user_question cannot be empty")
    try:
        return await chat_service.chat_with_document(
            document_id=request.document_id,
            user_question=request.user_question,
            conversation_history=request.conversation_history,
        )
    except ConnectionError as e:
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.error(f"Chat error for {request.document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
