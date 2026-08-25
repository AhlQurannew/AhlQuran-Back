from sqlalchemy import String, DateTime
# from sqlalchemy.orm import relationship
from sqlalchemy.orm import Mapped, mapped_column
from app.db.base import Base
from datetime import datetime, timezone
from typing import Optional

class Admin(Base):
    __tablename__ = "admins"

    id : Mapped[int] = mapped_column(primary_key=True, index=True)
    user : Mapped[str] = mapped_column(String, unique=True, index=True)
    password : Mapped[str] = mapped_column(String)
    
    role : Mapped[str] = mapped_column(String, default="admin")

    created_by_id: Mapped[Optional[int]] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True) , default=lambda: datetime.now(timezone.utc))
     

    def __repr__(self):
        return f"<Admin(id={self.id}, user={self.user}, password={self.password})>"