"""Helpers for safely deleting and recreating role-specific user accounts."""

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import get_password_hash
from app.models.user import User, UserRoleEnum


MAX_PASSWORD_BYTES = 72  # bcrypt ignores or rejects anything longer
async def student_in_lecture_or_its_history(db: AsyncSession, student_id: int, lecture_id: int, president_id: int) -> bool:
    """The student is in the lecture now, or was and still has attendance there (kept as history)."""
    from app.models.attendance import Attendance
    from app.models.lecture import Lecture
    from app.models.sessionParticipation import SessionParticipation

    enrolled = await db.scalar(
        select(SessionParticipation.id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .where(SessionParticipation.student_id == student_id, SessionParticipation.lecture_id == lecture_id,
               Lecture.president_id == president_id)
        .limit(1)
    )
    if enrolled is not None:
        return True
    return await db.scalar(
        select(Attendance.id)
        .where(Attendance.student_id == student_id, Attendance.lecture_id == lecture_id, Attendance.president_id == president_id)
        .limit(1)
    ) is not None


SCHOOL_DEACTIVATED = "Your school is deactivated. Please contact the administrator."


async def ensure_school_active(db: AsyncSession, user: User) -> None:
    """Accounts of a school whose director (chief supervisor) is deactivated cannot be used.

    A school with several directors stays open while at least one of them is active.
    """
    from app.models.chief_supervisor import ChiefSupervisor
    from app.models.guardian import Guardian
    from app.models.student import Student
    from app.models.supervisor import Supervisor
    from app.models.teacher import Teacher

    profile = {
        UserRoleEnum.TEACHER: Teacher,
        UserRoleEnum.SUPERVISOR: Supervisor,
        UserRoleEnum.STUDENT: Student,
        UserRoleEnum.GUARDIAN: Guardian,
    }.get(user.role)
    if profile is None:
        return
    directors_active = (await db.execute(
        select(User.is_active)
        .join(ChiefSupervisor, ChiefSupervisor.user_id == User.id)
        .join(profile, profile.president_id == ChiefSupervisor.president_id)
        .where(profile.user_id == user.id)
    )).scalars().all()
    if directors_active and not any(directors_active):
        raise HTTPException(status_code=403, detail=SCHOOL_DEACTIVATED)


def reset_user_password(user: User, password: str) -> None:
    """Set a new password on someone's behalf and end their existing sessions.

    Bumping auth_version invalidates tokens issued with the old password, matching what
    the self-service password change does.
    """
    if len(password.encode("utf-8")) > MAX_PASSWORD_BYTES:
        raise HTTPException(status_code=422, detail="Password must be at most 72 bytes")
    user.hashed_password = get_password_hash(password)
    user.auth_version += 1


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
    result = await db.execute(select(User).where(func.lower(User.email) == email.strip().lower()))
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
