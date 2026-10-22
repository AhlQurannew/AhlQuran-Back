from pydantic import BaseModel, Field
from datetime import date as DateType, datetime
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
    date: DateType = Field(..., example="2026-10-15")
    status: AttendanceStatus = Field(default=AttendanceStatus.PRESENT, example="present")
    notes: Optional[str] = Field(None, example="Good attendance")


class AttendanceCreate(AttendanceBase):
    student_id: Optional[int] = Field(None, example=1)
    lecture_id: int = Field(..., gt=0)


class AttendanceUpdate(BaseModel):
    status: Optional[AttendanceStatus] = None
    notes: Optional[str] = None


class AttendanceResponse(AttendanceBase):
    id: int
    student_id: int
    lecture_id: Optional[int] = None
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class AttendanceList(BaseModel):
    attendances: list[AttendanceResponse]
    total: int


class AttendanceBulkRecord(BaseModel):
    student_id: int = Field(..., gt=0)
    status: Optional[AttendanceStatus] = None
    notes: Optional[str] = None


class AttendanceBulkSave(BaseModel):
    date: DateType
    records: list[AttendanceBulkRecord]
