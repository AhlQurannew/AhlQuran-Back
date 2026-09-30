"""
WebSocket endpoint and manager for real-time group chat.
Features:
  - Multi-tenancy: isolated room per president_id.
  - Auth: JWT token validated on handshake.
  - Bi-directional: send/receive messages, delete events, and typing indicators.
  - Inter-operable: broadcast function exported for REST API routes.
"""
import json
import logging
from collections import defaultdict
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.security import decode_token
from app.db.session import SessionLocal as async_session_factory
from app.models.message import Message, SenderRole
from app.models.user import User
from app.models.president import President
from app.models.teacher import Teacher
from app.models.supervisor import Supervisor

logger = logging.getLogger(__name__)

ws_router = APIRouter()

# Global connection registry: { president_id: set[WebSocket] }
_groups: dict[int, set[WebSocket]] = defaultdict(set)


async def get_president_id_for_user(user: User, db: AsyncSession) -> int | None:
    """Resolve president_id for any authenticated user."""
    role = user.role.value if hasattr(user.role, "value") else str(user.role)
    
    if role == "PRESIDENT":
        result = await db.execute(select(President).where(President.user_id == user.id))
        pres = result.scalar_one_or_none()
        return pres.id if pres else None
    
    if role == "TEACHER":
        result = await db.execute(select(Teacher).where(Teacher.user_id == user.id))
        teacher = result.scalar_one_or_none()
        return teacher.president_id if teacher else None
    
    if role == "SUPERVISOR":
        result = await db.execute(select(Supervisor).where(Supervisor.user_id == user.id))
        sup = result.scalar_one_or_none()
        return sup.president_id if sup else None
    
    return None


async def authenticate_ws_token(token: str, db: AsyncSession) -> User | None:
    """Validate JWT token and return active User or None."""
    if not token:
        return None
    
    payload = decode_token(token)
    if not payload:
        return None
    
    user_id = payload.get("user_id")
    if not user_id:
        return None
    
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    
    if not user or not user.is_active:
        return None
    
    return user


async def broadcast_to_group(president_id: int, data: dict) -> None:
    """Broadcast JSON payload to all active WebSockets in the president group."""
    if president_id not in _groups or not _groups[president_id]:
        return
    
    dead: set[WebSocket] = set()
    payload = json.dumps(data, ensure_ascii=False, default=str)
    
    for ws in list(_groups[president_id]):
        try:
            await ws.send_text(payload)
        except Exception:
            dead.add(ws)
    
    _groups[president_id] -= dead
    if not _groups[president_id]:
        del _groups[president_id]


async def handle_websocket_connection(websocket: WebSocket, token: str):
    async with async_session_factory() as db:
        user = await authenticate_ws_token(token, db)
        if not user:
            await websocket.close(code=4001, reason="Unauthorized")
            return
        
        president_id = await get_president_id_for_user(user, db)
        if not president_id:
            await websocket.close(code=4003, reason="Organization not found")
            return
        
        await websocket.accept()
        _groups[president_id].add(websocket)
        
        sender_name = f"{user.firstname} {user.lastname}"
        logger.info(f"[WS] User '{sender_name}' (ID: {user.id}) connected to group {president_id}")
        
        # Send welcome / connected event to client
        await websocket.send_text(json.dumps({
            "type": "connected",
            "user_id": user.id,
            "sender_name": sender_name,
            "president_id": president_id
        }))
        
        try:
            while True:
                raw = await websocket.receive_text()
                try:
                    payload = json.loads(raw)
                except json.JSONDecodeError:
                    await websocket.send_text(json.dumps({"type": "error", "detail": "Invalid JSON"}))
                    continue
                
                event_type = payload.get("type", "message")
                
                # ── Typing Indicator ──────────────────────────────
                if event_type == "typing":
                    is_typing = bool(payload.get("is_typing", False))
                    await broadcast_to_group(president_id, {
                        "type": "typing",
                        "sender_id": user.id,
                        "sender_name": sender_name,
                        "is_typing": is_typing
                    })
                    continue
                
                # ── Delete Message via WS ─────────────────────────
                if event_type == "delete":
                    msg_id = payload.get("message_id") or payload.get("id")
                    if not msg_id:
                        continue
                    
                    res = await db.execute(select(Message).where(Message.id == msg_id))
                    msg_to_del = res.scalar_one_or_none()
                    
                    if msg_to_del and msg_to_del.sender_id == user.id:
                        await db.delete(msg_to_del)
                        await db.commit()
                        await broadcast_to_group(president_id, {
                            "type": "delete",
                            "id": msg_id
                        })
                    continue
                
                # ── Chat Message ──────────────────────────────────
                msg_text = (payload.get("message") or "").strip()
                sender_role_raw = (payload.get("sender_role") or "").lower()
                
                if not msg_text:
                    continue
                
                allowed_roles = {"teacher", "supervisor", "president"}
                if sender_role_raw not in allowed_roles:
                    # Fallback role from user object
                    u_role = user.role.value.lower() if hasattr(user.role, "value") else str(user.role).lower()
                    sender_role_raw = u_role if u_role in allowed_roles else "teacher"
                
                role_enum = SenderRole(sender_role_raw)
                
                new_msg = Message(
                    sender_id=user.id,
                    sender_name=sender_name,
                    sender_role=role_enum,
                    message=msg_text,
                    president_id=president_id,
                )
                db.add(new_msg)
                await db.commit()
                await db.refresh(new_msg)
                
                broadcast_data = {
                    "type": "message",
                    "id": new_msg.id,
                    "sender_id": new_msg.sender_id,
                    "sender_name": new_msg.sender_name,
                    "sender_role": new_msg.sender_role.value,
                    "message": new_msg.message,
                    "created_at": new_msg.created_at.isoformat(),
                }
                await broadcast_to_group(president_id, broadcast_data)
                
                logger.info(f"[WS] Message {new_msg.id} from {sender_name} broadcast to group {president_id}")
        
        except WebSocketDisconnect:
            logger.info(f"[WS] User '{sender_name}' disconnected from group {president_id}")
        except Exception as e:
            logger.error(f"[WS] Error for {sender_name}: {e}")
        finally:
            _groups[president_id].discard(websocket)
            if president_id in _groups and not _groups[president_id]:
                del _groups[president_id]


@ws_router.websocket("/ws/messages")
async def websocket_messages_root(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token"),
):
    await handle_websocket_connection(websocket, token)


@ws_router.websocket("/api/v1/messages/ws")
async def websocket_messages_v1(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token"),
):
    await handle_websocket_connection(websocket, token)
