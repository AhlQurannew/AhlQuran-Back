from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class AttendanceStatus(str, Enum):
    PRESENT = "present"
    LATE = "late"
    ABSENT = "absent"
    EXCUSED = "excused"
    
    def __str__(self):
        return self.value


class AttendanceBase(BaseModel):
    date: str = Field(..., pattern=r'^\d{2}-\d{2}-\d{4}$', example="17-12-2024")  # DD-MM-YYYY
    status: AttendanceStatus = Field(default=AttendanceStatus.PRESENT, example="present")
    notes: Optional[str] = Field(None, example="Good attendance")


class AttendanceCreate(AttendanceBase):
    student_id: int = Field(..., gt=0, example=1)


class AttendanceUpdate(BaseModel):
    status: Optional[AttendanceStatus] = None
    notes: Optional[str] = None


class AttendanceResponse(AttendanceBase):
    id: int
    student_id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class AttendanceList(BaseModel):
    attendances: list[AttendanceResponse]
    total: int
