from sqlalchemy import String, Integer, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from typing import Optional

from app.db.base import Base


class Guardian(Base):
    __tablename__ = "guardians"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        nullable=False
    )
    
    # Multi-tenancy: Link to president
    president_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("presidents.id", ondelete="CASCADE"), nullable=True, index=True)
    
    # Required fields
    first_name: Mapped[str] = mapped_column(String(100), nullable=False)
    last_name: Mapped[str] = mapped_column(String(100), nullable=False)
    relationship_to_student: Mapped[str] = mapped_column(String(50), nullable=False)
    
    # Optional fields
    date_of_birth: Mapped[Optional[str]] = mapped_column(String(20))
    phone_number: Mapped[Optional[str]] = mapped_column(String(20))
    email: Mapped[Optional[str]] = mapped_column(String(255))
    job: Mapped[Optional[str]] = mapped_column(String(100))
    address: Mapped[Optional[str]] = mapped_column(String(255))
    student_id: Mapped[Optional[int]] = mapped_column(
        Integer,
        ForeignKey("students.id", ondelete="SET NULL"),
        nullable=True
    )
    
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), 
        default=lambda: datetime.now(timezone.utc)
    )
    created_by_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"))
    
    # Relationships
    president: Mapped[Optional["President"]] = relationship("President", foreign_keys=[president_id])
    
    user: Mapped["User"] = relationship(
        "User",
        back_populates="guardian",
        foreign_keys=[user_id]
    )
    
    created_by: Mapped["User"] = relationship(
        "User",
        foreign_keys=[created_by_id]
    )
    
    student: Mapped[Optional["Student"]] = relationship(
        "Student",
        foreign_keys=[student_id],
        backref="guardians"
    )
    
    def __repr__(self) -> str:
        return f"Guardian(id={self.id}, name={self.first_name} {self.last_name})"
