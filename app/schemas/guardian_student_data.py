"""
Schemas for guardian student data access endpoints.
These models are used for the guardian achievement and attendance endpoints.
"""
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import date as DateType


class StudentContext(BaseModel):
    """Student information included in guardian data access responses."""
    id: int = Field(..., description="Student ID", example=1)
    name: str = Field(..., description="Student full name", example="John Doe")
    
    class Config:
        from_attributes = True


class GuardianAchievementResponse(BaseModel):
    """Single achievement record with student context for guardian access."""
    id: int = Field(..., description="Achievement ID")
    student: StudentContext = Field(..., description="Student information")
    from_surah: int = Field(..., ge=1, le=114, description="Starting surah (chapter) number")
    to_surah: int = Field(..., ge=1, le=114, description="Ending surah (chapter) number")
    from_verse: int = Field(..., gt=0, description="Starting verse number")
    to_verse: int = Field(..., gt=0, description="Ending verse number")
    note: Optional[str] = Field(None, description="Additional notes about the achievement")
    achievement_type: str = Field(..., description="Type of achievement (normal, small, big)")
    date: str = Field(..., description="Achievement date in DD-MM-YYYY format", example="19-12-2024")
    
    class Config:
        from_attributes = True


class PaginatedAchievementsResponse(BaseModel):
    """Paginated achievement results for guardian access."""
    items: List[GuardianAchievementResponse] = Field(..., description="List of achievements")
    total: int = Field(..., description="Total number of achievements matching the query", example=100)
    page: int = Field(..., ge=1, description="Current page number", example=1)
    page_size: int = Field(..., ge=1, le=100, description="Number of items per page", example=50)
    total_pages: int = Field(..., ge=0, description="Total number of pages", example=2)


class GuardianAttendanceResponse(BaseModel):
    """Single attendance record with student context for guardian access."""
    id: int = Field(..., description="Attendance ID")
    student: StudentContext = Field(..., description="Student information")
    date: DateType = Field(..., description="Attendance date in ISO format", example="2026-10-15")
    lecture_id: Optional[int] = None
    status: str = Field(..., description="Attendance status (present, late, absent, excused)")
    notes: Optional[str] = Field(None, description="Additional notes about the attendance")
    
    class Config:
        from_attributes = True


class PaginatedAttendanceResponse(BaseModel):
    """Paginated attendance results for guardian access."""
    items: List[GuardianAttendanceResponse] = Field(..., description="List of attendance records")
    total: int = Field(..., description="Total number of attendance records matching the query", example=100)
    page: int = Field(..., ge=1, description="Current page number", example=1)
    page_size: int = Field(..., ge=1, le=100, description="Number of items per page", example=50)
    total_pages: int = Field(..., ge=0, description="Total number of pages", example=2)
