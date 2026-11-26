"""Private storage for announcement attachments: images, videos and documents.

Files are streamed to disk, then validated by their content (never by the browser's content type):
images and documents reuse the chat attachment checks, videos are recognised by their container
header (MP4/MOV `ftyp`, WebM EBML). Paths stay under UPLOAD_DIR/announcements.
"""
import logging
import os
import stat
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO
from uuid import uuid4

from app.core.config import settings
from app.services.message_attachments import _detect_and_validate, _safe_display_filename

logger = logging.getLogger(__name__)

MAX_FILES = 6
MAX_VIDEO_BYTES = 80 * 1024 * 1024
MAX_FILE_BYTES = 25 * 1024 * 1024
MAX_TOTAL_BYTES = 150 * 1024 * 1024
CHUNK = 1024 * 1024
DIRECTORY = "announcements"

VIDEO_SUFFIXES = {".mp4": ("video/mp4", "mp4"), ".m4v": ("video/mp4", "m4v"), ".mov": ("video/quicktime", "mov"), ".webm": ("video/webm", "webm")}
MP4_BRANDS = {b"isom", b"iso2", b"iso4", b"iso5", b"iso6", b"mp41", b"mp42", b"avc1", b"M4V ", b"M4VP", b"dash", b"MSNV", b"3gp4", b"3gp5"}


class AnnouncementFileError(ValueError):
    pass


class AnnouncementFileTooLarge(AnnouncementFileError):
    pass


@dataclass(frozen=True)
class StoredFile:
    storage_path: str
    filename: str
    content_type: str
    size: int


def _root() -> tuple[Path, Path]:
    root = Path(settings.UPLOAD_DIR).resolve()
    directory = root / DIRECTORY
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    if directory.resolve() != directory:
        raise OSError("Announcement storage must not be a symlink")
    return root, directory


def _video_type(header: bytes, suffix: str) -> tuple[str, str] | None:
    """Content type of a supported video container, or None when the header is not one."""
    if suffix not in VIDEO_SUFFIXES:
        return None
    if suffix == ".webm":
        if header.startswith(b"\x1a\x45\xdf\xa3") and b"webm" in header[:64]:
            return VIDEO_SUFFIXES[suffix]
        raise AnnouncementFileError("The file is not a valid WebM video")
    if header[4:8] != b"ftyp":
        raise AnnouncementFileError("The file is not a valid MP4 or MOV video")
    brand = header[8:12]
    if suffix == ".mov":
        if brand == b"qt  ":
            return VIDEO_SUFFIXES[suffix]
        raise AnnouncementFileError("The file is not a valid MOV video")
    if brand in MP4_BRANDS:
        return VIDEO_SUFFIXES[suffix]
    raise AnnouncementFileError("Unsupported MP4 video format")


def store_announcement_file(source: BinaryIO, filename: str | None, remaining_total: int) -> StoredFile:
    """Stream one upload to disk, validate it and return where it is stored."""
    root, directory = _root()
    suffix = Path((filename or "").replace("\\", "/")).suffix.lower()
    is_video = suffix in VIDEO_SUFFIXES
    limit = min(MAX_VIDEO_BYTES if is_video else MAX_FILE_BYTES, remaining_total)
    token = uuid4().hex
    temporary = directory / f".{token}.tmp"
    final_path = directory / token
    size = 0
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, stat.S_IRUSR | stat.S_IWUSR)
    try:
        with os.fdopen(fd, "wb") as destination:
            while chunk := source.read(CHUNK):
                size += len(chunk)
                if size > limit:
                    if limit < (MAX_VIDEO_BYTES if is_video else MAX_FILE_BYTES):
                        raise AnnouncementFileTooLarge("Attachments must total 150 MB or less")
                    raise AnnouncementFileTooLarge("Videos must be 80 MB or smaller; other files 25 MB or smaller")
                destination.write(chunk)
        if size == 0:
            raise AnnouncementFileError("The uploaded file is empty")

        if is_video:
            with open(temporary, "rb") as handle:
                content_type, extension = _video_type(handle.read(64), suffix)
        else:
            raw = temporary.read_bytes()
            content_type, extension, validated = _detect_and_validate(raw, filename or "")
            if validated != raw:
                temporary.write_bytes(validated)
                size = len(validated)

        temporary.replace(final_path)
        return StoredFile(
            storage_path=final_path.relative_to(root).as_posix(),
            filename=_safe_display_filename(filename, extension),
            content_type=content_type,
            size=size,
        )
    except Exception:
        temporary.unlink(missing_ok=True)
        final_path.unlink(missing_ok=True)
        raise


def resolve_announcement_file(storage_path: str) -> Path | None:
    """Absolute path of a stored attachment, or None if it is missing or outside the folder."""
    root, directory = _root()
    target = (root / storage_path).resolve()
    if target.parent != directory or not target.is_file():
        return None
    return target


def remove_announcement_file(storage_path: str | None) -> None:
    if not storage_path:
        return
    try:
        path = resolve_announcement_file(storage_path)
        if path is not None:
            path.unlink(missing_ok=True)
    except OSError:
        logger.warning("Could not remove announcement file %s", storage_path, exc_info=True)
