from types import SimpleNamespace

import pytest
from fastapi import HTTPException

from app.core.account_lifecycle import reset_user_password
from app.core.security import verify_password


def make_user(auth_version: int = 0):
    return SimpleNamespace(hashed_password="old-hash", auth_version=auth_version)


def test_reset_sets_a_working_hash_and_ends_existing_sessions():
    user = make_user(auth_version=3)

    reset_user_password(user, "New-pass-789")

    assert verify_password("New-pass-789", user.hashed_password)
    assert not verify_password("Old-pass-123", user.hashed_password)
    assert user.auth_version == 4  # tokens issued with the old password stop working


def test_reset_rejects_passwords_bcrypt_cannot_handle():
    user = make_user()

    with pytest.raises(HTTPException) as error:
        reset_user_password(user, "x" * 73)

    assert error.value.status_code == 422
    assert user.hashed_password == "old-hash"
    assert user.auth_version == 0


def test_limit_counts_bytes_not_characters():
    user = make_user()

    with pytest.raises(HTTPException):
        reset_user_password(user, "é" * 40)  # 40 characters, 80 bytes
