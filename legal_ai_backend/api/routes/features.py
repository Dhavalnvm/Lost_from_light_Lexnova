"""
api/routes/features.py
-----------------------
Four new feature endpoints:
  A. Contract Safety Comparison    POST /compare-contracts
  B. Clause Rewriting Suggestions  GET  /clause-rewrites/{document_id}
  C. Smart Document Checklist      GET  /smart-checklist/{document_id}
  D. Version Diff                  POST /version-diff
"""
import asyncio
from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from typing import Optional

from services.document_service import document_service
from services.comparison_service import comparison_service
from services.rewrite_service import rewrite_service
from services.checklist_service import checklist_service
from services.version_diff_service import version_diff_service
from api.middleware.auth_middleware import get_optional_user
from utils.logging import app_logger as logger

router = APIRouter(prefix="/api/v1", tags=["Advanced Features"])

FEATURE_TIMEOUT = 200


# ── A: Contract Safety Comparison ─────────────────────────────────────────────

class CompareRequest(BaseModel):
    document_id_a: str
    document_id_b: str


@router.post("/compare-contracts")
async def compare_contracts(
    body: CompareRequest,
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Compare two uploaded documents side-by-side for safety."""
    doc_a = document_service.get_document(body.document_id_a)
    doc_b = document_service.get_document(body.document_id_b)

    if not doc_a:
        raise HTTPException(status_code=404, detail=f"Document A not found: {body.document_id_a}")
    if not doc_b:
        raise HTTPException(status_code=404, detail=f"Document B not found: {body.document_id_b}")

    try:
        result = await asyncio.wait_for(
            comparison_service.compare_contracts(
                doc_id_a=body.document_id_a,
                text_a=doc_a["full_text"],
                filename_a=doc_a["filename"],
                doc_id_b=body.document_id_b,
                text_b=doc_b["full_text"],
                filename_b=doc_b["filename"],
            ),
            timeout=FEATURE_TIMEOUT,
        )
        return result
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Contract comparison timed out")
    except Exception as e:
        logger.error(f"Comparison error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── B: Clause Rewriting Suggestions ───────────────────────────────────────────

@router.get("/clause-rewrites/{document_id}")
async def get_clause_rewrites(
    document_id: str,
    tone: str = Query(default="standard", description="firm | polite | standard"),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Get safer rewrites for all risky clauses in a document."""
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document not found: {document_id}")

    valid_tones = {"firm", "polite", "standard"}
    if tone not in valid_tones:
        tone = "standard"

    try:
        result = await asyncio.wait_for(
            rewrite_service.get_rewrite_suggestions(
                document_id=document_id,
                full_text=doc["full_text"],
                tone=tone,
            ),
            timeout=FEATURE_TIMEOUT,
        )
        return result
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Rewrite suggestions timed out")
    except Exception as e:
        logger.error(f"Rewrite error [{document_id}]: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── C: Smart Document Checklist ───────────────────────────────────────────────

@router.get("/smart-checklist/{document_id}")
async def get_smart_checklist(
    document_id: str,
    doc_type: str = Query(default="", description="rental | employment | loan | business | nda | general"),
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Generate a dynamic checklist of expected clauses for the document type."""
    doc = document_service.get_document(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail=f"Document not found: {document_id}")

    try:
        result = await asyncio.wait_for(
            checklist_service.generate_checklist(
                document_id=document_id,
                full_text=doc["full_text"],
                doc_type=doc_type,
            ),
            timeout=FEATURE_TIMEOUT,
        )
        return result
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Checklist generation timed out")
    except Exception as e:
        logger.error(f"Checklist error [{document_id}]: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ── D: Contract Version Comparison ────────────────────────────────────────────

class VersionDiffRequest(BaseModel):
    document_id_v1: str
    document_id_v2: str


@router.post("/version-diff")
async def compare_versions(
    body: VersionDiffRequest,
    current_user: Optional[dict] = Depends(get_optional_user),
):
    """Compare two versions of the same contract and highlight changes."""
    doc_v1 = document_service.get_document(body.document_id_v1)
    doc_v2 = document_service.get_document(body.document_id_v2)

    if not doc_v1:
        raise HTTPException(status_code=404, detail=f"Version 1 not found: {body.document_id_v1}")
    if not doc_v2:
        raise HTTPException(status_code=404, detail=f"Version 2 not found: {body.document_id_v2}")

    try:
        result = await asyncio.wait_for(
            version_diff_service.compare_versions(
                document_id_v1=body.document_id_v1,
                text_v1=doc_v1["full_text"],
                filename_v1=doc_v1["filename"],
                document_id_v2=body.document_id_v2,
                text_v2=doc_v2["full_text"],
                filename_v2=doc_v2["filename"],
            ),
            timeout=FEATURE_TIMEOUT,
        )
        return result
    except asyncio.TimeoutError:
        raise HTTPException(status_code=504, detail="Version diff timed out")
    except Exception as e:
        logger.error(f"Version diff error: {e}")
        raise HTTPException(status_code=500, detail=str(e))