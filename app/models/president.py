from sqlalchemy import String, ForeignKey, DateTime, Boolean, func, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime
from typing import Optional

from app.db.base import Base


class President(Base):
    __tablename__ = "presidents"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True, index=True)

    # President-specific fields
    school_name: Mapped[str] = mapped_column(String(100), nullable=False)
    phone_number: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)
    approval_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    approved_by: Mapped[Optional[int]] = mapped_column(ForeignKey("admins.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    is_verified: Mapped[bool] = mapped_column(Boolean, default=False, server_default='false')

    # Relationships
    user: Mapped["User"] = relationship(back_populates="president")
    admin: Mapped[Optional["Admin"]] = relationship("Admin", foreign_keys=[approved_by])

    def __repr__(self) -> str:
        return f"President(id={self.id}, school={self.school_name}, verified={self.is_verified})"
