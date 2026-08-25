from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class AdminLoginReq(BaseModel):
    user: str
    password : str

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

# this is for the president registration
class RegisterRequest(BaseModel):
    firstname: str = Field(..., min_length=2, max_length=50)
    lastname: str = Field(..., min_length=2, max_length=50)
    email: str = Field(..., min_length=2, max_length=50)
    password: str = Field(..., min_length=6)
    school_name: str = Field(..., min_length=3, max_length=100)
    phone_number: Optional[str] = Field(None, max_length=20)
    
    class Config:
        json_schema_extra = {
            "example": {
                "firstname": "John",
                "lastname": "Doe",
                "email": "john.president@school.com",
                "password": "securePassword123",
                "school_name": "Springfield Elementary",
                "phone_number": "+1234567890"
            }
        }

class RegisterResponse(BaseModel):
    message : str



class AuthResponse(BaseModel):
    message: str
    user: dict
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "Registration successful. Your account is pending administrator approval.",
                "user": {
                    "id": 1,
                    "email": "john.president@school.com",
                    "firstname": "John",
                    "lastname": "Doe",
                    "role": "president",
                    "is_active": False
                }
            }
        }

# this is for the president login
class LoginResponse(BaseModel):
    message: str
    access_token: str
    token_type: str = "bearer"
    user: dict
    
    class Config:
        json_schema_extra = {
            "example": {
                "message": "Login successful",
                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
                "token_type": "bearer",
                "user": {
                    "id": 1,
                    "email": "john.president@school.com",
                    "firstname": "John",
                    "lastname": "Doe",
                    "role": "president"
                }
            }
        }

class UserInfo(BaseModel):
    id: int
    email: str
    firstname: str
    lastname: str
    role: str
    is_active: bool

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str
    message: str
    user: Optional[UserInfo] = None
    guardian: Optional[dict] = None


class RefreshTokenRequest(BaseModel):
    refresh_token: str


class RefreshTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"