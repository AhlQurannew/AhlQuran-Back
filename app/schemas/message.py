from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum


class SenderRole(str, Enum):
    TEACHER = "teacher"
    SUPERVISOR = "supervisor"
    PRESIDENT = "president"
    
    def __str__(self):
        return self.value


class MessageCreate(BaseModel):
    message: str = Field(..., min_length=1, max_length=5000, example="Hello, this is a test message")
    sender_role: SenderRole | None = Field(None, example="teacher")


class MessageResponse(BaseModel):
    id: int
    sender_id: int
    sender_name: str
    sender_role: SenderRole
    message: str
    created_at: datetime

    class Config:
        from_attributes = True


class MessageList(BaseModel):
    messages: list[MessageResponse]
    total: int
