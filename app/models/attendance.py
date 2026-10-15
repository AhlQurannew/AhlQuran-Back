from sqlalchemy import Date, DateTime, ForeignKey, Integer, Text, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from datetime import date as date_type, datetime, timezone
from typing import Optional
from enum import Enum


class AttendanceStatus(str, Enum):
    PRESENT = "present"
    LATE = "late"
    ABSENT = "absent"
    EXCUSED = "excused"
    
    def __str__(self):
        return self.value


class Attendance(Base):
    __tablename__ = "attendances"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    student_id: Mapped[int] = mapped_column(Integer, ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    
    # Multi-tenancy: Link to president
    president_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("presidents.id", ondelete="CASCADE"), nullable=True, index=True)

    lecture_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("lectures.id", ondelete="SET NULL"), nullable=True, index=True)

    date: Mapped[date_type] = mapped_column(Date, nullable=False, index=True)
    status: Mapped[AttendanceStatus] = mapped_column(
        SQLEnum(AttendanceStatus, values_callable=lambda x: [e.value for e in x]),
        default=AttendanceStatus.PRESENT,
        nullable=False
    )
    notes: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    president: Mapped[Optional["President"]] = relationship("President", foreign_keys=[president_id])
    
    student: Mapped["Student"] = relationship(
        "Student",
        foreign_keys=[student_id]
    )
    lecture: Mapped[Optional["Lecture"]] = relationship("Lecture")

    def __repr__(self) -> str:
        return f"Attendance(id={self.id}, student_id={self.student_id}, lecture_id={self.lecture_id}, date={self.date}, status={self.status})"
