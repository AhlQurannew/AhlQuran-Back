from sqlalchemy import String, Integer, ForeignKey, DateTime, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from typing import Optional, List

from app.db.base import Base


class Student(Base):
    __tablename__ = "students"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False
    )
    president_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("presidents.id", ondelete="CASCADE"),
        nullable=False,
        index=True
    )
    
    # Student-specific fields
    enrollment_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    parent_name: Mapped[Optional[str]] = mapped_column(String(255))
    parent_phone: Mapped[Optional[str]] = mapped_column(String(20)) 
    guardian_email: Mapped[Optional[str]] = mapped_column(String(255))
    created_by_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"))
    Golden: Mapped[Optional[bool]] = mapped_column(Boolean, default=False)
    
    # New Fields
    sex: Mapped[Optional[str]] = mapped_column(String(10))
    date_of_birth: Mapped[Optional[str]] = mapped_column(String(20))
    place_of_birth: Mapped[Optional[str]] = mapped_column(String(100))
    home_address: Mapped[Optional[str]] = mapped_column(String(255))
    nationality: Mapped[Optional[str]] = mapped_column(String(50))
    
    # English name fields
    first_name_en: Mapped[Optional[str]] = mapped_column(String(50))
    last_name_en: Mapped[Optional[str]] = mapped_column(String(50))
    
    # Parent status fields
    father_status: Mapped[Optional[str]] = mapped_column(String(50))
    mother_status: Mapped[Optional[str]] = mapped_column(String(50))
    
    academic_level: Mapped[Optional[str]] = mapped_column(String(50))
    grade: Mapped[Optional[str]] = mapped_column(String(50))
    school_name: Mapped[Optional[str]] = mapped_column(String(100))
    
    guardian_id: Mapped[Optional[int]] = mapped_column(Integer)
    notes: Mapped[Optional[str]] = mapped_column(String(1000), nullable=True)
    
    # Many-to-Many relationship with Sessions through SessionParticipation
    participations: Mapped[List["SessionParticipation"]] = relationship(
        "SessionParticipation",
        back_populates="student",
        cascade="all, delete-orphan"
    )
    
    # Achievements relationship
    achievements: Mapped[List["Achievement"]] = relationship(
        "Achievement",
        back_populates="student",
        cascade="all, delete-orphan",
        foreign_keys="Achievement.student_id"
    )

    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="student",
        foreign_keys=[user_id]
    )
    
    created_by: Mapped["User"] = relationship(
        "User",
        foreign_keys=[created_by_id]
    )
    
    president: Mapped["President"] = relationship(
        "President",
        foreign_keys=[president_id]
    )
    
    def __repr__(self) -> str:
        return f"Student(id={self.id}, user_id={self.user_id}, president_id={self.president_id})"
