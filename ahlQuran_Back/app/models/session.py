from sqlalchemy import String, Integer, ForeignKey, DateTime, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from typing import Optional, List

from app.db.base import Base


class Session(Base):
    """
    Represents a learning session (class/lecture/study group)
    Can have MULTIPLE students participating
    """
    __tablename__ = "sessions"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # Who's managing/teaching this session
    teacher_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    
    # Session details
    session_date: Mapped[datetime] = mapped_column(DateTime, default=datetime.now(timezone.utc))
    session_time: Mapped[str] = mapped_column(String(20))  # e.g., "09:00-10:30"
    duration_minutes: Mapped[int] = mapped_column(Integer, nullable=False)
    topic: Mapped[str] = mapped_column(String(200))  # e.g., "Surah Al-Baqarah 1-20"
    description: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    location: Mapped[Optional[str]] = mapped_column(String(100))  # e.g., "Room 101"
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True) , default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime, onupdate=datetime.now(timezone.utc))
    
    # Relationships
    teacher: Mapped[Optional["User"]] = relationship(
        "User",
        foreign_keys=[teacher_id]
    )
    
    # Many-to-Many relationship with Students through SessionParticipation
    participations: Mapped[List["SessionParticipation"]] = relationship(
        "SessionParticipation",
        back_populates="session",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self) -> str:
        return f"Session(id={self.id}, topic='{self.topic}', date={self.session_date})"