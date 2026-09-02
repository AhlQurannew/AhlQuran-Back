from sqlalchemy import String, DateTime, ForeignKey, Integer, Text, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from datetime import datetime, timezone
from typing import Optional
from enum import Enum


class TeacherAttendanceStatus(str, Enum):
    PRESENT = "present"
    LATE = "late"
    ABSENT = "absent"
    EXCUSED = "excused"
    
    def __str__(self):
        return self.value


class TeacherAttendance(Base):
    __tablename__ = "teacher_attendances"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    teacher_id: Mapped[int] = mapped_column(Integer, ForeignKey("teachers.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Multi-tenancy: Link to president
    president_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("presidents.id", ondelete="CASCADE"), nullable=True, index=True)
    
    date: Mapped[str] = mapped_column(String(10), nullable=False, index=True)  # Format: DD-MM-YYYY
    status: Mapped[str] = mapped_column(
        String(20),
        default="present",
        nullable=False
    )
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    president: Mapped[Optional["President"]] = relationship("President", foreign_keys=[president_id])
    
    teacher: Mapped["Teacher"] = relationship(
        "Teacher",
        foreign_keys=[teacher_id]
    )

    def __repr__(self) -> str:
        return f"TeacherAttendance(id={self.id}, teacher_id={self.teacher_id}, date={self.date}, status={self.status})"
