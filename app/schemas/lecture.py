from pydantic import BaseModel, Field
from typing import Optional, List
from datetime import datetime


# Teacher schema for nested response
class TeacherInfo(BaseModel):
    teacher_id: int
    
    class Config:
        from_attributes = True


class TeacherResponse(BaseModel):
    teacher_id: int
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    
    class Config:
        from_attributes = True


# Weekly Schedule schemas
class WeeklyScheduleBase(BaseModel):
    day_of_week: str = Field(..., description="Day of the week (e.g., 'Friday', 'Monday')")
    start_time: str = Field(..., pattern=r"^\d{2}:\d{2}$", description="Start time in HH:MM format")
    end_time: str = Field(..., pattern=r"^\d{2}:\d{2}$", description="End time in HH:MM format")


class WeeklyScheduleCreate(WeeklyScheduleBase):
    pass


class WeeklyScheduleUpdate(WeeklyScheduleBase):
    weekly_schedule_id: Optional[int] = None


class WeeklyScheduleResponse(WeeklyScheduleBase):
    weekly_schedule_id: int
    lecture_id: int
    
    class Config:
        from_attributes = True


# Lecture schemas
class LectureBase(BaseModel):
    lecture_name_ar: str = Field(..., min_length=1, max_length=200, description="Arabic name of the lecture")
    lecture_name_en: str = Field(..., min_length=1, max_length=200, description="English name of the lecture")
    circle_type: str = Field(..., description="Type: 'memorization and revision' or 'other'")
    category: str = Field(..., description="Category: 'male', 'female', or 'both'")
    shown_on_website: bool = Field(default=False, description="Whether to show on website")


class LectureInfo(LectureBase):
    lecture_id: Optional[int] = None


class LectureCreate(BaseModel):
    lecture: LectureInfo
    teachers: List[TeacherInfo] = Field(default_factory=list, description="List of teacher IDs")
    schedules: List[WeeklyScheduleCreate] = Field(..., min_length=1, description="At least one schedule required")


class LectureUpdate(BaseModel):
    lecture: LectureInfo
    teachers: List[TeacherInfo] = Field(default_factory=list)
    schedules: List[WeeklyScheduleUpdate] = Field(..., min_length=1)


class LectureResponse(BaseModel):
    lecture_id: int
    lecture_name_ar: str
    lecture_name_en: str
    circle_type: str
    category: str
    shown_on_website: bool
    teachers: List[TeacherResponse] = []
    schedules: List[WeeklyScheduleResponse] = []
    student_count: int = 0
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class LectureListResponse(BaseModel):
    lectures: List[LectureResponse]
    total: int
