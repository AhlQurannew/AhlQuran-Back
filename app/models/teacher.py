from sqlalchemy import String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from typing import Optional

from app.db.base import Base

class Teacher(Base):
    __tablename__ = "teachers"
    
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
    
    # Teacher-specific fields
    riwaya: Mapped[str] = mapped_column(String(100), nullable=False)
    hire_date: Mapped[datetime] = mapped_column(DateTime(timezone=True) , default=lambda: datetime.now(timezone.utc))
    created_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    
    # Relationships - USE STRING REFERENCES with foreign_keys
    user: Mapped["User"] = relationship(
        "User",  # ← String reference
        back_populates="teacher",
        foreign_keys=[user_id]  # ← Use list
    )
    
    created_by: Mapped[Optional["User"]] = relationship(
        "User",  # ← String reference
        foreign_keys=[created_by_id]  # ← Use list
    )
    
    lectures: Mapped[list["Lecture"]] = relationship(
        "Lecture",
        secondary="lecture_teachers",
        back_populates="teachers"
    )
    
    president: Mapped["President"] = relationship(
        "President",
        foreign_keys=[president_id]
    )
    
    def __repr__(self) -> str:
        return f"Teacher(id={self.id}, user_id={self.user_id}, president_id={self.president_id})"