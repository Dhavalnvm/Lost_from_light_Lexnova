"""
api/middleware/auth_middleware.py
----------------------------------
FastAPI dependency for extracting and validating JWT Bearer tokens.
"""
from fastapi import Header, HTTPException, status
from services.auth_service import auth_service


async def get_current_user(authorization: str = Header(default="")):
    """
    Dependency: extracts Bearer token from Authorization header.
    Raises 401 if missing or invalid.
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated. Provide Authorization: Bearer <token>",
        )
    token = authorization[7:]
    user = await auth_service.get_current_user(token)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalid or expired",
        )
    return user


async def get_optional_user(authorization: str = Header(default="")):
    """
    Optional auth: returns user dict if token is valid, else None.
    Does not raise 401 — routes can handle anonymous usage.
    """
    if not authorization.startswith("Bearer "):
        return None
    token = authorization[7:]
    return await auth_service.get_current_user(token)