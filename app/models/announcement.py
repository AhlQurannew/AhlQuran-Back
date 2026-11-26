"""Platform announcements (إعلانات) written by the administrator or an inspector.

`audience` lists the school roles that see the announcement; administrators and inspectors always
see every announcement since they manage them.
"""
from datetime import datetime, timezone
from typing import List, Optional

from sqlalchemy import BigInteger, DateTime, ForeignKey, String, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

AUDIENCE_KEYS = ("chief_supervisor", "supervisor", "teacher", "inspector")


class Announcement(Base):
    __tablename__ = "announcements"

    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(200), nullable=False)
    body: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    audience: Mapped[List[str]] = mapped_column(ARRAY(String(30)), nullable=False)
    author_admin_id: Mapped[Optional[int]] = mapped_column(ForeignKey("admins.id", ondelete="SET NULL"), nullable=True, index=True)
    author_name: Mapped[str] = mapped_column(String(200), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, index=True, default=lambda: datetime.now(timezone.utc)
    )

    attachments: Mapped[List["AnnouncementAttachment"]] = relationship(
        back_populates="announcement", cascade="all, delete-orphan", order_by="AnnouncementAttachment.id"
    )


class AnnouncementAttachment(Base):
    __tablename__ = "announcement_attachments"

    id: Mapped[int] = mapped_column(primary_key=True)
    announcement_id: Mapped[int] = mapped_column(ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False, index=True)
    storage_path: Mapped[str] = mapped_column(String(512), nullable=False, unique=True)
    filename: Mapped[str] = mapped_column(String(255), nullable=False)
    content_type: Mapped[str] = mapped_column(String(127), nullable=False)
    size: Mapped[int] = mapped_column(BigInteger, nullable=False)

    announcement: Mapped[Announcement] = relationship(back_populates="attachments")
