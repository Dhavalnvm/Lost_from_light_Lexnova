"""
api/routes/user_dashboard.py
-----------------------------
Personal user dashboard endpoint consumed by the UserDashboard frontend.

Routes
------
GET /api/user/dashboard  — per-user analytics: document history, risk summary,
                           AI usage, recent activity, and account overview.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends

from api.middleware.auth_middleware import get_current_user
from core.database import get_db
from utils.logging import app_logger as logger

router = APIRouter(prefix="/api/user", tags=["User Dashboard"])


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _isoformat(value) -> str:
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value) if value else ""


# ─── GET /api/user/dashboard ──────────────────────────────────────────────────

@router.get("/dashboard")
async def get_user_dashboard(current_user: dict = Depends(get_current_user)):
    """
    Return personalised analytics for the authenticated user.

    Data is drawn from MongoDB (documents collection + optional audit_log).
    All counts default to zero gracefully when collections are empty.
    """
    db = get_db()
    user_id = current_user["user_id"]
    now_utc = datetime.now(timezone.utc)

    # ── Document counts ───────────────────────────────────────────────────────
    total_docs = await db.documents.count_documents({"user_id": user_id})

    # Documents uploaded in the last 30 days
    recent_cutoff = now_utc - timedelta(days=30)
    recent_docs = await db.documents.count_documents({
        "user_id":     user_id,
        "uploaded_at": {"$gte": recent_cutoff},
    })

    # ── Risk aggregation ──────────────────────────────────────────────────────
    risk_pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {
            "_id":    None,
            "high":   {"$sum": {"$ifNull": ["$analysis.risk.high_count",   0]}},
            "medium": {"$sum": {"$ifNull": ["$analysis.risk.medium_count", 0]}},
            "low":    {"$sum": {"$ifNull": ["$analysis.risk.low_count",    0]}},
        }},
    ]
    risk_agg = await db.documents.aggregate(risk_pipeline).to_list(1)
    risk_row = risk_agg[0] if risk_agg else {"high": 0, "medium": 0, "low": 0}

    # ── Average safety score ──────────────────────────────────────────────────
    safety_pipeline = [
        {"$match": {"user_id": user_id, "analysis.safety_score": {"$exists": True}}},
        {"$group": {"_id": None, "avg": {"$avg": "$analysis.safety_score"}}},
    ]
    safety_agg = await db.documents.aggregate(safety_pipeline).to_list(1)
    avg_safety = round(safety_agg[0]["avg"], 1) if safety_agg else 0.0

    # ── Uploads over the last 7 days (trend chart) ────────────────────────────
    upload_trend = []
    for days_back in range(6, -1, -1):
        day_start = now_utc - timedelta(days=days_back + 1)
        day_end   = now_utc - timedelta(days=days_back)
        label = (now_utc - timedelta(days=days_back)).strftime("%-d %b")
        count = await db.documents.count_documents({
            "user_id":     user_id,
            "uploaded_at": {"$gte": day_start, "$lt": day_end},
        })
        upload_trend.append({"label": label, "value": count})

    # ── Document type breakdown ───────────────────────────────────────────────
    raw_docs = await db.documents.find(
        {"user_id": user_id}, {"doc_type": 1}
    ).to_list(500)

    type_counts: dict = {}
    for d in raw_docs:
        dtype = (d.get("doc_type") or "Other").strip() or "Other"
        type_counts[dtype] = type_counts.get(dtype, 0) + 1

    doc_type_breakdown = [
        {"label": k, "value": v}
        for k, v in sorted(type_counts.items(), key=lambda x: -x[1])
    ][:8]   # top 8 categories

    # ── Recent documents (last 5) ─────────────────────────────────────────────
    recent_cursor = db.documents.find(
        {"user_id": user_id},
        {"_id": 0, "document_id": 1, "filename": 1, "doc_type": 1, "uploaded_at": 1,
         "analysis.safety_score": 1},
    ).sort("uploaded_at", -1).limit(5)

    recent_documents = []
    async for doc in recent_cursor:
        recent_documents.append({
            "document_id":   doc.get("document_id", ""),
            "filename":      doc.get("filename", "Untitled"),
            "doc_type":      doc.get("doc_type", "Unknown"),
            "uploaded_at":   _isoformat(doc.get("uploaded_at")),
            "safety_score":  doc.get("analysis", {}).get("safety_score", 0),
        })

    # ── Recent activity from audit log (with graceful fallback) ──────────────
    collections = await db.list_collection_names()
    activity_items = []

    if "audit_log" in collections:
        cursor = db.audit_log.find(
            {"user_id": user_id}, {"_id": 0}
        ).sort("timestamp", -1).limit(10)
        async for item in cursor:
            activity_items.append({
                "user":      item.get("user", current_user.get("name", "You")),
                "resource":  item.get("resource", item.get("detail", "—")),
                "type":      str(item.get("type", "default")).lower(),
                "timestamp": _isoformat(item.get("timestamp")),
            })

    # Fall back to document uploads as activity events
    if len(activity_items) < 5:
        cursor = db.documents.find(
            {"user_id": user_id},
            {"filename": 1, "uploaded_at": 1},
        ).sort("uploaded_at", -1).limit(10 - len(activity_items))
        async for doc in cursor:
            activity_items.append({
                "user":      current_user.get("name", "You"),
                "resource":  doc.get("filename", "Document"),
                "type":      "upload",
                "timestamp": _isoformat(doc.get("uploaded_at")),
            })

    activity_items.sort(key=lambda x: x.get("timestamp", ""), reverse=True)

    # ── Compose and return ────────────────────────────────────────────────────
    return {
        "user": {
            "user_id":         user_id,
            "name":            current_user.get("name", ""),
            "email":           current_user.get("email", ""),
            "documents_count": current_user.get("documents_count", total_docs),
            "member_since":    current_user.get("created_at", ""),
        },
        "overview": {
            "totalDocuments":    total_docs,
            "recentDocuments":   recent_docs,
            "avgSafetyScore":    avg_safety,
            "riskyClauses":      risk_row.get("high", 0) + risk_row.get("medium", 0),
        },
        "riskSummary": {
            "high":   risk_row.get("high",   0),
            "medium": risk_row.get("medium", 0),
            "low":    risk_row.get("low",    0),
        },
        "uploadTrend":       upload_trend,
        "docTypeBreakdown":  doc_type_breakdown,
        "recentDocuments":   recent_documents,
        "recentActivity":    activity_items[:10],
    }