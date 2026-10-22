from pydantic import BaseModel, EmailStr, Field
from typing import Optional
from datetime import datetime


class GuardianInfo(BaseModel):
    """Guardian information schema"""
    first_name: str
    last_name: str
    relationship: str  # Required: relationship to student
    date_of_birth: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    job: Optional[str] = None
    address: Optional[str] = None


class AccountInfo(BaseModel):
    """Account information for guardian"""
    username: str
    password: str


class AccountInfoUpdate(BaseModel):
    """Account information for guardian update (password optional)"""
    username: str
    password: Optional[str] = None


class GuardianCreate(BaseModel):
    """Schema for creating a guardian"""
    guardian_info: GuardianInfo
    account_info: AccountInfo
    student_ids: list[int] = Field(default_factory=list)
    student_id: Optional[int] = None  # Backwards-compatible single-child input.


class GuardianUpdate(BaseModel):
    """Schema for updating a guardian"""
    guardian_info: GuardianInfo
    account_info: AccountInfoUpdate
    student_ids: list[int] = Field(default_factory=list)
    student_id: Optional[int] = None  # Backwards-compatible single-child input.


class GuardianStudentSummary(BaseModel):
    id: int
    first_name: str
    last_name: str
    username: Optional[str] = None


class GuardianStudentOptions(BaseModel):
    students: list[GuardianStudentSummary]
    total: int


class GuardianResponse(BaseModel):
    """Response schema for guardian"""
    id: int
    user_id: int
    first_name: str
    last_name: str
    relationship_to_student: str
    date_of_birth: Optional[str] = None
    phone_number: Optional[str] = None
    email: Optional[str] = None
    job: Optional[str] = None
    address: Optional[str] = None
    username: Optional[str] = None
    student_id: Optional[int] = None  # Deprecated: first linked student ID.
    student_ids: list[int] = Field(default_factory=list)
    students: list[GuardianStudentSummary] = Field(default_factory=list)
    is_active: bool = True
    
    class Config:
        from_attributes = True


class GuardianListResponse(BaseModel):
    """Response schema for list of guardians"""
    guardians: list[GuardianResponse]
    total: int


# Alias for consistency with other routes
GuardianList = GuardianListResponse
