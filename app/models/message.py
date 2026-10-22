from datetime import datetime, timezone
from enum import Enum
from typing import TYPE_CHECKING, Optional

from sqlalchemy import BigInteger, CheckConstraint, DateTime, Enum as SQLEnum, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

if TYPE_CHECKING:
    from app.models.admin import Admin
    from app.models.president import President
    from app.models.user import User


class SenderRole(str, Enum):
    TEACHER = "teacher"
    SUPERVISOR = "supervisor"
    CHIEF_SUPERVISOR = "chief_supervisor"
    PRESIDENT = "president"
    STUDENT = "student"
    GUARDIAN = "guardian"
    ADMIN = "admin"
    
    def __str__(self):
        return self.value


class Message(Base):
    __tablename__ = "messages"
    __table_args__ = (
        CheckConstraint(
            "(sender_id IS NOT NULL AND admin_sender_id IS NULL) OR "
            "(sender_id IS NULL AND admin_sender_id IS NOT NULL)",
            name="ck_messages_exactly_one_sender",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    
    # Sender information
    sender_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    admin_sender_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("admins.id", ondelete="CASCADE"),
        nullable=True,
        index=True,
    )
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
    sender: Mapped[Optional["User"]] = relationship("User", foreign_keys=[sender_id])
    admin_sender: Mapped[Optional["Admin"]] = relationship("Admin", foreign_keys=[admin_sender_id])
    attachments: Mapped[list["MessageAttachment"]] = relationship(
        "MessageAttachment",
        back_populates="message_record",
        cascade="all, delete-orphan",
        passive_deletes=True,
    )

    def __repr__(self) -> str:
        return f"Message(id={self.id}, sender={self.sender_name}, role={self.sender_role}, time={self.created_at})"


class MessageAttachment(Base):
    __tablename__ = "message_attachments"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    message_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("messages.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    storage_path: Mapped[str] = mapped_column(String(512), nullable=False, unique=True)
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    content_type: Mapped[str] = mapped_column(String(127), nullable=False)
    size: Mapped[int] = mapped_column(BigInteger, nullable=False)

    message_record: Mapped["Message"] = relationship("Message", back_populates="attachments")
