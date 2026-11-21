from pydantic import BaseModel, Field, field_validator
from app.schemas.dates import checked_text_date
from typing import Literal, Optional
from datetime import datetime


TeacherAttendanceStatus = Literal["present", "late", "absent", "excused"]


class TeacherAttendanceBase(BaseModel):
    teacher_id: Optional[int] = None  # Made optional since it's in the URL
    date: str = Field(..., description="Date in DD-MM-YYYY format")
    status: str = Field(..., description="Attendance status: present, late, absent, excused")
    notes: Optional[str] = None


class TeacherAttendanceCreate(TeacherAttendanceBase):
    status: TeacherAttendanceStatus

    @field_validator("date")
    @classmethod
    def real_date(cls, value: str) -> str:
        checked = checked_text_date(value)
        if checked is None:
            raise ValueError("Invalid date")
        return checked

    pass


class TeacherAttendanceUpdate(BaseModel):
    date: Optional[str] = None

    @field_validator("date")
    @classmethod
    def real_date(cls, value: Optional[str]) -> Optional[str]:
        return checked_text_date(value)

    status: Optional[TeacherAttendanceStatus] = None
    notes: Optional[str] = None


class TeacherAttendanceResponse(TeacherAttendanceBase):
    id: int
    teacher_id: int  # Always present in response
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class TeacherAttendanceList(BaseModel):
    attendances: list[TeacherAttendanceResponse]
    total: int
