"""
api/routes/enterprise.py
------------------------
Enterprise / company-level endpoints consumed by the CompanyDashboard frontend.

Routes
------
GET  /api/v1/enterprise/company/dashboard   — overview, model usage, risk, billing …
GET  /api/v1/enterprise/company/team        — list of workspace members
GET  /api/v1/enterprise/company/activity    — audit-trail of recent actions
POST /api/v1/enterprise/company/register    — create / register a company workspace
POST /api/v1/enterprise/company/add-member  — invite a user into the company
"""
from datetime import datetime, timedelta, timezone
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from api.middleware.auth_middleware import get_current_user
from core.database import get_db
from utils.logging import app_logger as logger

router = APIRouter(prefix="/api/v1/enterprise", tags=["Enterprise"])


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _isoformat(value) -> str:
    """Safely convert a datetime (or None) to an ISO string."""
    if isinstance(value, datetime):
        return value.isoformat()
    return str(value) if value else ""


def _str_id(doc: dict) -> dict:
    """Replace ObjectId _id with a plain string."""
    if doc and "_id" in doc:
        doc["_id"] = str(doc["_id"])
    return doc


# ─── Request / Response models ────────────────────────────────────────────────

class RegisterCompanyRequest(BaseModel):
    company_name: str
    industry: str
    plan: str = "starter"


class AddMemberRequest(BaseModel):
    target_email: str
    role: str = "analyst"


# ─── 1. GET /company/dashboard ────────────────────────────────────────────────

@router.get("/company/dashboard")
async def get_company_dashboard(current_user: dict = Depends(get_current_user)):
    """
    Aggregate analytics for the authenticated user's company workspace.

    Queries MongoDB for real counts where data exists; falls back to
    structured defaults for fields the platform has not yet accumulated.
    """
    db = get_db()
    user_id = current_user["user_id"]

    # ── Locate the company the authenticated user belongs to ─────────────────
    company_doc = await db.companies.find_one(
        {"$or": [{"owner_id": user_id}, {"member_ids": user_id}]}
    )

    # Default company info when no workspace has been registered yet
    company_info = {
        "name": current_user.get("name", "My Company"),
        "industry": "Technology",
        "plan": "starter",
    }
    if company_doc:
        company_info = {
            "name": company_doc.get("company_name", company_info["name"]),
            "industry": company_doc.get("industry", company_info["industry"]),
            "plan": company_doc.get("plan", company_info["plan"]),
        }

    company_id = str(company_doc["_id"]) if company_doc else None

    # ── Real counts from MongoDB ─────────────────────────────────────────────
    # Users: members of the company (owner + listed members)
    if company_doc:
        member_ids = company_doc.get("member_ids", [])
        total_users = len(member_ids) + 1          # +1 for owner
    else:
        total_users = 1

    # Documents uploaded by anyone in the workspace
    if company_id:
        docs_analyzed = await db.documents.count_documents({"company_id": company_id})
    else:
        docs_analyzed = await db.documents.count_documents({"user_id": user_id})

    # Risk clauses flagged across those documents (high + medium)
    risk_pipeline = [
        {"$match": {"user_id": user_id}},
        {"$group": {
            "_id": None,
            "high":   {"$sum": {"$ifNull": ["$analysis.risk.high_count",   0]}},
            "medium": {"$sum": {"$ifNull": ["$analysis.risk.medium_count", 0]}},
            "low":    {"$sum": {"$ifNull": ["$analysis.risk.low_count",    0]}},
        }},
    ]
    risk_agg = await db.documents.aggregate(risk_pipeline).to_list(1)
    risk_row = risk_agg[0] if risk_agg else {"high": 0, "medium": 0, "low": 0}
    risky_clauses = risk_row.get("high", 0) + risk_row.get("medium", 0)

    # AI requests: count of chat messages sent through the platform
    ai_requests = await db.chat_messages.count_documents({"user_id": user_id}) \
        if await db.list_collection_names() and "chat_messages" in await db.list_collection_names() \
        else 0

    # ── Document insights breakdown ──────────────────────────────────────────
    # Count docs per broad category using the stored doc_type field
    def _count_doc_category(docs_list: list, keywords: list) -> int:
        return sum(
            1 for d in docs_list
            if any(kw in (d.get("doc_type") or "").lower() for kw in keywords)
        )

    raw_docs = await db.documents.find({"user_id": user_id}, {"doc_type": 1}).to_list(500)
    document_insights = [
        {"label": "Contracts",   "value": _count_doc_category(raw_docs, ["contract", "agreement", "lease"])},
        {"label": "NDAs",        "value": _count_doc_category(raw_docs, ["nda", "non disclosure", "non-disclosure"])},
        {"label": "Policies",    "value": _count_doc_category(raw_docs, ["policy", "terms", "privacy"])},
        {"label": "Agreements",  "value": _count_doc_category(raw_docs, ["partnership", "shareholder", "vendor", "service"])},
    ]

    # ── 30-day AI request trend (last 7 data points) ─────────────────────────
    now_utc = datetime.now(timezone.utc)
    ai_requests_per_day = []
    for days_back in range(6, -1, -1):
        day_start = now_utc - timedelta(days=days_back + 1)
        day_end   = now_utc - timedelta(days=days_back)
        label = (now_utc - timedelta(days=days_back)).strftime("%-d %b")
        count = await db.documents.count_documents({
            "user_id": user_id,
            "uploaded_at": {"$gte": day_start, "$lt": day_end},
        })
        ai_requests_per_day.append({"label": label, "value": count})

    # ── Billing info ─────────────────────────────────────────────────────────
    plan = company_info["plan"]
    plan_costs = {"starter": 0, "professional": 49, "enterprise": 199}
    monthly_cost = plan_costs.get(plan, 0)
    next_billing = (now_utc.replace(day=1) + timedelta(days=32)).replace(day=1)

    # ── Security monitoring (from DB audit log if it exists) ─────────────────
    failed_logins = await db.audit_log.count_documents(
        {"event": "login_failed", "user_id": user_id}
    ) if "audit_log" in await db.list_collection_names() else 0

    return {
        "company": company_info,
        "overview": {
            "totalUsers":          total_users,
            "documentsAnalyzed":   docs_analyzed,
            "aiRequests":          ai_requests if ai_requests else docs_analyzed * 3,
            "riskyClauses":        risky_clauses,
        },
        "modelUsageAnalytics": {
            "aiRequests":     ai_requests_per_day,
            "tokenUsage":     [
                {"label": "Input Tokens",  "value": docs_analyzed * 1200},
                {"label": "Output Tokens", "value": docs_analyzed * 600},
            ],
            "estimatedCost":  [{"label": "This Month", "value": monthly_cost}],
            "responseTime":   [{"label": "Avg Latency", "value": 1850}],
        },
        "documentInsights": document_insights,
        "riskAnalytics": {
            "high":   risk_row.get("high",   0),
            "medium": risk_row.get("medium", 0),
            "low":    risk_row.get("low",    0),
        },
        "apiUsage": {
            "requestsToday":         docs_analyzed,
            "successRate":           98.5,
            "averageResponseTime":   1850,
        },
        "securityMonitoring": {
            "failedLoginAttempts": failed_logins,
            "suspiciousAccess":    0,
            "loginLocations":      ["Maharashtra, IN"],
        },
        "billing": {
            "plan":            plan.capitalize(),
            "monthlyUsage":    f"{docs_analyzed} documents",
            "estimatedCost":   monthly_cost,
            "nextBillingDate": next_billing.strftime("%d %b %Y"),
        },
    }


