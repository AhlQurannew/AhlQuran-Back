from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, text
# from sqlalchemy.orm import relationship
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base
from datetime import datetime, timezone
from typing import Optional

class Admin(Base):
    __tablename__ = "admins"
    __table_args__ = (
        Index("uq_admins_email_lower", text("lower(email)"), unique=True),
    )

    id : Mapped[int] = mapped_column(primary_key=True, index=True)
    user : Mapped[str] = mapped_column(String, unique=True, index=True)
    email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    email_verified_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    password_hash: Mapped[str] = mapped_column("password", String)
    
    # "admin" (full control) or "inspector" (مفتش: same access, created by an admin, cannot edit the site)
    role : Mapped[str] = mapped_column(String, default="admin")
    full_name: Mapped[Optional[str]] = mapped_column(String(150), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true", nullable=False)
    auth_version: Mapped[int] = mapped_column(default=0, server_default="0", nullable=False)

    created_by_id: Mapped[Optional[int]] = mapped_column(ForeignKey("admins.id", ondelete="CASCADE"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True) , default=lambda: datetime.now(timezone.utc))
     

    @property
    def is_inspector(self) -> bool:
        return (self.role or "admin") == "inspector"

    def __repr__(self):
        return f"<Admin(id={self.id}, user={self.user})>"
