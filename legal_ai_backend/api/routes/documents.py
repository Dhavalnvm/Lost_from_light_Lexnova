import asyncio
import json
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, AsyncGenerator

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

UPLOAD_TIMEOUT   = 120
SUMMARY_TIMEOUT  = 180
ANALYSIS_TIMEOUT = 150
CHAT_TIMEOUT     = 90


# ─── Helpers ───────────────────────────────────────────────────────────────────

def sse_event(event: str, data: dict) -> str:
    """Format a Server-Sent Event string."""
    return f"event: {event}\ndata: {json.dumps(data)}\n\n"


# ─── Upload ────────────────────────────────────────────────────────────────────

@router.post("/upload-document", response_model=UploadDocumentResponse,
    summary="Upload and process a legal document")
async def upload_document(file: UploadFile = File(...)):
    try:
        result = await asyncio.wait_for(
            document_service.upload_and_process(file), timeout=UPLOAD_TIMEOUT)
        return result
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail=f"Upload timed out after {UPLOAD_TIMEOUT}s.")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Upload error: {e}")
        raise HTTPException(status_code=500, detail=f"Document processing failed: {str(e)}")


# ─── Streaming Analysis (SSE) ──────────────────────────────────────────────────

async def analysis_stream(document_id: str, mode: ExplanationMode) -> AsyncGenerator[str, None]:
    """
    Yields SSE events for each analysis step as they complete:
      - event: status   → progress updates ("Starting summary...", etc.)
      - event: summary  → DocumentSummaryResponse JSON
      - event: risk     → RiskAnalysisResponse JSON
      - event: fairness → ClauseFairnessResponse JSON
      - event: safety   → SafetyScoreResponse JSON
      - event: error    → { step, message } on partial failure
      - event: done     → { message: "Analysis complete" }
    """
    doc = document_service.get_document(document_id)
    if not doc:
        yield sse_event("error", {"step": "init", "message": f"Document '{document_id}' not found"})
        return

    risk_result     = None
    fairness_result = None

    # ── Step 1: Summary ────────────────────────────────────────────────────────
    yield sse_event("status", {"step": "summary", "message": "Generating document summary..."})
    try:
        summary = await asyncio.wait_for(
            document_service.get_summary(document_id, mode), timeout=SUMMARY_TIMEOUT)
        yield sse_event("summary", summary.dict())
        logger.info(f"[{document_id}] Summary ✅")
    except asyncio.TimeoutError:
        yield sse_event("error", {"step": "summary", "message": f"Summary timed out after {SUMMARY_TIMEOUT}s"})
        logger.error(f"[{document_id}] Summary timed out")
    except Exception as e:
        yield sse_event("error", {"step": "summary", "message": str(e)})
        logger.error(f"[{document_id}] Summary failed: {e}")

    # ── Step 2: Risk Analysis ──────────────────────────────────────────────────
    yield sse_event("status", {"step": "risk", "message": "Analyzing risks and red flags..."})
    try:
        risk_result = await asyncio.wait_for(
            risk_service.analyze_risk(document_id, doc["full_text"]), timeout=ANALYSIS_TIMEOUT)
        yield sse_event("risk", risk_result.dict())
        logger.info(f"[{document_id}] Risk ✅")
    except asyncio.TimeoutError:
        yield sse_event("error", {"step": "risk", "message": f"Risk analysis timed out after {ANALYSIS_TIMEOUT}s"})
        logger.error(f"[{document_id}] Risk timed out")
    except Exception as e:
        yield sse_event("error", {"step": "risk", "message": str(e)})
        logger.error(f"[{document_id}] Risk failed: {e}")

    # ── Step 3: Clause Fairness ────────────────────────────────────────────────
    yield sse_event("status", {"step": "fairness", "message": "Checking clause fairness..."})
    try:
        fairness_result = await asyncio.wait_for(
            fairness_service.analyze_fairness(document_id, doc["full_text"]), timeout=ANALYSIS_TIMEOUT)
        yield sse_event("fairness", fairness_result.dict())
        logger.info(f"[{document_id}] Fairness ✅")
    except asyncio.TimeoutError:
        yield sse_event("error", {"step": "fairness", "message": f"Fairness timed out after {ANALYSIS_TIMEOUT}s"})
        logger.error(f"[{document_id}] Fairness timed out")
    except Exception as e:
        yield sse_event("error", {"step": "fairness", "message": str(e)})
        logger.error(f"[{document_id}] Fairness failed: {e}")

    # ── Step 4: Safety Score ───────────────────────────────────────────────────
    yield sse_event("status", {"step": "safety", "message": "Calculating overall safety score..."})
    try:
        if risk_result and fairness_result:
            total_red_flags = len(risk_result.detected_red_flags)
            high_severity   = sum(1 for f in risk_result.detected_red_flags if f.severity == "high")
            unfair_clauses  = sum(
                1 for c in fairness_result.clauses_analyzed
                if "unfair" in c.fairness_rating.lower())
            safety = await asyncio.wait_for(
                chat_service.calculate_safety_score(
                    document_id=document_id,
                    risk_score=risk_result.risk_score,
                    fairness_issues=unfair_clauses,
                    total_red_flags=total_red_flags,
                    high_severity_flags=high_severity,
                ), timeout=60)
            yield sse_event("safety", safety.dict())
            logger.info(f"[{document_id}] Safety ✅")
        else:
            yield sse_event("error", {"step": "safety", "message": "Skipped — risk or fairness data unavailable"})
    except asyncio.TimeoutError:
        yield sse_event("error", {"step": "safety", "message": "Safety score timed out after 60s"})
        logger.error(f"[{document_id}] Safety timed out")
    except Exception as e:
        yield sse_event("error", {"step": "safety", "message": str(e)})
        logger.error(f"[{document_id}] Safety failed: {e}")

    # ── Done ───────────────────────────────────────────────────────────────────
    yield sse_event("done", {"message": "Analysis complete"})


