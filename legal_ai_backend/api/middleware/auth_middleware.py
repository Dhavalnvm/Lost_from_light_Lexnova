"""
api/middleware/auth_middleware.py
----------------------------------
FastAPI dependency for extracting and validating JWT Bearer tokens.

Changes from original:
- WWW-Authenticate header added to all 401 responses (RFC 6750 compliant)
- Failed auth attempts are logged with reason so they appear in errors.log
- get_optional_user logs a debug line on token parse failure (helps debugging)
"""
from fastapi import Header, HTTPException, status
from fastapi.security.utils import get_authorization_scheme_param
from services.auth_service import auth_service
from utils.logging import app_logger as logger

# RFC 6750 — all 401 responses MUST include this header
_WWW_AUTH = {"WWW-Authenticate": "Bearer"}


async def get_current_user(authorization: str = Header(default="")) -> dict:
    """
    Required auth dependency.
    Extracts Bearer token, verifies signature + expiry, returns user dict.
    Raises HTTP 401 if token is missing, malformed, expired, or invalid.

    The returned user dict always contains:
      user_id, name, email, documents_count, created_at,
      company_id (may be ""), company_role (may be "")
    """
    scheme, token = get_authorization_scheme_param(authorization)

    if not authorization or scheme.lower() != "bearer":
        logger.warning(
            f"Auth rejected — missing or non-Bearer Authorization header "
            f"(scheme='{scheme or 'none'}')"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated. Provide: Authorization: Bearer <token>",
            headers=_WWW_AUTH,
        )

    if not token:
        logger.warning("Auth rejected — Bearer scheme present but token is empty")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token is empty.",
            headers=_WWW_AUTH,
        )

    user = await auth_service.get_current_user(token)

    if not user:
        logger.warning("Auth rejected — token invalid or expired (or DB down with no JWT fallback)")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token invalid or expired. Please log in again.",
            headers=_WWW_AUTH,
        )

    return user


async def get_optional_user(authorization: str = Header(default="")) -> dict | None:
    """
    Optional auth dependency.
    Returns a user dict if a valid Bearer token is supplied, otherwise None.
    Never raises 401 — routes decide how to handle anonymous access.
    """
    scheme, token = get_authorization_scheme_param(authorization)
    if scheme.lower() != "bearer" or not token:
        return None

    user = await auth_service.get_current_user(token)
    if not user:
        logger.debug("get_optional_user — token present but invalid/expired; treating as anonymous")
    return user