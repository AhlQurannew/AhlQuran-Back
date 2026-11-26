"""Announcements (إعلانات) and the unread counters behind the sidebar red dots.

- The administrator and inspectors publish announcements (text, images, videos, files) for chosen
  school roles: directors, supervisors, teachers and/or inspectors.
- Every school account sees the announcements addressed to its role; administrators and inspectors
  see all of them.
- /notifications/unread tells the sidebar whether there are new announcements or chat messages since
  the account last opened those pages; /notifications/seen records that visit.
"""
import logging
from datetime import datetime, timezone
from typing import Literal

from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import FileResponse
from pydantic import BaseModel
from sqlalchemy import func, or_, select, true, false
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import get_current_user, require_admin
from app.core.multi_tenancy import get_president_id_for_user
from app.db.session import get_db
from app.models.account_preference import AccountPreference
from app.models.admin import Admin
from app.models.announcement import AUDIENCE_KEYS, Announcement, AnnouncementAttachment
from app.models.message import Message
from app.models.user import User, UserRoleEnum
from app.services.announcement_files import (
    MAX_FILES,
    MAX_TOTAL_BYTES,
    AnnouncementFileError,
    AnnouncementFileTooLarge,
    remove_announcement_file,
    resolve_announcement_file,
    store_announcement_file,
)

logger = logging.getLogger(__name__)
announcementRouter = APIRouter()
notificationRouter = APIRouter()

# School role -> audience key. The internal school account (PRESIDENT) is the director's.
ROLE_AUDIENCE = {
    UserRoleEnum.CHIEF_SUPERVISOR: "chief_supervisor",
    UserRoleEnum.PRESIDENT: "chief_supervisor",
    UserRoleEnum.SUPERVISOR: "supervisor",
    UserRoleEnum.TEACHER: "teacher",
}
CHAT_ROLES = {UserRoleEnum.PRESIDENT, UserRoleEnum.CHIEF_SUPERVISOR, UserRoleEnum.SUPERVISOR, UserRoleEnum.TEACHER}
INLINE_TYPES = {"image/jpeg", "image/png", "image/webp", "image/gif", "video/mp4", "video/webm", "video/quicktime"}


class AttachmentOut(BaseModel):
    id: int
    filename: str
    content_type: str
    size: int


class AnnouncementOut(BaseModel):
    id: int
    title: str
    body: str | None
    audience: list[str]
    author_name: str
    created_at: datetime
    attachments: list[AttachmentOut]
    can_delete: bool


class AnnouncementPage(BaseModel):
    items: list[AnnouncementOut]
    total: int


class UnreadOut(BaseModel):
    announcements: int
    messages: int


class SeenIn(BaseModel):
    kind: Literal["announcements", "messages"]


def _visible(account):
    """SQL condition for the announcements this account may read."""
    if isinstance(account, Admin):
        return true()
    key = ROLE_AUDIENCE.get(getattr(account, "role", None))
    return Announcement.audience.contains([key]) if key else false()


def _can_delete(account, announcement: Announcement) -> bool:
    if not isinstance(account, Admin):
        return False
    return not account.is_inspector or announcement.author_admin_id == account.id


def _out(account, announcement: Announcement) -> AnnouncementOut:
    return AnnouncementOut(
        id=announcement.id,
        title=announcement.title,
        body=announcement.body,
        audience=list(announcement.audience),
        author_name=announcement.author_name,
        created_at=announcement.created_at,
        attachments=[AttachmentOut(id=a.id, filename=a.filename, content_type=a.content_type, size=a.size) for a in announcement.attachments],
        can_delete=_can_delete(account, announcement),
    )


def _author_name(admin: Admin) -> str:
    name = admin.full_name or admin.user
    return f"{name} (مفتش)" if admin.is_inspector else name


@announcementRouter.get("/", response_model=AnnouncementPage)
async def list_announcements(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    account=Depends(get_current_user),
):
    condition = _visible(account)
    total = await db.scalar(select(func.count(Announcement.id)).where(condition))
    rows = (await db.execute(
        select(Announcement).options(selectinload(Announcement.attachments)).where(condition)
        .order_by(Announcement.created_at.desc(), Announcement.id.desc()).offset(skip).limit(limit)
    )).scalars().all()
    return AnnouncementPage(items=[_out(account, row) for row in rows], total=total or 0)


@announcementRouter.post("/", response_model=AnnouncementOut, status_code=status.HTTP_201_CREATED)
async def create_announcement(
    title: str = Form(..., min_length=1, max_length=200),
    body: str | None = Form(None, max_length=5000),
    audience: list[str] = Form(...),
    files: list[UploadFile] = File(default=[]),
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_admin),
):
    if not isinstance(admin, Admin):
        raise HTTPException(status_code=403, detail="Only administrators and inspectors can publish announcements")
    keys = set(AUDIENCE_KEYS) if "all" in audience else set(audience)
    if not keys or not keys <= set(AUDIENCE_KEYS):
        raise HTTPException(status_code=422, detail="Choose at least one valid audience")
    title = title.strip()
    if not title:
        raise HTTPException(status_code=422, detail="The title cannot be blank")
    files = [upload for upload in files if upload.filename]
    if len(files) > MAX_FILES:
        for upload in files:
            await upload.close()
        raise HTTPException(status_code=413, detail=f"An announcement can include at most {MAX_FILES} files")

    stored = []
    try:
        total = 0
        for upload in files:
            item = await run_in_threadpool(store_announcement_file, upload.file, upload.filename, MAX_TOTAL_BYTES - total)
            total += item.size
            stored.append(item)
    except AnnouncementFileTooLarge as exc:
        for item in stored:
            remove_announcement_file(item.storage_path)
        raise HTTPException(status_code=413, detail=str(exc)) from exc
    except (AnnouncementFileError, ValueError) as exc:
        for item in stored:
            remove_announcement_file(item.storage_path)
        raise HTTPException(status_code=415, detail=str(exc)) from exc
    except Exception:
        for item in stored:
            remove_announcement_file(item.storage_path)
        raise
    finally:
        for upload in files:
            await upload.close()

    announcement = Announcement(
        title=title,
        body=(body or "").strip() or None,
        audience=[key for key in AUDIENCE_KEYS if key in keys],
        author_admin_id=admin.id,
        author_name=_author_name(admin),
        attachments=[AnnouncementAttachment(storage_path=i.storage_path, filename=i.filename, content_type=i.content_type, size=i.size) for i in stored],
    )
    try:
        db.add(announcement)
        await db.commit()
    except Exception:
        await db.rollback()
        for item in stored:
            remove_announcement_file(item.storage_path)
        raise
    result = await db.execute(select(Announcement).options(selectinload(Announcement.attachments)).where(Announcement.id == announcement.id))
    logger.info("Announcement %s published by admin %s", announcement.id, admin.id)
    return _out(admin, result.scalar_one())


