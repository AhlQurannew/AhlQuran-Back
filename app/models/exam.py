from datetime import date, datetime, timezone
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Exam(Base):
    """An exam held for one circle (halaqa); its results rank the students who sat it."""

    __tablename__ = "exams"

    id: Mapped[int] = mapped_column(primary_key=True)
    president_id: Mapped[int] = mapped_column(ForeignKey("presidents.id", ondelete="CASCADE"), nullable=False, index=True)
    lecture_id: Mapped[int] = mapped_column(ForeignKey("lectures.id", ondelete="CASCADE"), nullable=False, index=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    exam_type: Mapped[Optional[str]] = mapped_column(String(50))  # monthly | term | final | tajwid | other
    exam_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    max_mark: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False, default=Decimal("20"), server_default="20")
    pass_mark: Mapped[Decimal] = mapped_column(Numeric(6, 2), nullable=False, default=Decimal("10"), server_default="10")
    notes: Mapped[Optional[str]] = mapped_column(Text)
    created_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))

    lecture: Mapped["Lecture"] = relationship("Lecture")
    results: Mapped[List["ExamResult"]] = relationship(
        "ExamResult", back_populates="exam", cascade="all, delete-orphan", passive_deletes=True,
    )


class ExamResult(Base):
    """One student's sitting of an exam: attendance, mark (when present) and teacher notes."""

    __tablename__ = "exam_results"
    __table_args__ = (UniqueConstraint("exam_id", "student_id", name="uq_exam_results_exam_student"),)

    id: Mapped[int] = mapped_column(primary_key=True)
    exam_id: Mapped[int] = mapped_column(ForeignKey("exams.id", ondelete="CASCADE"), nullable=False, index=True)
    student_id: Mapped[int] = mapped_column(ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    attendance: Mapped[str] = mapped_column(String(20), nullable=False, default="present", server_default="present")  # present | absent | excused
    mark: Mapped[Optional[Decimal]] = mapped_column(Numeric(6, 2))
    notes: Mapped[Optional[str]] = mapped_column(Text)
    updated_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), onupdate=lambda: datetime.now(timezone.utc))

    exam: Mapped["Exam"] = relationship("Exam", back_populates="results")
    student: Mapped["Student"] = relationship("Student")
