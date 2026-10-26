import logging

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import FileResponse
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.v1.routes.ws_messages import broadcast_to_group
from app.core.config import settings
from app.core.dependencies import get_current_user
from app.core.multi_tenancy import get_president_id_for_user as resolve_president_id
from app.db.session import get_db
from app.models.admin import Admin
from app.models.message import Message, MessageAttachment, SenderRole
from app.schemas.message import MessageAttachmentResponse, MessageCreate, MessageList, MessageResponse
from app.services.message_attachments import (
    AttachmentTooLarge,
    AttachmentTotalTooLarge,
    MAX_ATTACHMENT_BYTES,
    MAX_ATTACHMENTS_PER_MESSAGE,
    MAX_MESSAGE_ATTACHMENT_BYTES,
    cleanup_orphaned_message_attachments,
    remove_message_attachment,
    resolve_message_attachment_path,
    store_message_attachment,
)

logger = logging.getLogger(__name__)
messageRouter = APIRouter()


async def get_president_id_for_user(current_user, db: AsyncSession, school_id: int | None = None) -> int:
    return await resolve_president_id(current_user, db, school_id=school_id)


def get_sender_role(user) -> SenderRole:
    if isinstance(user, Admin):
        return SenderRole.ADMIN
    role = getattr(user.role, "value", user.role)

    try:
        return SenderRole(str(role).lower())
    except ValueError as exc:
        raise HTTPException(status_code=403, detail="This account cannot send messages") from exc


def _sender_name(user) -> str:
    if isinstance(user, Admin):
        return user.user
    return f"{user.firstname} {user.lastname}".strip()


def _attachment_response(attachment: MessageAttachment, school_id: int | None) -> MessageAttachmentResponse:
    url = f"{settings.API_V1_PREFIX}/messages/attachments/{attachment.id}"
    if school_id is not None:
        url = f"{url}?school_id={school_id}"
    return MessageAttachmentResponse(
        id=attachment.id,
        filename=attachment.filename,
        content_type=attachment.content_type,
        size=attachment.size,
        url=url,
    )


def _message_response(
    message: Message,
    attachments: list[MessageAttachment] | None = None,
) -> MessageResponse:
    # Async ORM relationships must be provided by an eager-loaded query or the
    # already-loaded list; never trigger implicit I/O while building a response.
    return MessageResponse(
        id=message.id,
        sender_id=message.sender_id,
        admin_sender_id=message.admin_sender_id,
        sender_name=message.sender_name,
        sender_role=getattr(message.sender_role, "value", str(message.sender_role)),
        message=message.message,
        created_at=message.created_at,
        attachments=[
            _attachment_response(item, message.president_id)
            for item in (attachments or [])
        ],
    )


def _message_event(message: Message, attachments: list[MessageAttachment] | None = None) -> dict:
    response = _message_response(message, attachments)
    return {
        "type": "message",
        "id": response.id,
        "sender_id": response.sender_id,
        "admin_sender_id": response.admin_sender_id,
        "sender_name": response.sender_name,
        "sender_role": response.sender_role,
        "message": response.message,
        "created_at": response.created_at.isoformat(),
        "attachments": [item.model_dump() for item in response.attachments],
    }


def _new_message(current_user, president_id: int, text: str) -> Message:
    is_admin = isinstance(current_user, Admin)
    return Message(
        sender_id=None if is_admin else current_user.id,
        admin_sender_id=current_user.id if is_admin else None,
        sender_name=_sender_name(current_user),
        sender_role=get_sender_role(current_user),
        message=text,
        president_id=president_id,
        attachments=[],
    )


