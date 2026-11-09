"""Inspectors (مفتش): accounts created and managed by the administrator.

An inspector signs in like the administrator and has the same access, except what is reserved to
the administrators (login page images, inspector and administrator accounts). Deactivating it
ends its sessions. If the admin who created it is deleted, it moves to that admin's creator.
"""
import logging

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.dependencies import require_super_admin
from app.core.security import get_password_hash
from app.db.session import get_db
from app.models.admin import Admin

logger = logging.getLogger(__name__)
inspectorRouter = APIRouter()

MIN_PASSWORD = 10


def check_password_bytes(value: str | None) -> str | None:
    """bcrypt only reads the first 72 bytes: refuse longer passwords instead of silently cutting them."""
    if value is not None and len(value.encode("utf-8")) > 72:
        raise ValueError("The password must not exceed 72 bytes")
    return value


class InspectorCreate(BaseModel):
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


class InspectorUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    full_name: str | None = Field(default=None, min_length=1, max_length=150)
    email: EmailStr | None = None
    is_active: bool | None = None
    # A new password resets the inspector's sessions.
    password: str | None = Field(default=None, min_length=MIN_PASSWORD)

    @field_validator("password")
    @classmethod
    def password_bytes(cls, value):
        return check_password_bytes(value)


class InspectorOut(BaseModel):
    id: int
    username: str
    full_name: str | None
    email: str | None
    is_active: bool
    created_at: str | None


def _out(admin: Admin) -> InspectorOut:
    return InspectorOut(
        id=admin.id, username=admin.user, full_name=admin.full_name, email=admin.email,
        is_active=admin.is_active, created_at=admin.created_at.isoformat() if admin.created_at else None,
    )


async def _get(db: AsyncSession, inspector_id: int) -> Admin:
    inspector = await db.scalar(select(Admin).where(Admin.id == inspector_id, Admin.role == "inspector"))
    if inspector is None:
        raise HTTPException(status_code=404, detail="Inspector not found")
    return inspector


async def check_unique(db: AsyncSession, username: str | None, email: str | None, exclude_id: int | None = None) -> None:
    if username:
        query = select(Admin.id).where(func.lower(Admin.user) == username.lower())
        if exclude_id:
            query = query.where(Admin.id != exclude_id)
        if await db.scalar(query.limit(1)):
            raise HTTPException(status_code=409, detail="This username is already used")
    if email:
        query = select(Admin.id).where(func.lower(Admin.email) == email.lower())
        if exclude_id:
            query = query.where(Admin.id != exclude_id)
        if await db.scalar(query.limit(1)):
            raise HTTPException(status_code=409, detail="Email already exists")


@inspectorRouter.get("/", response_model=list[InspectorOut])
async def list_inspectors(db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    rows = (await db.execute(select(Admin).where(Admin.role == "inspector").order_by(Admin.created_at.desc()))).scalars()
    return [_out(a) for a in rows]


@inspectorRouter.post("/", response_model=InspectorOut, status_code=status.HTTP_201_CREATED)
async def create_inspector(data: InspectorCreate, db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    email = data.email.lower() if data.email else None
    await check_unique(db, data.username, email)
    if data.password.strip().lower() in {data.username.lower(), (email or "")}:
        raise HTTPException(status_code=422, detail="The password must differ from the username and e-mail")
    inspector = Admin(
        user=data.username, full_name=data.full_name, email=email, password_hash=get_password_hash(data.password),
        role="inspector", is_active=True, created_by_id=admin.id,
    )
    db.add(inspector)
    await db.commit()
    await db.refresh(inspector)
    logger.info("Inspector %s created by admin %s", inspector.id, admin.id)
    return _out(inspector)


@inspectorRouter.put("/{inspector_id}", response_model=InspectorOut)
async def update_inspector(inspector_id: int, data: InspectorUpdate, db: AsyncSession = Depends(get_db),
                           admin=Depends(require_super_admin)):
    inspector = await _get(db, inspector_id)
    changes = data.model_dump(exclude_unset=True)
    if "email" in changes:
        email = changes["email"].lower() if changes["email"] else None
        await check_unique(db, None, email, exclude_id=inspector.id)
        inspector.email = email
    if changes.get("full_name"):
        inspector.full_name = changes["full_name"].strip()
    end_sessions = False
    if "is_active" in changes and changes["is_active"] is not None and changes["is_active"] != inspector.is_active:
        inspector.is_active = changes["is_active"]
        end_sessions = not inspector.is_active
    if changes.get("password"):
        inspector.password_hash = get_password_hash(changes["password"])
        end_sessions = True
    if end_sessions:
        inspector.auth_version += 1  # existing tokens stop working
    await db.commit()
    await db.refresh(inspector)
    logger.info("Inspector %s updated by admin %s", inspector.id, admin.id)
    return _out(inspector)


@inspectorRouter.delete("/{inspector_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_inspector(inspector_id: int, db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    inspector = await _get(db, inspector_id)
    await db.delete(inspector)
    await db.commit()
    logger.info("Inspector %s deleted by admin %s", inspector_id, admin.id)
