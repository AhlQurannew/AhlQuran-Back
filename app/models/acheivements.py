from sqlalchemy import String, DateTime, ForeignKey, Integer, Text, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from datetime import datetime, timezone
from typing import Optional
from enum import Enum

class AchievementType(str, Enum):
    NORMAL = "normal"
    SMALL = "small"
    BIG = "big"
    
    def __str__(self):
        return self.value

class Achievement(Base):
    __tablename__ = "achievements"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"))
    
    # Multi-tenancy: Link to president
    president_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("presidents.id", ondelete="CASCADE"), nullable=True, index=True)

    from_surah: Mapped[int] = mapped_column(Integer, nullable=False)  # Changed to chapter number
    to_surah: Mapped[int] = mapped_column(Integer, nullable=False)    # Changed to chapter number
    from_verse: Mapped[int] = mapped_column(Integer, nullable=False)
    to_verse: Mapped[int] = mapped_column(Integer, nullable=False)

    note: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    achievement_type: Mapped[AchievementType] = mapped_column(
        SQLEnum(AchievementType, values_callable=lambda x: [e.value for e in x]),
        default=AchievementType.NORMAL,
        nullable=False
    )
    date: Mapped[Optional[str]] = mapped_column(String(10), nullable=True, index=True)  # Format: DD-MM-YYYY

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    president: Mapped[Optional["President"]] = relationship("President", foreign_keys=[president_id])
    
    student: Mapped["Student"] = relationship(
        "Student",
        foreign_keys=[student_id]
    )

    def __repr__(self) -> str:
        return f"Achievement(id={self.id}, student_id={self.student_id}, surah {self.from_surah}:{self.from_verse} - {self.to_surah}:{self.to_verse}, type={self.achievement_type})"
