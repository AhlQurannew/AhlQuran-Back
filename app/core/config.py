from typing import Literal

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore",
    )

    # Database
    DATABASE_URL: str
    DB_POOL_SIZE: int = Field(default=5, ge=1, le=100)
    DB_MAX_OVERFLOW: int = Field(default=5, ge=0, le=100)
    DB_POOL_TIMEOUT_SECONDS: int = Field(default=30, ge=1, le=300)
    
    # Security
    SECRET_KEY: str = Field(min_length=32)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30
    
    # API
    API_V1_PREFIX: str = "/api/v1"
    PROJECT_NAME: str = "Ahl Quran School Management"
    CORS_ORIGINS: list[str] = ["http://localhost:3000"]
    
    # Environment
    APP_ENV: Literal["development", "production"] = "production"
    DEBUG: bool = False
    UPLOAD_DIR: str = "uploads"
    @field_validator("SECRET_KEY")
    @classmethod
    def reject_known_development_secret(cls, value: str) -> str:
        if value in {
            "ahlquran2024secretkeyprojectlaib",
            "your-secret-key-change-in-production-use-openssl-rand-hex-32",
        }:
            raise ValueError("SECRET_KEY must be replaced with a private random value")
        return value

    @field_validator("CORS_ORIGINS")
    @classmethod
    def validate_cors_origins(cls, origins: list[str]) -> list[str]:
        normalized = [origin.rstrip("/") for origin in origins]
        if not normalized or any(origin == "*" for origin in normalized):
            raise ValueError("CORS_ORIGINS must contain explicit origins; wildcard is not allowed")
        if any(not origin.startswith(("http://", "https://")) for origin in normalized):
            raise ValueError("Each CORS origin must start with http:// or https://")
        return normalized


settings = Settings()