@router.get(
    "/analyze-stream/{document_id}",
    summary="Stream analysis results step by step (SSE)",
    description=(
        "Returns a text/event-stream. Events: status, summary, risk, fairness, safety, error, done. "
        "Each result is pushed to the client as soon as that step finishes — "
        "no waiting for all steps to complete."
    ),
    response_class=StreamingResponse,
)
async def analyze_stream(
    document_id: str,
    mode: ExplanationMode = Query(ExplanationMode.student),
):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")

    return StreamingResponse(
        analysis_stream(document_id, mode),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "X-Accel-Buffering": "no",   # disables nginx buffering if behind proxy
            "Connection": "keep-alive",
        },
    )


# ─── Individual endpoints (kept for direct access) ─────────────────────────────

@router.get("/document-summary/{document_id}", response_model=DocumentSummaryResponse)
async def get_document_summary(
    document_id: str,
    mode: ExplanationMode = Query(ExplanationMode.student),
):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        return await asyncio.wait_for(
            document_service.get_summary(document_id, mode), timeout=SUMMARY_TIMEOUT)
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail=f"Summary timed out after {SUMMARY_TIMEOUT}s.")
    except Exception as e:
        logger.error(f"Summary error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/risk-analysis/{document_id}", response_model=RiskAnalysisResponse)
async def get_risk_analysis(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        return await asyncio.wait_for(
            risk_service.analyze_risk(document_id, doc["full_text"]), timeout=ANALYSIS_TIMEOUT)
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail=f"Risk analysis timed out after {ANALYSIS_TIMEOUT}s.")
    except Exception as e:
        logger.error(f"Risk analysis error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/clause-fairness/{document_id}", response_model=ClauseFairnessResponse)
async def get_clause_fairness(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        return await asyncio.wait_for(
            fairness_service.analyze_fairness(document_id, doc["full_text"]), timeout=ANALYSIS_TIMEOUT)
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail=f"Fairness timed out after {ANALYSIS_TIMEOUT}s.")
    except Exception as e:
        logger.error(f"Fairness error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/safety-score/{document_id}", response_model=SafetyScoreResponse)
async def get_safety_score(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        risk_result = await asyncio.wait_for(
            risk_service.analyze_risk(document_id, doc["full_text"]), timeout=ANALYSIS_TIMEOUT)
        fairness_result = await asyncio.wait_for(
            fairness_service.analyze_fairness(document_id, doc["full_text"]), timeout=ANALYSIS_TIMEOUT)
        total_red_flags = len(risk_result.detected_red_flags)
        high_severity   = sum(1 for f in risk_result.detected_red_flags if f.severity == "high")
        unfair_clauses  = sum(
            1 for c in fairness_result.clauses_analyzed
            if "unfair" in c.fairness_rating.lower())
        return await asyncio.wait_for(
            chat_service.calculate_safety_score(
                document_id=document_id,
                risk_score=risk_result.risk_score,
                fairness_issues=unfair_clauses,
                total_red_flags=total_red_flags,
                high_severity_flags=high_severity,
            ), timeout=60)
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail=f"Safety score timed out after {ANALYSIS_TIMEOUT}s.")
    except Exception as e:
        logger.error(f"Safety score error for {document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ─── Chat With Document (RAG) ──────────────────────────────────────────────────

@router.post("/chat-with-document", response_model=ChatWithDocumentResponse)
async def chat_with_document(request: ChatWithDocumentRequest):
    doc = document_service.get_document(request.document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{request.document_id}' not found")
    if not request.user_question.strip():
        raise HTTPException(status_code=400, detail="user_question cannot be empty")
    try:
        return await asyncio.wait_for(
            chat_service.chat_with_document(
                document_id=request.document_id,
                user_question=request.user_question,
                conversation_history=request.conversation_history,
            ), timeout=CHAT_TIMEOUT)
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail=f"Chat timed out after {CHAT_TIMEOUT}s.")
    except Exception as e:
        logger.error(f"Chat error for {request.document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))