@messageRouter.post("/", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message(
    message_data: MessageCreate,
    school_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Create a compatible text-only message; sender role always comes from auth."""
    president_id = await get_president_id_for_user(current_user, db, school_id)
    new_message = _new_message(current_user, president_id, message_data.message)
    db.add(new_message)
    await db.commit()
    logger.info("Message created in school_id=%s", president_id)
    try:
        await broadcast_to_group(president_id, _message_event(new_message))
    except Exception:
        logger.warning("Failed to broadcast REST-created message over WebSocket", exc_info=True)
    return _message_response(new_message)


@messageRouter.post("/with-attachments", response_model=MessageResponse, status_code=status.HTTP_201_CREATED)
async def create_message_with_attachments(
    message: str | None = Form(None, max_length=5000),
    attachments: list[UploadFile] = File(default=[]),
    school_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Create a message with up to five locally stored, content-validated files."""
    president_id = await get_president_id_for_user(current_user, db, school_id)
    caption = (message or "").strip()
    if not caption and not attachments:
        raise HTTPException(status_code=400, detail="Provide a message caption or at least one attachment")
    if len(attachments) > MAX_ATTACHMENTS_PER_MESSAGE:
        for upload in attachments:
            await upload.close()
        raise HTTPException(status_code=413, detail="A message can include at most 5 attachments")

    stored = []
    total_size = 0
    try:
        for upload in attachments:
            remaining_total = MAX_MESSAGE_ATTACHMENT_BYTES - total_size
            if remaining_total <= 0:
                raise AttachmentTotalTooLarge("Attachments must total 50 MiB or less")
            item = await run_in_threadpool(
                store_message_attachment,
                upload.file,
                president_id,
                upload.filename,
                min(MAX_ATTACHMENT_BYTES, remaining_total),
            )
            total_size += item.size
            stored.append(item)
    except AttachmentTotalTooLarge as exc:
        for item in stored:
            remove_message_attachment(item.storage_path)
        raise HTTPException(status_code=413, detail=str(exc)) from exc
    except AttachmentTooLarge as exc:
        for item in stored:
            remove_message_attachment(item.storage_path)
        raise HTTPException(status_code=413, detail=str(exc)) from exc
    except ValueError as exc:
        for item in stored:
            remove_message_attachment(item.storage_path)
        raise HTTPException(status_code=415, detail=str(exc)) from exc
    except Exception:
        for item in stored:
            remove_message_attachment(item.storage_path)
        raise
    finally:
        for upload in attachments:
            await upload.close()

    try:
        new_message = _new_message(current_user, president_id, caption)
        message_attachments = [
            MessageAttachment(
                storage_path=item.storage_path,
                filename=item.filename,
                content_type=item.content_type,
                size=item.size,
            )
            for item in stored
        ]
        new_message.attachments = message_attachments
        db.add(new_message)
        await db.commit()
    except Exception:
        try:
            await db.rollback()
        except Exception:
            logger.exception("Could not roll back attachment message transaction")
        for item in stored:
            remove_message_attachment(item.storage_path)
        raise
    try:
        await cleanup_orphaned_message_attachments(db, president_id)
    except Exception:
        logger.warning("Could not clean old orphaned message files", exc_info=True)
    try:
        await broadcast_to_group(president_id, _message_event(new_message, message_attachments))
    except Exception:
        logger.warning("Failed to broadcast attachment message over WebSocket", exc_info=True)
    return _message_response(new_message, message_attachments)


@messageRouter.get("/attachments/{attachment_id}")
async def get_message_attachment(
    attachment_id: int,
    school_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    """Serve a private attachment only to a user authorized for its school."""
    president_id = await get_president_id_for_user(current_user, db, school_id)
    result = await db.execute(
        select(MessageAttachment, Message)
        .join(Message, Message.id == MessageAttachment.message_id)
        .where(MessageAttachment.id == attachment_id, Message.president_id == president_id)
    )
    record = result.one_or_none()
    if record is None:
        raise HTTPException(status_code=404, detail="Attachment not found")
    attachment, _message = record

    file_path = resolve_message_attachment_path(attachment.storage_path, president_id)
    if file_path is None:
        raise HTTPException(status_code=404, detail="Attachment file not found")

    # SVG is always downloaded as opaque bytes, never rendered inline.
    media_type = "application/octet-stream" if attachment.content_type == "image/svg+xml" else attachment.content_type
    return FileResponse(
        file_path,
        media_type=media_type,
        filename=attachment.filename,
        content_disposition_type="attachment",
        headers={
            "X-Content-Type-Options": "nosniff",
            "Cache-Control": "private, no-store",
            "Content-Security-Policy": "default-src 'none'; sandbox",
        },
    )


@messageRouter.get("/", response_model=MessageList)
async def get_messages(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=200),
    school_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    result = await db.execute(
        select(Message)
        .options(selectinload(Message.attachments))
        .where(Message.president_id == president_id)
        .order_by(Message.created_at.desc())
        .offset(skip)
        .limit(limit)
    )
    messages = result.scalars().all()
    total = await db.scalar(select(func.count(Message.id)).where(Message.president_id == president_id)) or 0
    return MessageList(messages=[_message_response(item, item.attachments) for item in messages], total=total)


@messageRouter.get("/recent", response_model=MessageList)
async def get_recent_messages(
    limit: int = Query(50, ge=1, le=200),
    school_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    result = await db.execute(
        select(Message)
        .options(selectinload(Message.attachments))
        .where(Message.president_id == president_id)
        .order_by(Message.created_at.desc())
        .limit(limit)
    )
    messages = result.scalars().all()
    total = await db.scalar(select(func.count(Message.id)).where(Message.president_id == president_id)) or 0
    return MessageList(messages=[_message_response(item, item.attachments) for item in messages], total=total)


@messageRouter.delete("/{message_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_message(
    message_id: int,
    school_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    result = await db.execute(
        select(Message)
        .options(selectinload(Message.attachments))
        .where(Message.id == message_id, Message.president_id == president_id)
    )
    message = result.scalar_one_or_none()
    if message is None:
        raise HTTPException(status_code=404, detail=f"Message with ID {message_id} not found")

    owns_message = (
        message.admin_sender_id == current_user.id
        if isinstance(current_user, Admin)
        else message.sender_id == current_user.id
    )
    if not owns_message:
        raise HTTPException(status_code=403, detail="You can only delete your own messages")

    attachment_paths = [item.storage_path for item in message.attachments]
    await db.delete(message)
    await db.commit()
    # Files are removed only after the metadata transaction commits; failed DB
    # deletes therefore leave valid files, while cleanup errors leave private orphans.
    for storage_path in attachment_paths:
        remove_message_attachment(storage_path)
    try:
        await cleanup_orphaned_message_attachments(db, president_id)
    except Exception:
        logger.warning("Could not clean old orphaned message files", exc_info=True)

    try:
        await broadcast_to_group(president_id, {"type": "delete", "id": message_id})
    except Exception:
        logger.warning("Failed to broadcast message deletion over WebSocket", exc_info=True)
    return None
