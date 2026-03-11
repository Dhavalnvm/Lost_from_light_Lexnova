"""
services/auth_service.py
------------------------
Handles user registration, login, JWT creation & verification.
"""
import re
from datetime import datetime, timedelta, timezone
from typing import Optional

from jose import JWTError, jwt
from passlib.context import CryptContext

from core.database import get_db
from config.settings import settings
from utils.logging import app_logger as logger

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ── Helpers ───────────────────────────────────────────────────────────────────

def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    payload = data.copy()
    expire = datetime.now(timezone.utc) + (
        expires_delta or timedelta(minutes=settings.JWT_EXPIRE_MINUTES)
    )
    payload.update({"exp": expire})
    return jwt.encode(payload, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)


def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        return None


def _validate_email(email: str) -> bool:
    return bool(re.match(r"[^@]+@[^@]+\.[^@]+", email))


# ── Service ───────────────────────────────────────────────────────────────────

class AuthService:

    async def register(self, name: str, email: str, password: str) -> dict:
        email = email.lower().strip()
        if not _validate_email(email):
            raise ValueError("Invalid email address")
        if len(password) < 6:
            raise ValueError("Password must be at least 6 characters")

        db = get_db()
        existing = await db.users.find_one({"email": email})
        if existing:
            raise ValueError("An account with this email already exists")

        user_doc = {
            "name": name.strip(),
            "email": email,
            "password_hash": hash_password(password),
            "created_at": datetime.now(timezone.utc),
            "documents_count": 0,
        }
        result = await db.users.insert_one(user_doc)
        user_id = str(result.inserted_id)
        logger.info(f"New user registered: {email} (id={user_id})")

        token = create_access_token({"sub": user_id, "email": email})
        return {
            "user_id": user_id,
            "name": name.strip(),
            "email": email,
            "token": token,
        }

    async def login(self, email: str, password: str) -> dict:
        email = email.lower().strip()
        db = get_db()
        user = await db.users.find_one({"email": email})
        if not user or not verify_password(password, user["password_hash"]):
            raise ValueError("Invalid email or password")

        user_id = str(user["_id"])
        token = create_access_token({"sub": user_id, "email": email})
        logger.info(f"User logged in: {email}")
        return {
            "user_id": user_id,
            "name": user["name"],
            "email": email,
            "token": token,
        }

    async def get_user_by_id(self, user_id: str) -> Optional[dict]:
        from bson import ObjectId
        db = get_db()
        try:
            user = await db.users.find_one({"_id": ObjectId(user_id)})
        except Exception:
            return None
        if not user:
            return None
        return {
            "user_id": str(user["_id"]),
            "name": user["name"],
            "email": user["email"],
            "documents_count": user.get("documents_count", 0),
            "created_at": user.get("created_at", "").isoformat() if user.get("created_at") else "",
        }

    async def get_current_user(self, token: str) -> Optional[dict]:
        payload = decode_token(token)
        if not payload:
            return None
        user_id = payload.get("sub")
        if not user_id:
            return None
        return await self.get_user_by_id(user_id)

    async def save_document_to_history(
        self,
        user_id: str,
        document_id: str,
        filename: str,
        doc_type: Optional[str],
        analysis_summary: dict,
    ) -> None:
        """Persist a document and its analysis results to MongoDB."""
        from bson import ObjectId
        db = get_db()
        doc = {
            "user_id": user_id,
            "document_id": document_id,
            "filename": filename,
            "doc_type": doc_type,
            "analysis": analysis_summary,
            "uploaded_at": datetime.now(timezone.utc),
        }
        await db.documents.replace_one(
            {"document_id": document_id}, doc, upsert=True
        )
        # Increment user doc count
        await db.users.update_one(
            {"_id": ObjectId(user_id)},
            {"$inc": {"documents_count": 1}},
        )

    async def get_user_documents(self, user_id: str) -> list:
        """Retrieve all documents for a user, newest first."""
        db = get_db()
        cursor = db.documents.find(
            {"user_id": user_id},
            {"_id": 0}
        ).sort("uploaded_at", -1).limit(50)
        docs = []
        async for d in cursor:
            if "uploaded_at" in d and hasattr(d["uploaded_at"], "isoformat"):
                d["uploaded_at"] = d["uploaded_at"].isoformat()
            docs.append(d)
        return docs


auth_service = AuthService()