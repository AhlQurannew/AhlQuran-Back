from typing import Optional
from sqlalchemy import String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from app.db.base import Base

class Supervisor(Base):
    __tablename__ = "supervisors"
    
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
    
    # Supervisor-specific fields
    created_by_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True) , default=lambda: datetime.now(timezone.utc))
    
    # Relationships - USE STRING REFERENCES with foreign_keys
    user: Mapped["User"] = relationship(
        "User",  # ← String reference
        back_populates="supervisor",
        foreign_keys=[user_id]  # ← Use list, not string for this one
    )
    
    created_by: Mapped[Optional["User"]] = relationship(
        "User",  # ← String reference
        foreign_keys=[created_by_id]  # ← Use list
    )
    
    president: Mapped["President"] = relationship(
        "President",
        foreign_keys=[president_id]
    )
    
    def __repr__(self) -> str:
        return f"Supervisor(id={self.id}, user_id={self.user_id}, president_id={self.president_id})"