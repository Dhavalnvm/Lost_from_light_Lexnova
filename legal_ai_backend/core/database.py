"""
core/database.py
-----------------
Async MongoDB connection via Motor.
"""
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from utils.logging import app_logger as logger
from config.settings import settings

_client: AsyncIOMotorClient | None = None
_db: AsyncIOMotorDatabase | None = None


async def connect_db() -> None:
    global _client, _db
    logger.info("🔌 Connecting to MongoDB...")
    _client = AsyncIOMotorClient(settings.MONGODB_URI)
    _db = _client[settings.MONGODB_DB_NAME]
    await _client.admin.command("ping")
    logger.info(f"✅ MongoDB connected  →  db={settings.MONGODB_DB_NAME}")

    # ── Core indexes ──────────────────────────────────────────────────────────
    await _db.users.create_index("email", unique=True)
    await _db.documents.create_index("user_id")
    await _db.documents.create_index("document_id", unique=True)

    # ── Group Discussion indexes ───────────────────────────────────────────────
    await _db.group_rooms.create_index([("room_code", 1), ("is_active", 1)])
    await _db.group_messages.create_index([("room_code", 1), ("timestamp", 1)])

    # ── Enterprise indexes ─────────────────────────────────────────────────────
    await _db.companies.create_index("owner_user_id", unique=True)
    await _db.company_members.create_index([("company_id", 1), ("user_id", 1)], unique=True)
    await _db.company_activity.create_index([("company_id", 1), ("timestamp", -1)])
    await _db.company_api_calls.create_index([("company_id", 1), ("timestamp", -1)])
    await _db.company_login_log.create_index([("company_id", 1), ("timestamp", -1)])
    # TTL: auto-delete detailed API call logs after 90 days (keeps DB lean)
    await _db.company_api_calls.create_index(
        "timestamp", expireAfterSeconds=90 * 24 * 3600)

    logger.info("✅ MongoDB indexes ensured")


async def close_db() -> None:
    global _client
    if _client:
        _client.close()
        logger.info("🛑 MongoDB connection closed")


def get_db() -> AsyncIOMotorDatabase:
    if _db is None:
        raise RuntimeError("Database not connected. Call connect_db() first.")
    return _db