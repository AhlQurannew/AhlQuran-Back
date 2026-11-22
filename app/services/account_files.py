"""Remove what a deleted account or school leaves on disk: avatars, student photos, school image, chat attachments.

Call these only after the database deletion is committed, so a failed deletion never loses files.
"""
import logging
import shutil
from pathlib import Path

from app.core.config import settings

logger = logging.getLogger(__name__)


def _remove_dir(relative: str) -> None:
    root = Path(settings.UPLOAD_DIR).resolve()
    target = (root / relative).resolve()
    if target == root or not target.is_relative_to(root) or not target.is_dir():
        return
    try:
        shutil.rmtree(target)
    except OSError:
        logger.exception("Could not remove %s", relative)


def remove_user_files(user_id: int) -> None:
    """Avatar folder of a school account (teacher, supervisor, director, guardian, student)."""
    _remove_dir(f"accounts/user-{user_id}")


def remove_student_files(student_id: int) -> None:
    _remove_dir(f"students/{student_id}")


def remove_admin_files(admin_id: int) -> None:
    _remove_dir(f"accounts/admin-{admin_id}")


def remove_school_files(school_id: int, user_ids: list[int], student_ids: list[int]) -> None:
    for user_id in user_ids:
        _remove_dir(f"accounts/user-{user_id}")
    for student_id in student_ids:
        _remove_dir(f"students/{student_id}")
    _remove_dir(f"schools/{school_id}")
    _remove_dir(f"messages/{school_id}")


async def attachment_paths(db, *, user_id: int | None = None, admin_id: int | None = None) -> list[str]:
    """Files attached to the messages of an account; the messages are deleted with the account."""
    from sqlalchemy import select

    from app.models.message import Message, MessageAttachment

    sender = Message.sender_id == user_id if user_id is not None else Message.admin_sender_id == admin_id
    rows = await db.execute(
        select(MessageAttachment.storage_path).join(Message, Message.id == MessageAttachment.message_id).where(sender)
    )
    return [path for path in rows.scalars() if path]


def remove_attachment_files(paths: list[str]) -> None:
    from app.services.message_attachments import remove_message_attachment

    for path in paths:
        remove_message_attachment(path)


async def admin_cleanup_targets(db, admin_id: int) -> list[str]:
    return await attachment_paths(db, admin_id=admin_id)


async def clean_after_admin_delete(db, admin_id: int, paths: list[str]) -> None:
    from fastapi.concurrency import run_in_threadpool

    await run_in_threadpool(remove_admin_files, admin_id)
    await run_in_threadpool(remove_attachment_files, paths)
