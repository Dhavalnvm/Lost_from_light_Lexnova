"""
core/database.py
----------------
Async MongoDB connection via Motor.
Call connect_db() on startup, close_db() on shutdown.
Use get_db() anywhere to get the active database handle.
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
    # Ping to verify connection
    await _client.admin.command("ping")
    logger.info(f"✅ MongoDB connected  →  db={settings.MONGODB_DB_NAME}")

    # Create indexes
    await _db.users.create_index("email", unique=True)
    await _db.documents.create_index("user_id")
    await _db.documents.create_index("document_id", unique=True)
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