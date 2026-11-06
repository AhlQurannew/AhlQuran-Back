import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.schemas.guardian import AccountInfo
from app.services.registration_numbers import normalize, validate_format
from app.services.usernames import base_username, slug


def test_latin_names_keep_letters_and_lose_accents():
    assert base_username("Ahmed", "Ben Ali") == "ahmed_ben_ali"
    assert base_username("Hélène", "Dupré") == "helene_dupre"


def test_arabic_names_are_transliterated_to_ascii():
    username = base_username("أحمد", "بن علي")
    assert username.isascii() and username == "ahmd_bn_ali"
    assert slug("محمد") == "mhmd"


def test_empty_names_fall_back_to_a_generic_username():
    assert base_username("", "") == "parent"
    assert base_username("!!!", "") == "parent"


def test_registration_numbers_are_normalized_and_validated():
    assert normalize("  s2026-0001 ") == "S2026-0001"
    validate_format("S2026-0001")
    validate_format("CUSTOM_ID/7")
    for bad in ("-starts-with-dash", "has space", "x" * 31, "é123"):
        with pytest.raises(HTTPException) as error:
            validate_format(bad)
        assert error.value.status_code == 422


def test_guardian_usernames_are_trimmed_lowercased_and_spaceless():
    assert AccountInfo(username="  Ahmed_BenAli ", password="x").username == "ahmed_benali"
    with pytest.raises(ValidationError):
        AccountInfo(username="ahmed ben", password="x")
    with pytest.raises(ValidationError):
        AccountInfo(username="   ", password="x")
