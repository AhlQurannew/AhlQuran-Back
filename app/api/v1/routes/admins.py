"""Additional administrator accounts, created and managed by administrators.

Guard rails, because an administrator can otherwise lock out or take over another one:
- nobody changes their own account here (profile and password live in the account settings);
- the main accounts (created at install, created_by_id NULL) cannot be changed by anyone here, so
  at least one working administrator always exists;
- deleting an administrator hands the accounts it created to its own creator, instead of letting
  the foreign key cascade delete them.
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.routes.inspectors import check_password_bytes, check_unique
from app.core.dependencies import require_super_admin
from app.core.security import get_password_hash
from app.db.session import get_db
from app.models.admin import Admin

logger = logging.getLogger(__name__)
adminAccountRouter = APIRouter()

MIN_PASSWORD = 12


class AdminCreate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    username: str = Field(min_length=3, max_length=100)
    full_name: str = Field(min_length=1, max_length=150)
    email: EmailStr | None = None
    password: str = Field(min_length=MIN_PASSWORD)

    @field_validator("username", "full_name")
    @classmethod
    def strip(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("This field is required")
        return value

    @field_validator("password")
    @classmethod
    def password_bytes(cls, value):
        return check_password_bytes(value)


class AdminUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: str | None = Field(default=None, min_length=1, max_length=150)
    email: EmailStr | None = None
    is_active: bool | None = None
    # A new password ends the account's sessions.
    password: str | None = Field(default=None, min_length=MIN_PASSWORD)

    @field_validator("password")
    @classmethod
    def password_bytes(cls, value):
        return check_password_bytes(value)


class AdminOut(BaseModel):
    id: int
    username: str
    full_name: str | None
    email: str | None
    is_active: bool
    created_at: str | None
    # Main account: shown, but it has no actions.
    protected: bool
    is_self: bool


def _out(target: Admin, actor: Admin) -> AdminOut:
    return AdminOut(
        id=target.id, username=target.user, full_name=target.full_name, email=target.email, is_active=target.is_active,
        created_at=target.created_at.isoformat() if target.created_at else None,
        protected=target.created_by_id is None, is_self=target.id == actor.id,
    )


def _reject_password_like_identity(password: str, username: str, email: str | None) -> None:
    if password.strip().lower() in {username.lower(), (email or "").lower()}:
        raise HTTPException(status_code=422, detail="The password must differ from the username and e-mail")


async def _manageable(db: AsyncSession, admin_id: int, actor: Admin) -> Admin:
    target = await db.scalar(select(Admin).where(Admin.id == admin_id, Admin.role == "admin"))
    if target is None:
        raise HTTPException(status_code=404, detail="Administrator not found")
    if target.id == actor.id:
        raise HTTPException(status_code=403, detail="You cannot change your own account")
    if target.created_by_id is None:
        raise HTTPException(status_code=403, detail="The main administrator account cannot be changed")
    return target


@adminAccountRouter.get("/", response_model=list[AdminOut])
async def list_admins(db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    rows = (await db.execute(select(Admin).where(Admin.role == "admin").order_by(Admin.created_at, Admin.id))).scalars()
    return [_out(row, admin) for row in rows]


@adminAccountRouter.post("/", response_model=AdminOut, status_code=status.HTTP_201_CREATED)
async def create_admin(data: AdminCreate, db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    email = data.email.lower() if data.email else None
    await check_unique(db, data.username, email)
    _reject_password_like_identity(data.password, data.username, email)
    created = Admin(
        user=data.username, full_name=data.full_name, email=email, password_hash=get_password_hash(data.password),
        role="admin", is_active=True, created_by_id=admin.id,
    )
    db.add(created)
    await db.commit()
    await db.refresh(created)
    logger.info("Administrator %s created by admin %s", created.id, admin.id)
    return _out(created, admin)


@adminAccountRouter.put("/{admin_id}", response_model=AdminOut)
async def update_admin(admin_id: int, data: AdminUpdate, db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    target = await _manageable(db, admin_id, admin)
    changes = data.model_dump(exclude_unset=True)
    if "email" in changes:
        email = changes["email"].lower() if changes["email"] else None
        await check_unique(db, None, email, exclude_id=target.id)
        target.email = email
    if changes.get("full_name"):
        target.full_name = changes["full_name"].strip()
    end_sessions = False
    if changes.get("is_active") is not None and changes["is_active"] != target.is_active:
        target.is_active = changes["is_active"]
        end_sessions = not target.is_active
    if changes.get("password"):
        _reject_password_like_identity(changes["password"], target.user, target.email)
        target.password_hash = get_password_hash(changes["password"])
        end_sessions = True
    if end_sessions:
        target.auth_version += 1
    await db.commit()
    await db.refresh(target)
    logger.info("Administrator %s updated by admin %s", target.id, admin.id)
    return _out(target, admin)


@adminAccountRouter.delete("/{admin_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_admin(admin_id: int, db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    target = await _manageable(db, admin_id, admin)
    # Its accounts move up to its creator; the foreign key would otherwise delete them all.
    await db.execute(update(Admin).where(Admin.created_by_id == target.id).values(created_by_id=target.created_by_id))
    await db.delete(target)
    await db.commit()
    logger.info("Administrator %s deleted by admin %s", admin_id, admin.id)
