"""Activate / deactivate accounts down the hierarchy (تفعيل / تعطيل).

- administrator and inspectors: any school account (on the schools list: the chief supervisor)
- chief supervisor: supervisors and teachers of their school
- supervisor: teachers of their school

Students and guardians are not included: they have no way to sign in to the app yet.

Nobody can change their own account. Deactivating ends the account's sessions right away (the
token version changes) and the account cannot sign in until it is activated again.
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_school_management_access
from app.core.multi_tenancy import get_president_id_for_user
from app.db.session import get_db
from app.models.admin import Admin
from app.models.chief_supervisor import ChiefSupervisor
from app.models.guardian import Guardian
from app.models.president import President
from app.models.student import Student
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.user import User, UserRoleEnum

logger = logging.getLogger(__name__)
accountRouter = APIRouter()

# Roles each manager may switch on / off (accounts that actually sign in).
MANAGEABLE = {
    UserRoleEnum.PRESIDENT: {UserRoleEnum.SUPERVISOR, UserRoleEnum.TEACHER},
    UserRoleEnum.CHIEF_SUPERVISOR: {UserRoleEnum.SUPERVISOR, UserRoleEnum.TEACHER},
    UserRoleEnum.SUPERVISOR: {UserRoleEnum.TEACHER},
}


class ActiveIn(BaseModel):
    is_active: bool


class ActiveOut(BaseModel):
    user_id: int
    is_active: bool


async def _school_of(db: AsyncSession, user: User) -> set[int]:
    """Schools a user account belongs to (a guardian may belong to several through their children)."""
    schools: set[int] = set()
    for model in (ChiefSupervisor, Supervisor, Teacher, Student, Guardian):
        value = await db.scalar(select(model.president_id).where(model.user_id == user.id))
        if value:
            schools.add(value)
    president = await db.scalar(select(President.id).where(President.user_id == user.id))
    if president:
        schools.add(president)
    if user.role == UserRoleEnum.GUARDIAN:
        schools |= set((await db.execute(
            select(Student.president_id).join(Guardian, Guardian.id == Student.guardian_id).where(Guardian.user_id == user.id)
        )).scalars())
    return schools


@accountRouter.patch("/{user_id}/active", response_model=ActiveOut)
async def set_account_active(
    user_id: int,
    data: ActiveIn,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
    school_id: int | None = None,
):
    target = await db.get(User, user_id)
    if target is None:
        raise HTTPException(status_code=404, detail="Account not found")
    if not isinstance(current_user, Admin):
        if target.id == current_user.id:
            raise HTTPException(status_code=403, detail="You cannot change your own account")
        allowed = MANAGEABLE.get(current_user.role, set())
        if target.role not in allowed:
            raise HTTPException(status_code=403, detail="You cannot change this account")
        president_id = await get_president_id_for_user(current_user, db, school_id)
        if president_id not in await _school_of(db, target):
            raise HTTPException(status_code=404, detail="Account not found")

    if target.is_active != data.is_active:
        target.is_active = data.is_active
        if not data.is_active:
            target.auth_version += 1  # signs the account out everywhere
        await db.commit()
        logger.info("Account %s %s by %s %s", target.id, "activated" if data.is_active else "deactivated",
                    "admin" if isinstance(current_user, Admin) else "user", current_user.id)
    return ActiveOut(user_id=target.id, is_active=target.is_active)
