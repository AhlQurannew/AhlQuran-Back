"""Async helpers for resolving school ownership from authenticated accounts."""

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.admin import Admin
from app.models.chief_supervisor import ChiefSupervisor
from app.models.president import President
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.user import UserRoleEnum


async def get_president_id_for_user(
    current_user,
    db: AsyncSession,
    school_id: int | None = None,
) -> int:
    if isinstance(current_user, Admin):
        if school_id is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Admin must provide school_id parameter",
            )
        result = await db.execute(select(President.id).where(President.id == school_id))
        president_id = result.scalar_one_or_none()
        if president_id is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="School not found")
        return president_id

    role = current_user.role
    if role == UserRoleEnum.PRESIDENT:
        result = await db.execute(
            select(President.id).where(President.user_id == current_user.id)
        )
        president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.CHIEF_SUPERVISOR:
        # School creation stores chief supervisors separately from regular
        # supervisors. Keep the regular-supervisor lookup as a fallback for
        # legacy accounts created before the dedicated table was introduced.
        result = await db.execute(
            select(ChiefSupervisor.president_id).where(ChiefSupervisor.user_id == current_user.id)
        )
        president_id = result.scalar_one_or_none()
        if president_id is None:
            result = await db.execute(
                select(Supervisor.president_id).where(Supervisor.user_id == current_user.id)
            )
            president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.SUPERVISOR:
        result = await db.execute(
            select(Supervisor.president_id).where(Supervisor.user_id == current_user.id)
        )
        president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.TEACHER:
        result = await db.execute(
            select(Teacher.president_id).where(Teacher.user_id == current_user.id)
        )
        president_id = result.scalar_one_or_none()
    else:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Unable to determine organization for this user role",
        )
    if president_id is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is not linked to a school",
        )
    return president_id


async def get_creator_user_id(current_user, president_id: int, db: AsyncSession) -> int:
    """Return a valid user FK for audit columns, which do not reference admins."""
    if isinstance(current_user, Admin):
        result = await db.execute(select(President.user_id).where(President.id == president_id))
        user_id = result.scalar_one_or_none()
        if user_id is None:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="School not found")
        return user_id
    return current_user.id
