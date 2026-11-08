from datetime import datetime, timezone

from sqlalchemy import Boolean, DateTime, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class LoginSlide(Base):
    """An image shown on the public login page; several slides rotate as a slideshow."""

    __tablename__ = "login_slides"

    id: Mapped[int] = mapped_column(primary_key=True)
    # Path relative to UPLOAD_DIR (see app/services/profile_images.py)
    image_path: Mapped[str] = mapped_column(String(255), nullable=False)
    position: Mapped[int] = mapped_column(Integer, nullable=False, default=0, server_default="0")
    # The default photo shipped with the app (app/static/login): never deleted from disk, can be restored.
    is_builtin: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc)
    )
