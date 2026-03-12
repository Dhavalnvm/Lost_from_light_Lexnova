"""
services/group_chat_service.py
-------------------------------
Group Discussion: real-time multi-user chat over a shared PDF.

Collections used:
  group_rooms    — room metadata (code, doc, members, is_active)
  group_messages — persisted chat messages per room
"""
import random
import string
import json
from datetime import datetime, timezone
from typing import Dict, List, Optional
from fastapi import WebSocket
from core.database import get_db
from core.task_router import get_client
from core.embeddings import embeddings_manager
from core.vector_store import vector_store
from utils.logging import app_logger as logger


# ─── In-Memory Connection Manager ─────────────────────────────────────────────

class RoomConnectionManager:
    """Tracks live WebSocket connections per room in memory."""

    def __init__(self):
        # room_code → list of {ws, user_id, display_name}
        self.rooms: Dict[str, List[dict]] = {}

    def _room(self, code: str) -> List[dict]:
        return self.rooms.setdefault(code, [])

    async def connect(self, code: str, ws: WebSocket,
                      user_id: str, display_name: str):
        await ws.accept()
        self._room(code).append(
            {"ws": ws, "user_id": user_id, "display_name": display_name}
        )
        logger.info(f"[GroupChat] {display_name} connected → room {code}")

    def disconnect(self, code: str, ws: WebSocket):
        self.rooms[code] = [m for m in self._room(code) if m["ws"] is not ws]
        logger.info(f"[GroupChat] A user disconnected from room {code}")

    def member_count(self, code: str) -> int:
        return len(self._room(code))

    def get_member(self, code: str, ws: WebSocket) -> dict:
        for m in self._room(code):
            if m["ws"] is ws:
                return m
        return {"user_id": "", "display_name": "Unknown"}

    async def broadcast(self, code: str, message: dict,
                        exclude: Optional[WebSocket] = None):
        """Send JSON to all (or all-except-one) connections in a room."""
        payload = json.dumps(message, default=str)
        dead = []
        for member in list(self._room(code)):
            if exclude and member["ws"] is exclude:
                continue
            try:
                await member["ws"].send_text(payload)
            except Exception:
                dead.append(member)
        for d in dead:
            try:
                self.rooms[code].remove(d)
            except ValueError:
                pass


manager = RoomConnectionManager()


# ─── Room helpers ──────────────────────────────────────────────────────────────

def _make_code(length: int = 6) -> str:
    return "".join(random.choices(string.ascii_uppercase + string.digits, k=length))


def _serialize(doc: dict) -> dict:
    """Convert MongoDB doc to JSON-safe dict (strip _id, stringify datetimes)."""
    doc.pop("_id", None)
    for k, v in doc.items():
        if isinstance(v, datetime):
            doc[k] = v.isoformat()
    if "members" in doc:
        for m in doc["members"]:
            if isinstance(m.get("joined_at"), datetime):
                m["joined_at"] = m["joined_at"].isoformat()
    return doc


async def create_room(document_id: str, document_name: str,
                      host_id: str, host_name: str) -> dict:
    db = get_db()
    for _ in range(10):
        code = _make_code()
        if not await db.group_rooms.find_one({"room_code": code, "is_active": True}):
            break

    now = datetime.now(timezone.utc)
    room = {
        "room_code": code,
        "document_id": document_id,
        "document_name": document_name,
        "host_id": host_id,
        "host_name": host_name,
        "members": [{"user_id": host_id, "display_name": host_name, "joined_at": now}],
        "created_at": now,
        "is_active": True,
        "message_count": 0,
    }
    await db.group_rooms.insert_one(room)
    logger.info(f"[GroupChat] Room {code} created by {host_name}")
    return _serialize(dict(room))


async def get_room(code: str) -> Optional[dict]:
    db = get_db()
    doc = await db.group_rooms.find_one({"room_code": code.upper(), "is_active": True})
    return _serialize(dict(doc)) if doc else None


async def join_room(code: str, user_id: str, display_name: str) -> Optional[dict]:
    db = get_db()
    room = await db.group_rooms.find_one({"room_code": code.upper(), "is_active": True})
    if not room:
        return None
    if not any(m["user_id"] == user_id for m in room.get("members", [])):
        await db.group_rooms.update_one(
            {"room_code": code.upper()},
            {"$push": {"members": {
                "user_id": user_id,
                "display_name": display_name,
                "joined_at": datetime.now(timezone.utc),
            }}}
        )
    return await get_room(code)


async def persist_message(code: str, sender_id: str, sender_name: str,
                           role: str, content: str):
    db = get_db()
    await db.group_messages.insert_one({
        "room_code": code,
        "sender_id": sender_id,
        "sender_name": sender_name,
        "role": role,      # "user" | "ai"
        "content": content,
        "timestamp": datetime.now(timezone.utc),
    })
    await db.group_rooms.update_one(
        {"room_code": code},
        {"$inc": {"message_count": 1}}
    )


async def get_room_history(code: str, limit: int = 50) -> List[dict]:
    db = get_db()
    cursor = db.group_messages.find(
        {"room_code": code}, {"_id": 0}
    ).sort("timestamp", 1).limit(limit)
    msgs = []
    async for doc in cursor:
        if isinstance(doc.get("timestamp"), datetime):
            doc["timestamp"] = doc["timestamp"].isoformat()
        msgs.append(doc)
    return msgs


# ─── RAG AI response ───────────────────────────────────────────────────────────

_GROUP_AI_SYSTEM = """You are Lex, a legal document assistant in a group discussion.
Two users are reviewing a document together. Answer ONLY from the document context.
Be concise and clear. Never give personal legal advice.
If the answer is not in the document, say so plainly."""


async def get_ai_response(document_id: str, question: str,
                           history: List[dict]) -> str:
    try:
        client = get_client("group_chat")
        embedding = await embeddings_manager.embed_query(question)
        chunks = vector_store.query_similar_chunks(
            query_embedding=embedding,
            document_id=document_id,
            n_results=4,
        )
        if not chunks:
            return "I couldn't find relevant content in this document to answer your question."

        context = "\n\n---\n\n".join(chunks)
        prompt = (
            f"DOCUMENT CONTEXT:\n{context}\n\n"
            f"QUESTION: {question}\n\n"
            "Answer clearly and concisely based only on the document above."
        )
        return await client.generate_with_history(
            user_message=prompt,
            conversation_history=history[-10:],
            system_prompt=_GROUP_AI_SYSTEM,
        )
    except Exception as e:
        logger.error(f"[GroupChat] AI error: {e}")
        return "I encountered an error processing your question. Please try again."