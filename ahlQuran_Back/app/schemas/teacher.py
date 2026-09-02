from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional


class TeacherBase(BaseModel):
    firstname: str
    lastname: str
    email: EmailStr
    riwaya: str

class TeacherCreate(TeacherBase):
    password: str


class TeacherUpdate(BaseModel):
    firstname: Optional[str]
    lastname: Optional[str]
    email: Optional[EmailStr]
    riwaya: Optional[str]


class TeacherResponse(BaseModel):
    id: int
    user_id: int
    firstname: str
    lastname: str
    email: str
    riwaya: str
    hire_date: datetime
    is_active: bool

    class Config:
        from_attributes = True


class TeacherList(BaseModel):
    teachers: list[TeacherResponse]
    total: int
