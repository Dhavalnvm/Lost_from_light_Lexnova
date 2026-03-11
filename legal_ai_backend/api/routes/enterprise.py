"""
api/routes/enterprise.py
-------------------------
Enterprise / B2B multi-tenant endpoints.

All company-scoped routes require a valid JWT. The authenticated user
must have a `company_id` on their user record (set at registration).

Endpoints:
  POST /api/v1/enterprise/company/register    → create company workspace
  POST /api/v1/enterprise/company/add-member  → add user to company
  GET  /api/v1/enterprise/company/dashboard   → CompanyDashboard data
  GET  /api/v1/enterprise/company/team        → TeamTable data
  GET  /api/v1/enterprise/company/activity    → ActivityLog data
  GET  /api/v1/enterprise/company/info        → basic company info
"""
from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import Optional
from bson import ObjectId

from services.enterprise_service import enterprise_service
from api.middleware.auth_middleware import get_current_user
from core.database import get_db
from utils.logging import app_logger as logger

router = APIRouter(prefix="/api/v1/enterprise", tags=["Enterprise"])


# ─── Schemas ──────────────────────────────────────────────────────────────────

class RegisterCompanyRequest(BaseModel):
    company_name: str
    industry: str
    plan: str = "starter"   # starter | professional | enterprise


class AddMemberRequest(BaseModel):
    target_email: str
    role: str = "analyst"   # admin | analyst | viewer


# ─── Helpers ──────────────────────────────────────────────────────────────────

async def _require_company(current_user: dict) -> str:
    """
    Ensure the authenticated user belongs to a company.
    Returns company_id or raises 403.

    Priority:
      1. company_id already in user dict (from auth_service DB fetch or JWT fallback)
      2. Fresh DB lookup (handles legacy users registered before company_id was
         embedded in the token / user dict)
    """
    # ✅ Fast path — auth_service already populated this
    company_id = current_user.get("company_id", "")
    if company_id:
        return company_id

    # Fallback: re-query DB (covers users who registered before this fix)
    db = get_db()
    try:
        user = await db.users.find_one({"_id": ObjectId(current_user["user_id"])})
        company_id = user.get("company_id", "") if user else ""
    except Exception as e:
        logger.warning(f"_require_company DB fallback failed: {e}")
        company_id = ""

    if not company_id:
        raise HTTPException(
            status_code=403,
            detail=(
                "No company workspace found. "
                "Register a company first via POST /api/v1/enterprise/company/register"
            ),
        )
    return company_id


# ─── Company Registration ──────────────────────────────────────────────────────

@router.post("/company/register", summary="Register a new company workspace")
async def register_company(
    body: RegisterCompanyRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Creates a new company workspace for the authenticated user.
    The calling user becomes the company admin.
    """
    try:
        result = await enterprise_service.register_company(
            owner_user_id=current_user["user_id"],
            company_name=body.company_name,
            industry=body.industry,
            plan=body.plan,
        )
        await enterprise_service.log_activity(
            company_id=result["company_id"],
            user_id=current_user["user_id"],
            user_name=current_user.get("name", "Admin"),
            action="Company workspace registered",
            resource=body.company_name,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Company registration error: {e}")
        raise HTTPException(status_code=500, detail="Failed to register company")


# ─── Add Member ────────────────────────────────────────────────────────────────

@router.post("/company/add-member", summary="Add a user to the company workspace")
async def add_member(
    body: AddMemberRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Adds an existing LexNova user (by email) to the calling user's company.
    Requires the caller to be a company admin.
    """
    company_id = await _require_company(current_user)
    db = get_db()

    # Verify caller is admin
    membership = await db.company_members.find_one({
        "company_id": company_id, "user_id": current_user["user_id"]})
    if not membership or membership.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only company admins can add members")

    # Find target user by email
    target = await db.users.find_one({"email": body.target_email.lower().strip()})
    if not target:
        raise HTTPException(
            status_code=404,
            detail=f"No LexNova account found for {body.target_email}",
        )

    try:
        result = await enterprise_service.add_member(
            company_id=company_id,
            target_user_id=str(target["_id"]),
            role=body.role,
        )
        await enterprise_service.log_activity(
            company_id=company_id,
            user_id=current_user["user_id"],
            user_name=current_user.get("name", "Admin"),
            action=f"Added member ({body.role})",
            resource=body.target_email,
        )
        return result
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Add member error: {e}")
        raise HTTPException(status_code=500, detail="Failed to add member")


# ─── Company Info ──────────────────────────────────────────────────────────────

@router.get("/company/info", summary="Basic company info")
async def get_company_info(current_user: dict = Depends(get_current_user)):
    company_id = await _require_company(current_user)
    db = get_db()
    company = await db.companies.find_one({"_id": ObjectId(company_id)})
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")
    return {
        "company_id": company_id,
        "name": company["name"],
        "industry": company.get("industry", ""),
        "plan": company.get("plan", "starter"),
        "created_at": company.get("created_at", "").isoformat()
        if hasattr(company.get("created_at"), "isoformat") else "",
    }


# ─── Dashboard ────────────────────────────────────────────────────────────────

@router.get("/company/dashboard", summary="Full company analytics dashboard")
async def get_company_dashboard(current_user: dict = Depends(get_current_user)):
    """
    Returns everything CompanyDashboard needs:
      company, overview, modelUsageAnalytics, documentInsights,
      riskAnalytics, apiUsage, securityMonitoring, billing
    """
    company_id = await _require_company(current_user)
    try:
        data = await enterprise_service.get_dashboard(company_id)
        return data
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        logger.error(f"Dashboard error for company {company_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to load dashboard")


# ─── Team ─────────────────────────────────────────────────────────────────────

@router.get("/company/team", summary="Company team members")
async def get_company_team(current_user: dict = Depends(get_current_user)):
    company_id = await _require_company(current_user)
    try:
        return await enterprise_service.get_team(company_id)
    except Exception as e:
        logger.error(f"Team error for company {company_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to load team data")


# ─── Activity Log ──────────────────────────────────────────────────────────────

@router.get("/company/activity", summary="Company audit activity log")
async def get_company_activity(
    limit: int = 30,
    current_user: dict = Depends(get_current_user),
):
    company_id = await _require_company(current_user)
    try:
        return await enterprise_service.get_activity(company_id, limit=limit)
    except Exception as e:
        logger.error(f"Activity error for company {company_id}: {e}")
        raise HTTPException(status_code=500, detail="Failed to load activity log")