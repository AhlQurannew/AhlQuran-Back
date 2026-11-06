from datetime import datetime, timezone
from decimal import Decimal
from typing import List, Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class Speciality(Base):
    """A study track (تخصص) of a school, e.g. Fiqh, Tilawa or the common core (جذع مشترك).

    It groups circles (halaqat); a circle may belong to several specialities. Students
    assigned to a speciality are enrolled in all of its circles.
    """

    __tablename__ = "specialities"

    id: Mapped[int] = mapped_column(primary_key=True)
    president_id: Mapped[int] = mapped_column(ForeignKey("presidents.id", ondelete="CASCADE"), nullable=False, index=True)
    name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[Optional[str]] = mapped_column(Text)
    is_common: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")  # tronc commun
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    lectures: Mapped[List["SpecialityLecture"]] = relationship(
        "SpecialityLecture", back_populates="speciality", cascade="all, delete-orphan", passive_deletes=True,
    )


class SpecialityLecture(Base):
    """A circle inside a speciality, with its coefficient (used for exams later)."""

    __tablename__ = "speciality_lectures"

    speciality_id: Mapped[int] = mapped_column(ForeignKey("specialities.id", ondelete="CASCADE"), primary_key=True)
    lecture_id: Mapped[int] = mapped_column(ForeignKey("lectures.id", ondelete="CASCADE"), primary_key=True)
    coefficient: Mapped[Decimal] = mapped_column(Numeric(5, 2), nullable=False, default=Decimal("1"), server_default="1")

    speciality: Mapped["Speciality"] = relationship("Speciality", back_populates="lectures")
    lecture: Mapped["Lecture"] = relationship("Lecture")
