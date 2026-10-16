from sqlalchemy import String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from app.db.base import Base

class ChiefSupervisor(Base):
    __tablename__ = "chief_supervisors"
    
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
    
    # Chief Supervisor-specific fields
    created_by_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    
    # Relationships
    user: Mapped["User"] = relationship(
        "User",
        back_populates="chief_supervisor",
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
        return f"ChiefSupervisor(id={self.id}, user_id={self.user_id}, president_id={self.president_id})"
