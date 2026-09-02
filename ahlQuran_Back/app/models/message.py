from sqlalchemy import String, DateTime, ForeignKey, Integer, Text, Enum as SQLEnum
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
from datetime import datetime, timezone
from typing import Optional
from enum import Enum


class SenderRole(str, Enum):
    TEACHER = "teacher"
    SUPERVISOR = "supervisor"
    PRESIDENT = "president"
    
    def __str__(self):
        return self.value


class Message(Base):
    __tablename__ = "messages"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # Sender information
    sender_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"))
    sender_name: Mapped[str] = mapped_column(String(255), nullable=False)
    sender_role: Mapped[SenderRole] = mapped_column(
        SQLEnum(SenderRole, values_callable=lambda x: [e.value for e in x]),
        nullable=False,
        index=True
    )
    
    # Multi-tenancy: Link to president
    president_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("presidents.id", ondelete="CASCADE"), nullable=True, index=True)
    
    # Message content
    message: Mapped[str] = mapped_column(Text, nullable=False)
    
    # Timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        default=lambda: datetime.now(timezone.utc),
        index=True
    )

    # Relationships
    president: Mapped[Optional["President"]] = relationship("President", foreign_keys=[president_id])
    sender: Mapped["User"] = relationship("User", foreign_keys=[sender_id])

    def __repr__(self) -> str:
        return f"Message(id={self.id}, sender={self.sender_name}, role={self.sender_role}, time={self.created_at})"
