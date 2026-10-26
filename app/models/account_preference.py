from sqlalchemy import Boolean, CheckConstraint, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AccountPreference(Base):
    __tablename__ = "account_preferences"
    __table_args__ = (
        CheckConstraint("(user_id IS NOT NULL) <> (admin_id IS NOT NULL)", name="ck_account_preferences_single_owner"),
        UniqueConstraint("user_id", name="uq_account_preferences_user"),
        UniqueConstraint("admin_id", name="uq_account_preferences_admin"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), nullable=True)
    admin_id: Mapped[int | None] = mapped_column(ForeignKey("admins.id", ondelete="CASCADE"), nullable=True)
    timezone: Mapped[str] = mapped_column(String(64), nullable=False, default="Africa/Algiers", server_default="Africa/Algiers")
    reduce_motion: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, server_default="false")
