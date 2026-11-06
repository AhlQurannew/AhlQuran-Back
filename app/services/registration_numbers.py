"""Unique, human-friendly registration numbers for students (S2026-0001) and teachers (T2026-0001).

A number is generated when the form leaves it empty, and an administrator may type their
own value instead; either way it must be unique (case-insensitive) within its table.
"""
import re
from datetime import date

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

STUDENT_PREFIX = "S"
TEACHER_PREFIX = "T"
MAX_LENGTH = 30
VALID = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_/\-]*$")


def normalize(value: str | None) -> str:
    return (value or "").strip().upper()


def validate_format(value: str) -> None:
    if len(value) > MAX_LENGTH or not VALID.match(value):
        raise HTTPException(
            status_code=422,
            detail="The ID may only contain letters, digits, '-', '_' or '/' (30 characters max)",
        )


async def is_taken(db: AsyncSession, model, value: str, exclude_id: int | None = None) -> bool:
    query = select(model.id).where(func.upper(model.registration_number) == value)
    if exclude_id is not None:
        query = query.where(model.id != exclude_id)
    return (await db.scalar(query.limit(1))) is not None


async def suggest(db: AsyncSession, model, prefix: str, year: int | None = None) -> str:
    """Next free number for the year, e.g. S2026-0007."""
    year = year or date.today().year
    stem = f"{prefix}{year}-"
    count = await db.scalar(select(func.count(model.id)).where(model.registration_number.like(f"{stem}%"))) or 0
    sequence = count + 1
    while await is_taken(db, model, f"{stem}{sequence:04d}"):
        sequence += 1
    return f"{stem}{sequence:04d}"


async def resolve(db: AsyncSession, model, prefix: str, requested: str | None, exclude_id: int | None = None) -> str:
    """Use the typed number when given (validated + unique), otherwise generate one."""
    value = normalize(requested)
    if not value:
        return await suggest(db, model, prefix)
    validate_format(value)
    if await is_taken(db, model, value, exclude_id):
        raise HTTPException(status_code=409, detail="This ID is already used by another record")
    return value