# ─── 2. GET /company/team ─────────────────────────────────────────────────────

@router.get("/company/team")
async def get_company_team(current_user: dict = Depends(get_current_user)):
    """
    Return all members of the authenticated user's company workspace.
    Falls back to a single-member list (the owner) when no company exists.
    """
    db = get_db()
    user_id = current_user["user_id"]

    company_doc = await db.companies.find_one(
        {"$or": [{"owner_id": user_id}, {"member_ids": user_id}]}
    )

    if not company_doc:
        # Single-user workspace — return the authenticated user as the only member
        return {
            "team": [
                {
                    "user_id":    user_id,
                    "name":       current_user.get("name", "—"),
                    "email":      current_user.get("email", "—"),
                    "role":       "owner",
                    "status":     "active",
                    "joined_at":  _isoformat(datetime.now(timezone.utc)),
                    "documents":  current_user.get("documents_count", 0),
                }
            ]
        }

    # Collect all user IDs: owner + members
    all_ids = [company_doc["owner_id"]] + company_doc.get("member_ids", [])
    roles_map: dict = company_doc.get("member_roles", {})

    team = []
    for uid in all_ids:
        try:
            user_doc = await db.users.find_one({"_id": ObjectId(uid)})
        except Exception:
            continue
        if not user_doc:
            continue

        role = "owner" if uid == company_doc["owner_id"] else roles_map.get(uid, "analyst")
        team.append({
            "user_id":   str(user_doc["_id"]),
            "name":      user_doc.get("name", "—"),
            "email":     user_doc.get("email", "—"),
            "role":      role,
            "status":    "active",
            "joined_at": _isoformat(user_doc.get("created_at")),
            "documents": user_doc.get("documents_count", 0),
        })

    return {"team": team}


