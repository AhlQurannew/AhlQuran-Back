"""Helpers for safely deleting and recreating role-specific user accounts."""

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.models.user import User, UserRoleEnum


async def restore_orphaned_account(
    db: AsyncSession,
    *,
    email: str,
    firstname: str,
    lastname: str,
    password: str,
    role: UserRoleEnum,
    profile_model: type,
) -> User | None:
    """Reuse a same-role user left behind by legacy profile-only deletion."""
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if user is None:
        return None

    if user.role != role:
        raise HTTPException(status_code=400, detail="Email already registered")

    profile_result = await db.execute(
        select(profile_model.id).where(profile_model.user_id == user.id)
    )
    if profile_result.scalar_one_or_none() is not None:
        raise HTTPException(status_code=400, detail="Email already registered")

    user.firstname = firstname
    user.lastname = lastname
    user.hashed_password = get_password_hash(password)
    user.is_active = True
    user.auth_version += 1
    return user
