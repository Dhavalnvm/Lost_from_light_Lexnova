"""
api/routes/group_chat.py
-------------------------
REST + WebSocket endpoints for Group Discussion.

REST  (all require Bearer token):
  POST /api/v1/group-chat/create           → create room
  POST /api/v1/group-chat/join             → join room by code
  GET  /api/v1/group-chat/{code}           → get room info
  GET  /api/v1/group-chat/{code}/history   → message history

WebSocket (no auth header on WS — user_id passed as query param):
  WS /api/v1/group-chat/ws/{room_code}?user_id=<id>&display_name=<n>

WebSocket message protocol:
  ── Client → Server ──
  { "type": "message",  "text": "..." }     regular message
  { "type": "ai_query", "text": "..." }     ask Lex about the document
  { "type": "typing" }                      typing indicator

  ── Server → Client ──
  { "type": "history",     "messages": [...] }          on connect
  { "type": "message",     "role": "user"|"partner",
    "sender_name": "...", "sender_id": "...",
    "text": "...", "timestamp": "..." }
  { "type": "ai_thinking", "triggered_by": "..." }
  { "type": "ai_response", "text": "...",
    "triggered_by": "...", "question": "...",
    "timestamp": "..." }
  { "type": "system",      "text": "...", "timestamp": "..." }
  { "type": "typing",      "sender_name": "..." }
  { "type": "error",       "text": "..." }
"""
from datetime import datetime, timezone
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, HTTPException, Depends
from pydantic import BaseModel
import json

from services.group_chat_service import (
    manager, create_room, get_room, join_room,
    persist_message, get_room_history, get_ai_response,
)
# ✅ Correct import — same pattern used by auth.py, features.py, documents.py
from api.middleware.auth_middleware import get_current_user
from utils.logging import app_logger as logger

router = APIRouter(prefix="/api/v1/group-chat", tags=["Group Discussion"])


# ─── Schemas ──────────────────────────────────────────────────────────────────

class CreateRoomRequest(BaseModel):
    document_id: str
    document_name: str


class JoinRoomRequest(BaseModel):
    room_code: str


# ─── REST endpoints ───────────────────────────────────────────────────────────

@router.post("/create")
async def create_group_room(
    body: CreateRoomRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user.get("user_id") or current_user.get("_id", ""))
    name = (
        current_user.get("full_name")
        or current_user.get("name")
        or current_user.get("email", "User")
    )
    room = await create_room(body.document_id, body.document_name, user_id, name)
    return {
        "room_code": room["room_code"],
        "document_id": room["document_id"],
        "document_name": room["document_name"],
        "host_name": name,
    }


@router.post("/join")
async def join_group_room(
    body: JoinRoomRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user.get("user_id") or current_user.get("_id", ""))
    name = (
        current_user.get("full_name")
        or current_user.get("name")
        or current_user.get("email", "User")
    )
    room = await join_room(body.room_code, user_id, name)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found or no longer active")
    return room


@router.get("/{room_code}")
async def get_group_room(
    room_code: str,
    current_user: dict = Depends(get_current_user),
):
    room = await get_room(room_code)
    if not room:
        raise HTTPException(status_code=404, detail="Room not found")
    room["online_count"] = manager.member_count(room_code.upper())
    return room


@router.get("/{room_code}/history")
async def room_history(
    room_code: str,
    current_user: dict = Depends(get_current_user),
):
    messages = await get_room_history(room_code.upper())
    return {"room_code": room_code.upper(), "messages": messages}


# ─── WebSocket endpoint ───────────────────────────────────────────────────────

@router.websocket("/ws/{room_code}")
async def group_chat_ws(
    websocket: WebSocket,
    room_code: str,
    user_id: str = "",
    display_name: str = "User",
):
    code = room_code.upper()
    room = await get_room(code)
    if not room:
        await websocket.close(code=4004, reason="Room not found")
        return

    document_id = room["document_id"]

    await manager.connect(code, websocket, user_id, display_name)

    # Send full history on join
    history = await get_room_history(code, limit=50)
    await websocket.send_text(json.dumps({"type": "history", "messages": history}))

    # Notify others
    await manager.broadcast(code, {
        "type": "system",
        "text": f"{display_name} joined the discussion",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }, exclude=websocket)

    # Build AI conversation context from history
    ai_history = [
        {
            "role": "user" if m["role"] == "user" else "assistant",
            "content": m["content"],
        }
        for m in history[-20:]
    ]

    try:
        while True:
            raw = await websocket.receive_text()
            try:
                data = json.loads(raw)
            except json.JSONDecodeError:
                await websocket.send_text(json.dumps(
                    {"type": "error", "text": "Invalid JSON"}))
                continue

            msg_type = data.get("type", "")
            text = data.get("text", "").strip()
            now = datetime.now(timezone.utc).isoformat()

            # ── Regular chat message ───────────────────────────────────────────
            if msg_type == "message" and text:
                await websocket.send_text(json.dumps({
                    "type": "message", "role": "user",
                    "sender_id": user_id, "sender_name": display_name,
                    "text": text, "timestamp": now,
                }))
                await manager.broadcast(code, {
                    "type": "message", "role": "partner",
                    "sender_id": user_id, "sender_name": display_name,
                    "text": text, "timestamp": now,
                }, exclude=websocket)
                await persist_message(code, user_id, display_name, "user", text)
                ai_history.append({"role": "user", "content": f"{display_name}: {text}"})

            # ── AI query ──────────────────────────────────────────────────────
            elif msg_type == "ai_query" and text:
                thinking_msg = {
                    "type": "ai_thinking",
                    "triggered_by": display_name,
                    "timestamp": now,
                }
                await websocket.send_text(json.dumps(thinking_msg))
                await manager.broadcast(code, thinking_msg, exclude=websocket)

                ai_response = await get_ai_response(document_id, text, ai_history)

                ai_msg = {
                    "type": "ai_response",
                    "text": ai_response,
                    "triggered_by": display_name,
                    "question": text,
                    "timestamp": datetime.now(timezone.utc).isoformat(),
                }
                await websocket.send_text(json.dumps(ai_msg))
                await manager.broadcast(code, ai_msg, exclude=websocket)

                await persist_message(code, "lex_ai", "Lex", "ai", ai_response)
                ai_history.append({"role": "assistant", "content": ai_response})

            # ── Typing indicator ──────────────────────────────────────────────
            elif msg_type == "typing":
                await manager.broadcast(code, {
                    "type": "typing",
                    "sender_name": display_name,
                    "timestamp": now,
                }, exclude=websocket)

    except WebSocketDisconnect:
        manager.disconnect(code, websocket)
        await manager.broadcast(code, {
            "type": "system",
            "text": f"{display_name} left the discussion",
            "timestamp": datetime.now(timezone.utc).isoformat(),
        })
        logger.info(f"[GroupChat] {display_name} disconnected from {code}")
    except Exception as e:
        logger.error(f"[GroupChat] WS error for {display_name} in {code}: {e}")
        manager.disconnect(code, websocket)