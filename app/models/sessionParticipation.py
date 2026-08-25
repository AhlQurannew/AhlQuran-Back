from sqlalchemy import String, Integer, ForeignKey, DateTime, Text, Float, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from typing import Optional
from enum import Enum

from app.db.base import Base


class ParticipationStatus(str, Enum):

    PRESENT = "present"           # Student attended
    ABSENT = "absent"             # Student didn't attend
    EXCUSED = "excused"           # Absent with valid reason
    LATE = "late"                 # Arrived late
    LEFT_EARLY = "left_early"     # Left before session ended


class SessionParticipation(Base):
    """
    Association table tracking student participation in sessions
    Each record represents ONE student's participation in ONE session
    """
    __tablename__ = "session_participations"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # Foreign Keys
    student_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    session_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("sessions.id", ondelete="CASCADE"),
        nullable=True,
        index=True
    )
    
    lecture_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("lectures.id", ondelete="SET NULL"),
        nullable=True,
        index=True
    )
    
    # Attendance tracking
    status: Mapped[ParticipationStatus] = mapped_column(
        SQLEnum(ParticipationStatus),
        default=ParticipationStatus.PRESENT,
        nullable=False
    )
    
    # Performance tracking
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)  # Teacher's notes about this student
    score: Mapped[Optional[float]] = mapped_column(Float, nullable=True)  # Score/grade (0-100)
    
    # Recitation tracking (Quran-specific)
    verses_recited: Mapped[Optional[str]] = mapped_column(String(100))  # e.g., "Al-Baqarah 1-10"
    mistakes_count: Mapped[Optional[int]] = mapped_column(Integer, default=0)
    
    # Memorization tracking
    memorized_verses: Mapped[Optional[str]] = mapped_column(String(100))
    revision_verses: Mapped[Optional[str]] = mapped_column(String(100))
    
    # Behavior & engagement
    behavior_rating: Mapped[Optional[int]] = mapped_column(Integer)  # 1-5 scale
    participation_level: Mapped[Optional[int]] = mapped_column(Integer)  # 1-5 scale
    
    # Timestamps
    marked_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))
    
    # Who recorded this participation
    recorded_by_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True
    )
    
    # Relationships
    student: Mapped["Student"] = relationship(
        "Student",
        back_populates="participations",
        foreign_keys=[student_id]
    )
    
    session: Mapped[Optional["Session"]] = relationship(
        "Session",
        back_populates="participations",
        foreign_keys=[session_id]
    )
    
    recorded_by: Mapped[Optional["User"]] = relationship(
        "User",
        foreign_keys=[recorded_by_id]
    )
    
    lecture: Mapped[Optional["Lecture"]] = relationship(
        "Lecture",
        back_populates="participations",
        foreign_keys=[lecture_id]
    )
    
    def __repr__(self) -> str:
        return f"SessionParticipation(student_id={self.student_id}, session_id={self.session_id}, status={self.status})"