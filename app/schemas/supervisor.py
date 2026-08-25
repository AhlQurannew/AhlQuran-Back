from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional

class SupervisorBase(BaseModel):
    firstname: str
    lastname: str
    email: EmailStr

class SupervisorCreate(SupervisorBase):
    password: str = Field(..., min_length=6)

class SupervisorUpdate(BaseModel):
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = Field(None, min_length=6)

class SupervisorResponse(SupervisorBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

class SupervisorList(BaseModel):
    supervisors: list[SupervisorResponse]
    total: int