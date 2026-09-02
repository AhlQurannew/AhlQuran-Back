from sqlalchemy import String, Integer, ForeignKey, DateTime, Boolean, Table, Column
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from typing import Optional, List

from app.db.base import Base


# Association table for many-to-many relationship between lectures and teachers
lecture_teachers = Table(
    'lecture_teachers',
    Base.metadata,
    Column('lecture_id', Integer, ForeignKey('lectures.id', ondelete='CASCADE'), primary_key=True),
    Column('teacher_id', Integer, ForeignKey('teachers.id', ondelete='CASCADE'), primary_key=True)
)


class Lecture(Base):
    """
    Represents a lecture/circle (حلقة)
    Can have multiple teachers and a weekly schedule
    """
    __tablename__ = "lectures"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # Multi-tenancy: Link to president
    president_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("presidents.id", ondelete="CASCADE"), nullable=True, index=True)
    
    # Lecture details
    lecture_name_ar: Mapped[str] = mapped_column(String(200), nullable=False)
    lecture_name_en: Mapped[str] = mapped_column(String(200), nullable=False)
    circle_type: Mapped[str] = mapped_column(String(100), nullable=False)  # "memorization and revision" or "other"
    category: Mapped[str] = mapped_column(String(50), nullable=False)  # "male", "female", or "both"
    shown_on_website: Mapped[bool] = mapped_column(Boolean, default=False)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))
    
    # Relationships
    president: Mapped[Optional["President"]] = relationship("President", foreign_keys=[president_id])
    
    teachers: Mapped[List["Teacher"]] = relationship(
        "Teacher",
        secondary=lecture_teachers,
        back_populates="lectures"
    )
    
    schedules: Mapped[List["WeeklySchedule"]] = relationship(
        "WeeklySchedule",
        back_populates="lecture",
        cascade="all, delete-orphan"
    )
    
    # Relationship to students (through session participation)
    participations: Mapped[List["SessionParticipation"]] = relationship(
        "SessionParticipation",
        back_populates="lecture",
        cascade="all, delete-orphan"
    )
    
    def __repr__(self) -> str:
        return f"Lecture(id={self.id}, name_ar='{self.lecture_name_ar}', type='{self.circle_type}')"


class WeeklySchedule(Base):
    """
    Represents a weekly schedule for a lecture
    """
    __tablename__ = "weekly_schedules"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    lecture_id: Mapped[int] = mapped_column(Integer, ForeignKey('lectures.id', ondelete='CASCADE'), nullable=False)
    
    # Schedule details
    day_of_week: Mapped[str] = mapped_column(String(20), nullable=False)  # "Sunday", "Monday", etc.
    start_time: Mapped[str] = mapped_column(String(10), nullable=False)  # "09:00"
    end_time: Mapped[str] = mapped_column(String(10), nullable=False)  # "11:00"
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Relationships
    lecture: Mapped["Lecture"] = relationship(
        "Lecture",
        back_populates="schedules"
    )
    
    def __repr__(self) -> str:
        return f"WeeklySchedule(id={self.id}, day='{self.day_of_week}', time='{self.start_time}-{self.end_time}')"
