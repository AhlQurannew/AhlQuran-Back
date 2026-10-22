"""Authenticated, school-scoped WebSocket group chat."""

import json
import logging
from collections import defaultdict

from fastapi import APIRouter, HTTPException, Query, WebSocket, WebSocketDisconnect
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.multi_tenancy import get_president_id_for_user as resolve_president_id
from app.core.security import decode_token
from app.db.session import SessionLocal as async_session_factory
from app.models.admin import Admin
from app.models.message import Message, MessageAttachment, SenderRole
from app.models.user import User
from app.services.message_attachments import (
    cleanup_orphaned_message_attachments,
    remove_message_attachment,
)

logger = logging.getLogger(__name__)
ws_router = APIRouter()
_groups: dict[int, set[WebSocket]] = defaultdict(set)


async def get_president_id_for_user(user, db: AsyncSession, school_id: int | None = None) -> int | None:
    try:
        return await resolve_president_id(user, db, school_id=school_id)
    except HTTPException:
        return None


async def authenticate_ws_token(token: str, db: AsyncSession) -> User | Admin | None:
    """Validate the access token and reload its actual account (never trust token role for chat role)."""
    payload = decode_token(token) if token else None
    if not payload or payload.get("type") != "access":
        return None

    if payload.get("role") == "admin":
        admin_id = payload.get("admin_id")
        if admin_id is None:
            return None
        result = await db.execute(select(Admin).where(Admin.id == admin_id))
        admin = result.scalar_one_or_none()
        if admin is None or payload.get("ver", 0) != admin.auth_version:
            return None
        return admin

    user_id = payload.get("user_id")
    if user_id is None:
        return None
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user is None or not user.is_active or payload.get("ver", 0) != user.auth_version:
        return None
    return user


def _sender_name(account) -> str:
    if isinstance(account, Admin):
        return account.user
    return f"{account.firstname} {account.lastname}".strip()


def _sender_role(account) -> SenderRole | None:
    if isinstance(account, Admin):
        return SenderRole.ADMIN
    role = getattr(account.role, "value", account.role)

    try:
        return SenderRole(str(role).lower())
    except ValueError:
        return None


def _attachment_metadata(attachment: MessageAttachment) -> dict:
    from app.core.config import settings

    return {
        "id": attachment.id,
        "filename": attachment.filename,
        "content_type": attachment.content_type,
        "size": attachment.size,
        "url": f"{settings.API_V1_PREFIX}/messages/attachments/{attachment.id}",
    }


async def broadcast_to_group(president_id: int, data: dict) -> None:
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
        account = await authenticate_ws_token(token, db)
        if account is None:
            await websocket.close(code=4001, reason="Unauthorized")
            return

        president_id = await get_president_id_for_user(account, db, school_id)
        if president_id is None:
            await websocket.close(code=4003, reason="Authorized school context required")
            return

        await websocket.accept()
        _groups[president_id].add(websocket)
        sender_name = _sender_name(account)
        is_admin = isinstance(account, Admin)
        sender_id = None if is_admin else account.id
        logger.info("WebSocket connected account_id=%s school_id=%s", account.id, president_id)

        try:
            await websocket.send_text(json.dumps({
                "type": "connected",
                "user_id": sender_id,
                "admin_id": account.id if is_admin else None,
                "sender_name": sender_name,
                "president_id": president_id,
            }))
            while True:
                raw = await websocket.receive_text()
                try:
                    payload = json.loads(raw)
                except json.JSONDecodeError:
                    await websocket.send_text(json.dumps({"type": "error", "detail": "Invalid JSON"}))
                    continue

                event_type = payload.get("type", "message")
                if event_type == "typing":
                    await broadcast_to_group(president_id, {
                        "type": "typing",
                        "sender_id": sender_id,
                        "admin_sender_id": account.id if is_admin else None,
                        "sender_name": sender_name,
                        "is_typing": bool(payload.get("is_typing", False)),
                    })
                    continue

                if event_type == "delete":
                    msg_id = payload.get("message_id") or payload.get("id")
                    if not isinstance(msg_id, int):
                        continue
                    result = await db.execute(
                        select(Message)
                        .options(selectinload(Message.attachments))
                        .where(Message.id == msg_id, Message.president_id == president_id)
                    )
                    message = result.scalar_one_or_none()
                    if message is None:
                        continue
                    owns_message = (
                        message.admin_sender_id == account.id if is_admin else message.sender_id == account.id
                    )
                    if owns_message:
                        attachment_paths = [item.storage_path for item in message.attachments]
                        await db.delete(message)
                        await db.commit()
                        for storage_path in attachment_paths:
                            remove_message_attachment(storage_path)
                        try:
                            await cleanup_orphaned_message_attachments(db, president_id)
                        except Exception:
                            logger.warning("Could not clean old orphaned message files", exc_info=True)
                        await broadcast_to_group(president_id, {"type": "delete", "id": msg_id})
                    continue

                text = (payload.get("message") or "").strip()
                if not text:
                    continue
                role = _sender_role(account)
                if role is None:
                    await websocket.send_text(json.dumps({"type": "error", "detail": "This account cannot send messages"}))
                    continue

                new_message = Message(
                    sender_id=None if is_admin else account.id,
                    admin_sender_id=account.id if is_admin else None,
                    sender_name=sender_name,
                    sender_role=role,
                    message=text,
                    president_id=president_id,
                    attachments=[],
                )
                db.add(new_message)
                await db.commit()
                await db.refresh(new_message)
                await broadcast_to_group(president_id, {
                    "type": "message",
                    "id": new_message.id,
                    "sender_id": new_message.sender_id,
                    "admin_sender_id": new_message.admin_sender_id,
                    "sender_name": new_message.sender_name,
                    "sender_role": new_message.sender_role.value,
                    "message": new_message.message,
                    "created_at": new_message.created_at.isoformat(),
                    "attachments": [],
                })
                logger.info("WebSocket message_id=%s school_id=%s", new_message.id, president_id)

        except WebSocketDisconnect:
            logger.info("WebSocket disconnected account_id=%s school_id=%s", account.id, president_id)
        except Exception:
            logger.exception("WebSocket error account_id=%s school_id=%s", account.id, president_id)
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
    await handle_websocket_connection(websocket, token, school_id)


@ws_router.websocket("/api/v1/messages/ws")
async def websocket_messages_v1(
    websocket: WebSocket,
    token: str = Query(..., description="JWT access token"),
    school_id: int | None = Query(None),
):
    await handle_websocket_connection(websocket, token, school_id)
