"""Async helpers for resolving school ownership from authenticated accounts."""

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.admin import Admin
from app.models.chief_supervisor import ChiefSupervisor
from app.models.president import President
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.student import Student
from app.models.guardian import Guardian
from app.models.user import UserRoleEnum


async def get_president_id_for_user(
    current_user,
    db: AsyncSession,
    school_id: int | None = None,
) -> int:
    """Resolve a user's school and reject any caller-selected cross-tenant context."""
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

    role = getattr(current_user.role, "value", current_user.role)
    if role == UserRoleEnum.PRESIDENT.value:
        result = await db.execute(select(President.id).where(President.user_id == current_user.id))
        president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.CHIEF_SUPERVISOR.value:
        result = await db.execute(
            select(ChiefSupervisor.president_id).where(ChiefSupervisor.user_id == current_user.id)
        )
        president_id = result.scalar_one_or_none()
        if president_id is None:
            result = await db.execute(
                select(Supervisor.president_id).where(Supervisor.user_id == current_user.id)
            )
            president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.SUPERVISOR.value:
        result = await db.execute(select(Supervisor.president_id).where(Supervisor.user_id == current_user.id))
        president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.TEACHER.value:
        result = await db.execute(select(Teacher.president_id).where(Teacher.user_id == current_user.id))
        president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.STUDENT.value:
        result = await db.execute(select(Student.president_id).where(Student.user_id == current_user.id))
        president_id = result.scalar_one_or_none()
    elif role == UserRoleEnum.GUARDIAN.value:
        result = await db.execute(select(Guardian.president_id).where(Guardian.user_id == current_user.id))
        president_id = result.scalar_one_or_none()
        if president_id is None:
            schools_result = await db.execute(
                select(Student.president_id)
                .join(Guardian, Student.guardian_id == Guardian.id)
                .where(Guardian.user_id == current_user.id)
                .distinct()
            )
            schools = list(schools_result.scalars().all())
            if school_id is not None and school_id in schools:
                president_id = school_id
            elif len(schools) == 1:
                president_id = schools[0]
            elif len(schools) > 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Guardian must select one of their linked schools",
                )
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
    if school_id is not None and school_id != president_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not authorized to access this school",
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
