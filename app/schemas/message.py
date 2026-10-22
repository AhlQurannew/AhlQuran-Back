from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum


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


class MessageCreate(BaseModel):
    message: str = Field(..., min_length=1, max_length=5000, example="Hello, this is a test message")
    sender_role: SenderRole | None = Field(None, example="teacher")


class MessageAttachmentResponse(BaseModel):
    id: int
    filename: str
    content_type: str
    size: int
    url: str


class MessageResponse(BaseModel):
    id: int
    sender_id: int | None
    admin_sender_id: int | None = None
    sender_name: str
    sender_role: str
    message: str
    created_at: datetime
    attachments: list[MessageAttachmentResponse] = Field(default_factory=list)

    class Config:
        from_attributes = True


class MessageList(BaseModel):
    messages: list[MessageResponse]
    total: int
