from pydantic import BaseModel, ConfigDict, EmailStr, Field


class AdminContactEmailUpdate(BaseModel):
    model_config = ConfigDict(extra="forbid")

    email: EmailStr
    current_password: str = Field(min_length=1, max_length=256)
