from pydantic import BaseModel, Field, field_validator, model_validator
from datetime import datetime
from typing import Optional
from enum import Enum

from app.core.quran_thumn import WARSH_VERSE_COUNTS
from app.schemas.dates import checked_text_date


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


class _NewAchievementRules(BaseModel):
    """Checks for new records only; older ones may hold verse numbers from before the switch to Warsh."""

    @field_validator("date", check_fields=False)
    @classmethod
    def real_date(cls, value: Optional[str]) -> Optional[str]:
        return checked_text_date(value)

    @model_validator(mode="after")
    def verses_exist(self):
        if self.from_verse > WARSH_VERSE_COUNTS[self.from_surah - 1] or self.to_verse > WARSH_VERSE_COUNTS[self.to_surah - 1]:
            raise ValueError("This verse does not exist in the surah")
        # A surah may be listed backwards (reverse memorization), but not its verses.
        if self.from_surah == self.to_surah and self.to_verse < self.from_verse:
            raise ValueError("The last verse comes before the first verse")
        return self


class AchievementCreate(_NewAchievementRules, AchievementBase):
    student_id: Optional[int] = Field(None, gt=0, example=1)


class AchievementBulkCreate(_NewAchievementRules, AchievementBase):
    student_ids: list[int] = Field(..., min_length=1, max_length=10000)
    lecture_id: Optional[int] = Field(None, gt=0)


class AchievementUpdate(BaseModel):
    from_surah: Optional[int] = Field(None, ge=1, le=114)  # Chapter number 1-114
    to_surah: Optional[int] = Field(None, ge=1, le=114)    # Chapter number 1-114
    from_verse: Optional[int] = Field(None, gt=0)
    to_verse: Optional[int] = Field(None, gt=0)
    note: Optional[str] = None
    achievement_type: Optional[AchievementType] = None
    date: Optional[str] = Field(None, description="Date in DD-MM-YYYY format")

    @field_validator("date")
    @classmethod
    def real_date(cls, value: Optional[str]) -> Optional[str]:
        return checked_text_date(value)


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
