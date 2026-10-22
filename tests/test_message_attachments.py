from io import BytesIO
from pathlib import Path

import pytest
from PIL import Image

from app.core.config import settings
from app.services.message_attachments import (
    AttachmentTotalTooLarge,
    remove_message_attachment,
    store_message_attachment,
)


@pytest.mark.parametrize(
    ("image_format", "content_type", "extension"),
    [
        ("JPEG", "image/jpeg", ".jpg"),
        ("PNG", "image/png", ".png"),
        ("WEBP", "image/webp", ".webp"),
        ("GIF", "image/gif", ".gif"),
    ],
)
def test_raster_attachments_are_detected_from_content_and_private(
    tmp_path, monkeypatch, image_format, content_type, extension
):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    data = BytesIO()
    Image.new("RGB", (8, 6), "teal").save(data, format=image_format)

    stored = store_message_attachment(
        BytesIO(data.getvalue()),
        tenant_id=42,
        filename="../../photo." + extension.lstrip("."),
    )
    target = Path(settings.UPLOAD_DIR) / stored.storage_path

    assert stored.storage_path.startswith("messages/42/")
    assert len(Path(stored.storage_path).name) == 32
    assert stored.content_type == content_type
    assert stored.filename.endswith(extension)
    assert target.exists()
    assert target.stat().st_mode & 0o077 == 0
    assert target.read_bytes() == data.getvalue()

    remove_message_attachment(stored.storage_path)
    assert not target.exists()


def test_svg_is_sanitized_and_stored_as_an_attachment(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    svg = b'''<svg xmlns="http://www.w3.org/2000/svg" onload="alert(1)">
      <script>alert(1)</script><a href="https://evil.example/">bad</a>
      <path d="M0 0" fill="red" />
    </svg>'''

    stored = store_message_attachment(BytesIO(svg), tenant_id=7, filename="drawing.svg")
    sanitized = (Path(settings.UPLOAD_DIR) / stored.storage_path).read_bytes().lower()

    assert stored.content_type == "image/svg+xml"
    assert b"script" not in sanitized
    assert b"onload" not in sanitized
    assert b"https://" not in sanitized
    assert b"path" in sanitized


def test_rejects_executable_even_when_named_as_text(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))

    with pytest.raises(ValueError, match="Executable and script"):
        store_message_attachment(BytesIO(b"MZ\x90\x00payload"), tenant_id=3, filename="notes.txt")

    assert not list((Path(settings.UPLOAD_DIR) / "messages" / "3").glob("*"))


def test_rejects_content_with_mismatched_or_disallowed_extension(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    data = BytesIO()
    Image.new("RGB", (4, 4), "blue").save(data, format="PNG")

    with pytest.raises(ValueError, match="extension does not match"):
        store_message_attachment(BytesIO(data.getvalue()), tenant_id=3, filename="image.jpg")
    with pytest.raises(ValueError, match="supported filename extension"):
        store_message_attachment(BytesIO(data.getvalue()), tenant_id=3, filename="image.exe")

    svg = b'<svg xmlns="http://www.w3.org/2000/svg"><path d="M0 0"/></svg>'
    with pytest.raises(ValueError, match="extension does not match"):
        store_message_attachment(BytesIO(svg), tenant_id=3, filename="drawing.txt")


def test_streaming_size_limit_removes_partial_file(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))

    with pytest.raises(AttachmentTotalTooLarge):
        store_message_attachment(BytesIO(b"four"), tenant_id=3, filename="note.txt", max_bytes=3)

    assert list((Path(settings.UPLOAD_DIR) / "messages" / "3").iterdir()) == []


def test_rejects_html_named_as_text(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))

    with pytest.raises(ValueError, match="Script and HTML"):
        store_message_attachment(BytesIO(b"<!doctype html><html></html>"), tenant_id=3, filename="page.txt")


def test_cleanup_cannot_escape_upload_root(tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIR", str(tmp_path))
    outside = tmp_path.parent / "private-attachment"
    outside.write_bytes(b"keep")

    remove_message_attachment("../private-attachment")

    assert outside.exists()
