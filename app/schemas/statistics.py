from pydantic import BaseModel, Field
from typing import List


class StatsSummaryResponse(BaseModel):
    """Summary statistics response"""
    total_students: int = Field(..., description="Total number of students")
    total_teachers: int = Field(default=0, description="Total number of teachers")
    total_supervisors: int = Field(default=0, description="Total number of supervisors")
    present_today: int = Field(..., description="Number of students present today")
    total_pages_memorized: int = Field(..., description="Total pages memorized by all students")
    total_lectures: int = Field(..., description="Total number of lectures/circles")

    class Config:
        from_attributes = True


class AttendanceRecordResponse(BaseModel):
    """Attendance trend record response"""
    date: str = Field(..., description="Date in DD-MM-YYYY format")
    present: int = Field(..., description="Number of students present")
    absent: int = Field(..., description="Number of students absent")
    total: int = Field(..., description="Total students counted")
    percentage: str = Field(..., description="Attendance percentage with % symbol")

    class Config:
        from_attributes = True


class MemorizationRecordResponse(BaseModel):
    """Top memorizer record response"""
    student: str = Field(..., description="Full name of the student")
    pages: int = Field(..., description="Number of pages/achievements")
    rank: int = Field(..., description="Rank position (1, 2, 3, etc.)")

    class Config:
        from_attributes = True


class LectureDistributionResponse(BaseModel):
    """Lecture distribution response"""
    className: str = Field(..., description="Arabic name of the lecture/circle")
    students: int = Field(..., description="Number of students in this lecture")
    percentage: str = Field(..., description="Percentage of total students with % symbol")

    class Config:
        from_attributes = True
