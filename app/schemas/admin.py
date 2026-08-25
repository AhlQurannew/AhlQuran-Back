from pydantic import BaseModel, EmailStr
from typing import Optional

class AdminCreate(BaseModel):
    user: str
    password: str

class AdminApprove(BaseModel):
    admin_id: int
    approved: bool

class AdminResponse(BaseModel):
    message: str
    admin_id: Optional[int] = None
    email: Optional[EmailStr] = None
    name: Optional[str] = None

class AdminListResponse(BaseModel):
    admins: list[AdminResponse]