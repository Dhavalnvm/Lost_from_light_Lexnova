"""
api/routes/auth.py
------------------
Authentication endpoints: register, login, /me, document history.

Changes:
- UserProfile now includes company_id and company_role (populated by auth_service)
- /me returns company fields so the frontend knows if user has a workspace
- AuthResponse and UserProfile use model_config extra="ignore" so extra
  dict keys from auth_service never cause Pydantic validation errors
"""
from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel, ConfigDict
from typing import Optional

from services.auth_service import auth_service
from api.middleware.auth_middleware import get_current_user
from utils.logging import app_logger as logger

router = APIRouter(prefix="/api/v1/auth", tags=["Authentication"])


# ── Request / Response models ─────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


class AuthResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")   # ✅ ignore extra keys from auth_service

    user_id: str
    name: str
    email: str
    token: str
    message: str


class UserProfile(BaseModel):
    model_config = ConfigDict(extra="ignore")   # ✅ ignore extra keys from auth_service

    user_id: str
    name: str
    email: str
    documents_count: int
    created_at: str
    company_id: Optional[str] = ""              # ✅ NEW — enterprise workspace id
    company_role: Optional[str] = ""            # ✅ NEW — admin | analyst | viewer | ""


# ── Endpoints ─────────────────────────────────────────────────────────────────

@router.post("/register", response_model=AuthResponse)
async def register(body: RegisterRequest):
    try:
        result = await auth_service.register(body.name, body.email, body.password)
        return AuthResponse(**result, message="Account created successfully")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Register error: {e}")
        raise HTTPException(status_code=500, detail="Registration failed")


@router.post("/login", response_model=AuthResponse)
async def login(body: LoginRequest):
    try:
        result = await auth_service.login(body.email, body.password)
        return AuthResponse(**result, message="Login successful")
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))
    except Exception as e:
        logger.error(f"Login error: {e}")
        raise HTTPException(status_code=500, detail="Login failed")


@router.get("/me", response_model=UserProfile)
async def get_me(current_user: dict = Depends(get_current_user)):
    """
    Returns the authenticated user's profile.
    Includes company_id and company_role so the frontend can gate
    enterprise features without an extra round-trip.
    """
    return UserProfile(**current_user)


@router.get("/my-documents")
async def get_my_documents(current_user: dict = Depends(get_current_user)):
    """Retrieve all documents uploaded by the current user, newest first."""
    docs = await auth_service.get_user_documents(current_user["user_id"])
    return {"documents": docs, "count": len(docs)}