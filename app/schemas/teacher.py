from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional


class TeacherProfile(BaseModel):
    # Empty registration_number -> generated server-side (T<year>-0001); otherwise must be unique.
    registration_number: Optional[str] = Field(None, max_length=30)
    speciality: Optional[str] = Field(None, max_length=150)
    date_of_birth: Optional[str] = Field(None, max_length=20)
    place_of_birth: Optional[str] = Field(None, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = Field(None, max_length=255)
    medical_condition: Optional[str] = Field(None, max_length=2000)


class TeacherBase(BaseModel):
    firstname: str
    lastname: str
    email: EmailStr
    riwaya: str

class TeacherCreate(TeacherBase, TeacherProfile):
    password: str


class TeacherUpdate(TeacherProfile):
    firstname: Optional[str] = None
    lastname: Optional[str] = None
    email: Optional[EmailStr] = None
    riwaya: Optional[str] = None
    password: Optional[str] = None  # Optional password for reset


class TeacherResponse(BaseModel):
    id: int
    user_id: int
    firstname: str
    lastname: str
    email: str
    riwaya: str
    hire_date: datetime
    is_active: bool
    registration_number: Optional[str] = None
    speciality: Optional[str] = None
    date_of_birth: Optional[str] = None
    place_of_birth: Optional[str] = None
    phone_number: Optional[str] = None
    address: Optional[str] = None
    medical_condition: Optional[str] = None

    class Config:
        from_attributes = True


class TeacherList(BaseModel):
    teachers: list[TeacherResponse]
    total: int
