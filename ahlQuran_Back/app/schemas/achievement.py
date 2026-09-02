from pydantic import BaseModel, Field

from datetime import datetime

from typing import Optional

from enum import Enum


# ============================================================
# Achievement Type
# ============================================================

class AchievementType(str, Enum):

    NORMAL = "normal"

    SMALL = "small"

    BIG = "big"

    def __str__(self):
        return self.value


# ============================================================
# Base
# ============================================================

class AchievementBase(BaseModel):

    from_surah: int = Field(
        ...,
        ge=1,
        le=114,
        example=2,
        description="Chapter number 1-114",
    )

    to_surah: int = Field(
        ...,
        ge=1,
        le=114,
        example=2,
        description="Chapter number 1-114",
    )

    from_verse: int = Field(
        ...,
        gt=0,
        example=1,
    )

    to_verse: int = Field(
        ...,
        gt=0,
        example=10,
    )

    note: Optional[str] = Field(
        None,
        example="Good memorization",
    )

    achievement_type: AchievementType = Field(
        default=AchievementType.NORMAL,
        example="normal",
    )

    date: Optional[str] = Field(
        None,
        description="Date in DD-MM-YYYY format",
        example="19-12-2024",
    )


# ============================================================
# Create
# ============================================================

class AchievementCreate(AchievementBase):

    student_id: int = Field(
        ...,
        gt=0,
        example=1,
    )

    # ⭐ NEW
    # Lecture selected from the frontend

    lecture_id: int = Field(
        ...,
        gt=0,
        example=3,
        description="ID of the lecture / halqa",
    )


# ============================================================
# Update
# ============================================================

class AchievementUpdate(BaseModel):

    from_surah: Optional[int] = Field(
        None,
        ge=1,
        le=114,
    )

    to_surah: Optional[int] = Field(
        None,
        ge=1,
        le=114,
    )

    from_verse: Optional[int] = Field(
        None,
        gt=0,
    )

    to_verse: Optional[int] = Field(
        None,
        gt=0,
    )

    note: Optional[str] = None

    achievement_type: Optional[AchievementType] = None

    date: Optional[str] = Field(
        None,
        description="Date in DD-MM-YYYY format",
    )

    # ⭐ NEW
    #
    # Optional for update because:
    # - if omitted -> keep old lecture
    # - if number -> change lecture
    # - if null -> remove lecture

    lecture_id: Optional[int] = Field(
        None,
        gt=0,
        description="ID of the lecture / halqa",
    )


# ============================================================
# Response
# ============================================================

class AchievementResponse(AchievementBase):

    id: int

    student_id: int

    # ⭐ NEW

    lecture_id: Optional[int] = None

    created_at: datetime

    updated_at: Optional[datetime] = None


    class Config:

        from_attributes = True


# ============================================================
# List
# ============================================================

class AchievementList(BaseModel):

    achievements: list[AchievementResponse]

    total: int