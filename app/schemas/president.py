from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class PresidentCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8)

class PresidentResponse(BaseModel):
    id: int
    username: str
    email: EmailStr
    is_active: bool
    is_approved: bool

class PresidentUpdate(BaseModel):
    username: Optional[str] = Field(None, min_length=3, max_length=50)
    email: Optional[EmailStr]
    is_approved: Optional[bool] = None

class PresidentApproval(BaseModel):
    president_id: int
    approved: bool