@announcementRouter.delete("/{announcement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_announcement(
    announcement_id: int,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_admin),
):
    announcement = await db.scalar(
        select(Announcement).options(selectinload(Announcement.attachments)).where(Announcement.id == announcement_id)
    )
    if announcement is None:
        raise HTTPException(status_code=404, detail="Announcement not found")
    if not _can_delete(admin, announcement):
        raise HTTPException(status_code=403, detail="Inspectors can only delete their own announcements")
    paths = [item.storage_path for item in announcement.attachments]
    await db.delete(announcement)
    await db.commit()
    for path in paths:
        remove_announcement_file(path)


@announcementRouter.get("/attachments/{attachment_id}")
async def get_announcement_attachment(
    attachment_id: int,
    db: AsyncSession = Depends(get_db),
    account=Depends(get_current_user),
):
    attachment = await db.scalar(
        select(AnnouncementAttachment)
        .join(Announcement, Announcement.id == AnnouncementAttachment.announcement_id)
        .where(AnnouncementAttachment.id == attachment_id, _visible(account))
    )
    if attachment is None:
        raise HTTPException(status_code=404, detail="Attachment not found")
    path = resolve_announcement_file(attachment.storage_path)
    if path is None:
        raise HTTPException(status_code=404, detail="Attachment file not found")
    inline = attachment.content_type in INLINE_TYPES
    return FileResponse(
        path,
        media_type=attachment.content_type if attachment.content_type != "image/svg+xml" else "application/octet-stream",
        filename=attachment.filename,
        content_disposition_type="inline" if inline else "attachment",
        headers={"X-Content-Type-Options": "nosniff", "Cache-Control": "private, no-store", "Content-Security-Policy": "default-src 'none'; sandbox"},
    )


# ==================== UNREAD COUNTERS ====================

async def _preference(db: AsyncSession, account) -> AccountPreference:
    """The account's preference row; the first visit starts both counters from now (no backlog)."""
    owner = AccountPreference.user_id == account.id if isinstance(account, User) else AccountPreference.admin_id == account.id
    preference = await db.scalar(select(AccountPreference).where(owner))
    now = datetime.now(timezone.utc)
    if preference is None:
        preference = AccountPreference(user_id=account.id) if isinstance(account, User) else AccountPreference(admin_id=account.id)
        preference.announcements_seen_at = now
        preference.messages_seen_at = now
        db.add(preference)
    elif preference.announcements_seen_at is None or preference.messages_seen_at is None:
        preference.announcements_seen_at = preference.announcements_seen_at or now
        preference.messages_seen_at = preference.messages_seen_at or now
    else:
        return preference
    try:
        await db.commit()
    except IntegrityError:
        # Two requests created the row at the same time: use the one that won.
        await db.rollback()
        preference = await db.scalar(select(AccountPreference).where(owner))
    return preference


async def _unread_messages(db: AsyncSession, account, since: datetime) -> int:
    if isinstance(account, Admin):
        condition = or_(Message.admin_sender_id.is_(None), Message.admin_sender_id != account.id)
    elif getattr(account, "role", None) in CHAT_ROLES:
        try:
            president_id = await get_president_id_for_user(account, db)
        except HTTPException:
            return 0
        condition = (Message.president_id == president_id) & or_(Message.sender_id.is_(None), Message.sender_id != account.id)
    else:
        return 0
    return await db.scalar(select(func.count(Message.id)).where(condition, Message.created_at > since)) or 0


@notificationRouter.get("/unread", response_model=UnreadOut)
async def unread_counts(db: AsyncSession = Depends(get_db), account=Depends(get_current_user)):
    preference = await _preference(db, account)
    announcements_condition = [_visible(account), Announcement.created_at > preference.announcements_seen_at]
    if isinstance(account, Admin):
        announcements_condition.append(or_(Announcement.author_admin_id.is_(None), Announcement.author_admin_id != account.id))
    announcements = await db.scalar(select(func.count(Announcement.id)).where(*announcements_condition)) or 0
    messages = await _unread_messages(db, account, preference.messages_seen_at)
    return UnreadOut(announcements=announcements, messages=messages)


@notificationRouter.post("/seen", response_model=UnreadOut)
async def mark_seen(data: SeenIn, db: AsyncSession = Depends(get_db), account=Depends(get_current_user)):
    preference = await _preference(db, account)
    setattr(preference, f"{data.kind}_seen_at", datetime.now(timezone.utc))
    await db.commit()
    return await unread_counts(db, account)
