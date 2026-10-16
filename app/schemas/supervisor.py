from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional


class SupervisorBase(BaseModel):
    firstname: str
    lastname: str
    email: EmailStr


class SupervisorCreate(SupervisorBase):
    password: str


class SupervisorUpdate(BaseModel):
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None  # Optional password for reset


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