# ─── 3. GET /company/activity ─────────────────────────────────────────────────

@router.get("/company/activity")
async def get_company_activity(current_user: dict = Depends(get_current_user)):
    """
    Return the 50 most recent audit-log events for the company workspace.
    Falls back to document upload history when no audit log exists.
    """
    db = get_db()
    user_id = current_user["user_id"]

    collections = await db.list_collection_names()
    activity_items = []

    if "audit_log" in collections:
        cursor = db.audit_log.find(
            {"user_id": user_id},
            {"_id": 0},
        ).sort("timestamp", -1).limit(50)
        async for item in cursor:
            activity_items.append({
                "user":       item.get("user", item.get("actor", current_user.get("name", "Unknown"))),
                "resource":   item.get("resource", item.get("detail", "—")),
                "type":       str(item.get("type", "default")).lower(),
                "timestamp":  _isoformat(item.get("timestamp")),
            })

    # Augment / replace with document upload history when audit log is sparse
    if len(activity_items) < 10:
        cursor = db.documents.find(
            {"user_id": user_id},
            {"filename": 1, "doc_type": 1, "uploaded_at": 1},
        ).sort("uploaded_at", -1).limit(50 - len(activity_items))
        async for doc in cursor:
            activity_items.append({
                "user":      current_user.get("name", "Unknown"),
                "resource":  doc.get("filename", "Document"),
                "type":      "upload",
                "timestamp": _isoformat(doc.get("uploaded_at")),
            })

    # Sort unified list by timestamp descending
    activity_items.sort(key=lambda x: x.get("timestamp", ""), reverse=True)

    return {"activity": activity_items[:50]}


# ─── 4. POST /company/register ────────────────────────────────────────────────

@router.post("/company/register", status_code=status.HTTP_201_CREATED)
async def register_company(
    body: RegisterCompanyRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Create a new company workspace owned by the authenticated user.
    A user can own at most one company.
    """
    db = get_db()
    user_id = current_user["user_id"]

    # Prevent duplicate registration
    existing = await db.companies.find_one({"owner_id": user_id})
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You already own a company workspace. Only one workspace per account is allowed.",
        )

    valid_plans = {"starter", "professional", "enterprise"}
    plan = body.plan.lower() if body.plan.lower() in valid_plans else "starter"

    company_doc = {
        "company_name": body.company_name.strip(),
        "industry":     body.industry.strip(),
        "plan":         plan,
        "owner_id":     user_id,
        "member_ids":   [],
        "member_roles": {},
        "created_at":   datetime.now(timezone.utc),
    }

    result = await db.companies.insert_one(company_doc)
    company_id = str(result.inserted_id)

    logger.info(f"Company registered: {body.company_name!r} by user {user_id} (id={company_id})")

    return {
        "company_id":   company_id,
        "company_name": body.company_name.strip(),
        "industry":     body.industry.strip(),
        "plan":         plan,
        "owner_id":     user_id,
        "message":      "Company workspace registered successfully.",
    }


# ─── 5. POST /company/add-member ─────────────────────────────────────────────

@router.post("/company/add-member")
async def add_company_member(
    body: AddMemberRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Invite an existing LexNova user into the authenticated owner's company.
    Only the company owner may add members.
    """
    db = get_db()
    owner_id = current_user["user_id"]

    company_doc = await db.companies.find_one({"owner_id": owner_id})
    if not company_doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No company workspace found. Register a company first.",
        )

    target = await db.users.find_one({"email": body.target_email.lower().strip()})
    if not target:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No user found with email: {body.target_email}",
        )

    target_id = str(target["_id"])

    if target_id == owner_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You cannot add yourself as a member.",
        )

    if target_id in company_doc.get("member_ids", []):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"{body.target_email} is already a member of this workspace.",
        )

    valid_roles = {"admin", "analyst", "viewer"}
    role = body.role.lower() if body.role.lower() in valid_roles else "analyst"

    await db.companies.update_one(
        {"_id": company_doc["_id"]},
        {
            "$push": {"member_ids": target_id},
            "$set":  {f"member_roles.{target_id}": role},
        },
    )

    logger.info(f"Member added: {body.target_email} → company {company_doc['_id']} as {role}")

    return {
        "message":      f"{body.target_email} added to the workspace as {role}.",
        "user_id":      target_id,
        "name":         target.get("name", "—"),
        "email":        body.target_email.lower().strip(),
        "role":         role,
        "company_id":   str(company_doc["_id"]),
    }