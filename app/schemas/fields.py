"""Shared input rules for account forms: login emails, person names and new passwords."""
from typing import Annotated, Optional

from pydantic import AfterValidator, BeforeValidator, EmailStr

MIN_ACCOUNT_PASSWORD = 8
MAX_PASSWORD_BYTES = 72  # bcrypt ignores anything after 72 bytes


def normalize_email(value):
    """Emails are case-insensitive identifiers: store and compare them trimmed and lower-cased."""
    return value.strip().lower() if isinstance(value, str) else value


def check_new_password(value: str) -> str:
    if len(value) < MIN_ACCOUNT_PASSWORD:
        raise ValueError(f"The password must have at least {MIN_ACCOUNT_PASSWORD} characters")
    if len(value.encode("utf-8")) > MAX_PASSWORD_BYTES:
        raise ValueError("The password must not exceed 72 bytes")
    return value


def _optional_new_password(value: Optional[str]) -> Optional[str]:
    """In an edit form an empty password means "keep the current one"."""
    if value is None or not value.strip():
        return None
    return check_new_password(value)


def _name(max_length: int):
    def check(value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("This field is required")
        if len(value) > max_length:
            raise ValueError(f"This field must not exceed {max_length} characters")
        return value
    return check


LoginEmail = Annotated[EmailStr, BeforeValidator(normalize_email)]
NewPassword = Annotated[str, AfterValidator(check_new_password)]
OptionalNewPassword = Annotated[Optional[str], AfterValidator(_optional_new_password)]
# users.firstname / users.lastname are VARCHAR(50); guardians' names are VARCHAR(100).
PersonName = Annotated[str, AfterValidator(_name(50))]
GuardianName = Annotated[str, AfterValidator(_name(100))]
