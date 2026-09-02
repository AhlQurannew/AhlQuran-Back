from sqlalchemy import (
    String,
    DateTime,
    ForeignKey,
    Integer,
    Text,
    Enum as SQLEnum,
)

from sqlalchemy.orm import (
    Mapped,
    mapped_column,
    relationship,
)

from app.db.base import Base

from datetime import datetime, timezone

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
# Achievement Model
# ============================================================

class Achievement(Base):

    __tablename__ = "achievements"


    # ========================================================
    # ID
    # ========================================================

    id: Mapped[int] = mapped_column(
        primary_key=True,
        index=True,
    )


    # ========================================================
    # Student
    # ========================================================

    student_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey(
            "students.id",
            ondelete="CASCADE",
        ),
        nullable=False,
        index=True,
    )


    # ========================================================
    # Lecture / Halqa
    #
    # ⭐ NEW
    # ========================================================

    # Lecture / Halqa
    lecture_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey(
        "lectures.id",
        ondelete="SET NULL",
        ),
        nullable=True,
        index=True,
)


    # ========================================================
    # President / Multi-tenancy
    # ========================================================

    president_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey(
            "presidents.id",
            ondelete="CASCADE",
        ),
        nullable=True,
        index=True,
    )


    # ========================================================
    # Quran
    # ========================================================

    from_surah: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    to_surah: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    from_verse: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )

    to_verse: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )


    # ========================================================
    # Achievement information
    # ========================================================

    note: Mapped[Optional[str]] = mapped_column(
        Text,
        nullable=True,
    )


    achievement_type: Mapped[AchievementType] = mapped_column(
        SQLEnum(
            AchievementType,
            values_callable=lambda x: [
                e.value for e in x
            ],
        ),
        default=AchievementType.NORMAL,
        nullable=False,
    )


    # ========================================================
    # Date
    # Format: DD-MM-YYYY
    # ========================================================

    date: Mapped[Optional[str]] = mapped_column(
        String(10),
        nullable=True,
        index=True,
    )


    # ========================================================
    # Timestamps
    # ========================================================

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )


    updated_at: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True),
        onupdate=lambda: datetime.now(timezone.utc),
    )


    # ========================================================
    # Relationships
    # ========================================================

    president: Mapped[Optional["President"]] = relationship(
        "President",
        foreign_keys=[president_id],
    )


    student: Mapped["Student"] = relationship(
        "Student",
        foreign_keys=[student_id],
    )


    # ⭐ NEW: Achievement -> Lecture

    lecture: Mapped[Optional["Lecture"]] = relationship(
        "Lecture",
        foreign_keys=[lecture_id],
    )


    # ========================================================
    # Representation
    # ========================================================

    def __repr__(self) -> str:

        return (
            f"Achievement("
            f"id={self.id}, "
            f"student_id={self.student_id}, "
            f"lecture_id={self.lecture_id}, "
            f"surah={self.from_surah}:{self.from_verse}"
            f"-{self.to_surah}:{self.to_verse}, "
            f"type={self.achievement_type}"
            f")"
        )