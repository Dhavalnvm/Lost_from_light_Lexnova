"""
Document routes — includes parallel SSE streaming pipeline.

Analysis stream fires summary + risk + fairness concurrently via asyncio.gather,
yielding each result to the Flutter client as soon as it finishes.
"""

import asyncio
import json
from fastapi import APIRouter, UploadFile, File, HTTPException, Query
from fastapi.responses import StreamingResponse
from typing import AsyncGenerator

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
SUMMARY_TIMEOUT  = 240   # 8b model — give it more time
ANALYSIS_TIMEOUT = 200
CHAT_TIMEOUT     = 90


# ─── Helpers ───────────────────────────────────────────────────────────────────

def sse_event(event: str, data: dict) -> str:
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


# ─── Parallel Analysis Stream (SSE) ───────────────────────────────────────────

async def analysis_stream(document_id: str, mode: ExplanationMode) -> AsyncGenerator[str, None]:
    """
    Fires summary (8b), risk (8b), and fairness (8b) concurrently via asyncio.gather.
    Each result is streamed to the client as soon as it's ready.
    Safety score is computed instantly after (pure math, no LLM).

    Event types:
      status   → progress message
      summary  → DocumentSummaryResponse JSON
      risk     → RiskAnalysisResponse JSON
      fairness → ClauseFairnessResponse JSON
      safety   → SafetyScoreResponse JSON
      error    → { step, message }
      done     → { message }
    """
    doc = document_service.get_document(document_id)
    if not doc:
        yield sse_event("error", {"step": "init", "message": f"Document '{document_id}' not found"})
        return

    yield sse_event("status", {
        "step": "start",
        "message": "Launching parallel analysis on both models..."
    })

    # ── Fire all 3 heavy tasks simultaneously ─────────────────────────────────
    # All three use the smart 8b model. Since Ollama queues requests internally,
    # they overlap on GPU — the first to finish streams back immediately.

    async def run_summary():
        try:
            result = await asyncio.wait_for(
                document_service.get_summary(document_id, mode),
                timeout=SUMMARY_TIMEOUT,
            )
            return ("summary", result, None)
        except asyncio.TimeoutError:
            return ("summary", None, f"Summary timed out after {SUMMARY_TIMEOUT}s")
        except Exception as e:
            return ("summary", None, str(e))

    async def run_risk():
        try:
            result = await asyncio.wait_for(
                risk_service.analyze_risk(document_id, doc["full_text"]),
                timeout=ANALYSIS_TIMEOUT,
            )
            return ("risk", result, None)
        except asyncio.TimeoutError:
            return ("risk", None, f"Risk analysis timed out after {ANALYSIS_TIMEOUT}s")
        except Exception as e:
            return ("risk", None, str(e))

    async def run_fairness():
        try:
            result = await asyncio.wait_for(
                fairness_service.analyze_fairness(document_id, doc["full_text"]),
                timeout=ANALYSIS_TIMEOUT,
            )
            return ("fairness", result, None)
        except asyncio.TimeoutError:
            return ("fairness", None, f"Fairness timed out after {ANALYSIS_TIMEOUT}s")
        except Exception as e:
            return ("fairness", None, str(e))

    # Use a queue so we can yield results as each task completes
    result_queue: asyncio.Queue = asyncio.Queue()

    async def task_wrapper(coro):
        result = await coro
        await result_queue.put(result)

    # Launch all three concurrently
    tasks = [
        asyncio.create_task(task_wrapper(run_summary())),
        asyncio.create_task(task_wrapper(run_risk())),
        asyncio.create_task(task_wrapper(run_fairness())),
    ]

    risk_result     = None
    fairness_result = None
    completed       = 0
    total           = len(tasks)

    yield sse_event("status", {
        "step": "analyzing",
        "message": "Running summary, risk analysis, and clause fairness in parallel..."
    })

    # Stream each result as it arrives
    while completed < total:
        step, result, error = await result_queue.get()
        completed += 1

        if error:
            yield sse_event("error", {"step": step, "message": error})
            logger.error(f"[{document_id}] {step} failed: {error}")
        else:
            yield sse_event(step, result.dict())
            logger.info(f"[{document_id}] {step} ✅ ({completed}/{total})")

            if step == "risk":
                risk_result = result
            elif step == "fairness":
                fairness_result = result

    # ── Safety Score (instant — pure math) ────────────────────────────────────
    if risk_result and fairness_result:
        try:
            total_red_flags = len(risk_result.detected_red_flags)
            high_severity   = sum(1 for f in risk_result.detected_red_flags if f.severity == "high")
            unfair_clauses  = sum(
                1 for c in fairness_result.clauses_analyzed
                if "unfair" in c.fairness_rating.lower()
            )
            safety = await chat_service.calculate_safety_score(
                document_id=document_id,
                risk_score=risk_result.risk_score,
                fairness_issues=unfair_clauses,
                total_red_flags=total_red_flags,
                high_severity_flags=high_severity,
            )
            yield sse_event("safety", safety.dict())
            logger.info(f"[{document_id}] safety ✅")
        except Exception as e:
            yield sse_event("error", {"step": "safety", "message": str(e)})
    else:
        yield sse_event("error", {
            "step": "safety",
            "message": "Skipped — risk or fairness data unavailable",
        })

    yield sse_event("done", {"message": "Analysis complete"})


@router.get(
    "/analyze-stream/{document_id}",
    summary="Stream parallel analysis results (SSE)",
    description=(
        "Returns a text/event-stream. Fires summary, risk, and fairness concurrently "
        "on the 8b model. Each result is pushed as soon as it finishes — "
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
            "X-Accel-Buffering": "no",
            "Connection": "keep-alive",
        },
    )


# ─── Individual endpoints (for direct access) ──────────────────────────────────

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
        logger.error(f"Summary error: {e}")
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
        logger.error(f"Risk error: {e}")
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
        logger.error(f"Fairness error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/safety-score/{document_id}", response_model=SafetyScoreResponse)
async def get_safety_score(document_id: str):
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document '{document_id}' not found")
    try:
        risk_result, fairness_result = await asyncio.gather(
            asyncio.wait_for(
                risk_service.analyze_risk(document_id, doc["full_text"]),
                timeout=ANALYSIS_TIMEOUT),
            asyncio.wait_for(
                fairness_service.analyze_fairness(document_id, doc["full_text"]),
                timeout=ANALYSIS_TIMEOUT),
        )
        total_red_flags = len(risk_result.detected_red_flags)
        high_severity   = sum(1 for f in risk_result.detected_red_flags if f.severity == "high")
        unfair_clauses  = sum(
            1 for c in fairness_result.clauses_analyzed
            if "unfair" in c.fairness_rating.lower())
        return await chat_service.calculate_safety_score(
            document_id=document_id,
            risk_score=risk_result.risk_score,
            fairness_issues=unfair_clauses,
            total_red_flags=total_red_flags,
            high_severity_flags=high_severity,
        )
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Safety score timed out.")
    except Exception as e:
        logger.error(f"Safety score error: {e}")
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
        logger.error(f"Chat error: {e}")
        raise HTTPException(status_code=500, detail=str(e))