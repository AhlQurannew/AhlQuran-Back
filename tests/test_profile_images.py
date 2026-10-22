from io import BytesIO
from pathlib import Path

import pytest
from PIL import Image

from app.core.config import settings
from app.services.profile_images import (
    remove_student_profile_image,
    store_student_profile_image,
)


@pytest.mark.parametrize("image_format", ["PNG", "JPEG", "WEBP"])
def test_profile_image_is_validated_normalized_and_removed(tmp_path, monkeypatch, image_format):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    source = BytesIO()
    Image.new("RGB", (8, 6), "teal").save(source, format=image_format)

    stored_path = store_student_profile_image(source.getvalue(), student_id=12)
    image_path = Path(tmp_path) / stored_path

    with Image.open(image_path) as stored_image:
        assert stored_image.format == "WEBP"
        assert stored_image.size == (8, 6)

    remove_student_profile_image(stored_path)
    assert not image_path.exists()


def test_profile_image_rejects_malformed_data(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))

    with pytest.raises(ValueError, match="valid supported image"):
        store_student_profile_image(b"not an image", student_id=12)


def test_profile_image_rejects_unsupported_format(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    source = BytesIO()
    Image.new("RGB", (2, 2), "blue").save(source, format="GIF")

    with pytest.raises(ValueError, match="Only PNG, JPG, JPEG, and WebP"):
        store_student_profile_image(source.getvalue(), student_id=12)


def test_profile_image_cleanup_cannot_escape_upload_directory(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    outside_file = tmp_path.parent / "do-not-delete.webp"
    outside_file.write_bytes(b"safe")

    remove_student_profile_image("../do-not-delete.webp")

    assert outside_file.exists()
