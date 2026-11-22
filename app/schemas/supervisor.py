from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

from app.schemas.fields import GuardianName, LoginEmail, NewPassword, OptionalNewPassword, PersonName


class SupervisorBase(BaseModel):
    firstname: PersonName
    lastname: PersonName
    email: LoginEmail


class SupervisorCreate(SupervisorBase):
    password: NewPassword


class SupervisorUpdate(BaseModel):
    firstname: Optional[PersonName] = None
    lastname: Optional[PersonName] = None
    email: Optional[LoginEmail] = None
    password: OptionalNewPassword = None  # Optional password for reset


class SupervisorResponse(BaseModel):
    id: int
    user_id: int
    firstname: str
    lastname: str
    email: str
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True


class SupervisorList(BaseModel):
    supervisors: list[SupervisorResponse]
    total: int
