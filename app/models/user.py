from sqlalchemy import String, Boolean, DateTime, Enum as SQLEnum, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from datetime import datetime, timezone
from enum import Enum
from typing import Optional
from app.db.base import Base


class UserRoleEnum(str, Enum):
    PRESIDENT = "PRESIDENT"
    SUPERVISOR = "SUPERVISOR"
    CHIEF_SUPERVISOR = "CHIEF_SUPERVISOR"
    TEACHER = "TEACHER"
    STUDENT = "STUDENT"
    GUARDIAN = "GUARDIAN"


class User(Base):
    __tablename__ = "users"
    
    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    firstname: Mapped[str] = mapped_column(String(50), nullable=False)
    lastname: Mapped[str] = mapped_column(String(50), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    role: Mapped[UserRoleEnum] = mapped_column(SQLEnum(UserRoleEnum), nullable=False)


    # Account status fields
    is_active: Mapped[bool] = mapped_column(Boolean, default=False)
    
    # Relationships
    president: Mapped[Optional["President"]] = relationship(
        "President",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan"
    )
    
    supervisor: Mapped[Optional["Supervisor"]] = relationship(
        "Supervisor",  
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        foreign_keys="Supervisor.user_id"      
        )
    
    teacher: Mapped[Optional["Teacher"]] = relationship(
        "Teacher",  back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        foreign_keys="Teacher.user_id"    
        )
    
    student: Mapped[Optional["Student"]] = relationship(
        "Student",  back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        foreign_keys="Student.user_id"  
    )
    
    guardian: Mapped[Optional["Guardian"]] = relationship(
        "Guardian",
        back_populates="user",
        uselist=False,
        cascade="all, delete-orphan",
        foreign_keys="Guardian.user_id"
    )
    
    def __repr__(self) -> str:
        return f"User(id={self.id}, email={self.email}, role={self.role})"
