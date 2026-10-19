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


async def get_president_id_for_user(user, db: AsyncSession, school_id: int | None = None) -> int | None:
    """Resolve president_id for any authenticated user."""
    from app.models.admin import Admin
    if isinstance(user, Admin) or getattr(user, "role", None) in ("admin", "ADMIN") or hasattr(user, "is_admin"):
        if school_id:
            result = await db.execute(select(President).where(President.id == school_id))
            pres = result.scalar_one_or_none()
            if pres:
                return pres.id
        result = await db.execute(select(President).limit(1))
        pres = result.scalar_one_or_none()
        return pres.id if pres else 1

    role = (user.role.value if hasattr(user.role, "value") else str(user.role)).upper()
    
    if role == "PRESIDENT":
        result = await db.execute(select(President).where(President.user_id == user.id))
        pres = result.scalar_one_or_none()
        return pres.id if pres else None
    
    if role == "TEACHER":
        result = await db.execute(select(Teacher).where(Teacher.user_id == user.id))
        teacher = result.scalar_one_or_none()
        if teacher and teacher.president_id:
            return teacher.president_id
        result = await db.execute(select(President).limit(1))
        pres = result.scalar_one_or_none()
        return pres.id if pres else 1
    
    if role == "SUPERVISOR":
        result = await db.execute(select(Supervisor).where(Supervisor.user_id == user.id))
        sup = result.scalar_one_or_none()
        if sup and sup.president_id:
            return sup.president_id
        result = await db.execute(select(President).limit(1))
        pres = result.scalar_one_or_none()
        return pres.id if pres else 1
    
    if role in ("CHIEF_SUPERVISOR", "CHIEFSUPERVISOR"):
        from app.models.chief_supervisor import ChiefSupervisor
        result = await db.execute(select(ChiefSupervisor).where(ChiefSupervisor.user_id == user.id))
        cs = result.scalar_one_or_none()
        if cs and cs.president_id:
            return cs.president_id
        from app.models.supervisor import Supervisor
        result = await db.execute(select(Supervisor).where(Supervisor.user_id == user.id))
        sup = result.scalar_one_or_none()
        if sup and sup.president_id:
            return sup.president_id
        result = await db.execute(select(President).limit(1))
        pres = result.scalar_one_or_none()
        return pres.id if pres else 1
    
    result = await db.execute(select(President).limit(1))
    pres = result.scalar_one_or_none()
    return pres.id if pres else 1


async def authenticate_ws_token(token: str, db: AsyncSession):
    """Validate JWT token and return active User, Admin, or None."""
    if not token:
        return None
    
    payload = decode_token(token)
    if not payload:
        return None
    
    token_type = payload.get("type")
    admin_id = payload.get("admin_id")
    if token_type == "admin" or admin_id:
        from app.models.admin import Admin
        result = await db.execute(select(Admin).where(Admin.id == admin_id))
        admin = result.scalar_one_or_none()
        if admin:
            return admin
    
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


async def handle_websocket_connection(websocket: WebSocket, token: str, school_id: int | None = None):
    async with async_session_factory() as db:
        user = await authenticate_ws_token(token, db)
        if not user:
            await websocket.close(code=4001, reason="Unauthorized")
            return
        
        president_id = await get_president_id_for_user(user, db, school_id=school_id)
        if not president_id:
            await websocket.close(code=4003, reason="Organization not found")
            return
        
        await websocket.accept()
        _groups[president_id].add(websocket)
        
        from app.models.admin import Admin
        is_admin_user = isinstance(user, Admin) or getattr(user, "role", None) in ("admin", "ADMIN") or hasattr(user, "is_admin")
        
        if is_admin_user:
            sender_name = "الرئيس"
            result = await db.execute(select(President).where(President.id == president_id))
            pres = result.scalar_one_or_none()
            sender_id = pres.user_id if pres else user.id
        else:
            sender_name = f"{getattr(user, 'firstname', '')} {getattr(user, 'lastname', '')}".strip() or "مستخدم"
            sender_id = user.id

        logger.info(f"[WS] User '{sender_name}' (ID: {sender_id}) connected to group {president_id}")
        
        # Send welcome / connected event to client
        await websocket.send_text(json.dumps({
            "type": "connected",
            "user_id": sender_id,
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
                
                # ── Ping / Pong Keepalive ────────────────────────
                if event_type == "ping":
                    await websocket.send_text(json.dumps({"type": "pong"}))
                    continue
                
                # ── Typing Indicator ──────────────────────────────
                if event_type == "typing":
                    is_typing = bool(payload.get("is_typing", False))
                    await broadcast_to_group(president_id, {
                        "type": "typing",
                        "sender_id": sender_id,
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
                    
                    user_role_val = user.role.value if hasattr(user.role, 'value') else str(user.role)
                    is_president = user_role_val.upper() == 'PRESIDENT'
                    can_del = msg_to_del and (msg_to_del.sender_id == sender_id or is_admin_user or is_president)
                    if can_del:
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
                    if is_admin_user:
                        sender_role_raw = "president"
                    else:
                        u_role = user.role.value.lower() if hasattr(user.role, "value") else str(user.role).lower()
                        if u_role in ("chief_supervisor", "chiefsupervisor", "supervisor"):
                            sender_role_raw = "supervisor"
                        elif u_role in ("admin", "president"):
                            sender_role_raw = "president"
                        else:
                            sender_role_raw = "teacher"
                
                role_enum = SenderRole(sender_role_raw)
                
                new_msg = Message(
                    sender_id=sender_id,
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
    school_id: int | None = Query(None),
):
    await handle_websocket_connection(websocket, token, school_id=school_id)


@ws_router.websocket("/api/v1/messages/ws")
async def websocket_messages_v1(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token"),
    school_id: int | None = Query(None),
):
    await handle_websocket_connection(websocket, token, school_id=school_id)
