from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional
from enum import Enum


class AchievementType(str, Enum):
    NORMAL = "normal"
    SMALL = "small"
    BIG = "big"
    
    def __str__(self):
        return self.value


class AchievementBase(BaseModel):
    from_surah: int = Field(..., ge=1, le=114, example=2)  # Chapter number 1-114
    to_surah: int = Field(..., ge=1, le=114, example=2)    # Chapter number 1-114
    from_verse: int = Field(..., gt=0, example=1)
    to_verse: int = Field(..., gt=0, example=10)
    note: Optional[str] = Field(None, example="Good memorization")
    achievement_type: AchievementType = Field(default=AchievementType.NORMAL, example="normal")
    date: Optional[str] = Field(None, description="Date in DD-MM-YYYY format", example="19-12-2024")


class AchievementCreate(AchievementBase):
    student_id: int = Field(..., gt=0, example=1)


class AchievementUpdate(BaseModel):
    from_surah: Optional[int] = Field(None, ge=1, le=114)  # Chapter number 1-114
    to_surah: Optional[int] = Field(None, ge=1, le=114)    # Chapter number 1-114
    from_verse: Optional[int] = Field(None, gt=0)
    to_verse: Optional[int] = Field(None, gt=0)
    note: Optional[str] = None
    achievement_type: Optional[AchievementType] = None
    date: Optional[str] = Field(None, description="Date in DD-MM-YYYY format")


class AchievementResponse(AchievementBase):
    id: int
    student_id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True


class AchievementList(BaseModel):
    achievements: list[AchievementResponse]
    total: int

