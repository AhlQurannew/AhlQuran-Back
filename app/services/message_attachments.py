"""Private local storage and content validation for chat attachments."""

import asyncio
import csv
import io
import logging
import os
import re
import stat
import time
import warnings
import zipfile
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO
from uuid import uuid4
from xml.etree import ElementTree

from PIL import Image, UnidentifiedImageError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.message import Message, MessageAttachment

logger = logging.getLogger(__name__)

MAX_ATTACHMENT_BYTES = 25 * 1024 * 1024
MAX_ATTACHMENTS_PER_MESSAGE = 5
MAX_MESSAGE_ATTACHMENT_BYTES = 50 * 1024 * 1024
COPY_CHUNK_BYTES = 1024 * 1024
MAX_IMAGE_PIXELS = 40_000_000


class AttachmentTooLarge(ValueError):
    pass


class AttachmentTotalTooLarge(ValueError):
    pass


@dataclass(frozen=True)
class StoredAttachment:
    storage_path: str
    filename: str
    content_type: str
    size: int


def _safe_display_filename(filename: str | None, extension: str) -> str:
    original = (filename or "attachment").replace("\\", "/").split("/")[-1]
    original = "".join(char for char in original if char >= " " and char != "\x7f").strip()
    stem = Path(original).stem[:180].strip(" .") or "attachment"
    return f"{stem}.{extension}"


def _sanitize_svg(raw: bytes) -> bytes:
    if b"<!DOCTYPE" in raw.upper() or b"<!ENTITY" in raw.upper():
        raise ValueError("SVG documents with declarations are not supported")
    try:
        root = ElementTree.fromstring(raw)
    except (ElementTree.ParseError, UnicodeError, ValueError) as exc:
        raise ValueError("The uploaded SVG is malformed") from exc

    if root.tag.rsplit("}", 1)[-1].lower() != "svg":
        raise ValueError("The uploaded file is not an SVG image")

    allowed_elements = {
        "svg", "g", "path", "rect", "circle", "ellipse", "line", "polyline",
        "polygon", "text", "tspan", "defs", "linearGradient", "radialGradient",
        "stop", "clipPath", "mask", "pattern", "symbol", "use", "title", "desc",
    }
    allowed_attributes = {
        "id", "viewBox", "width", "height", "x", "y", "x1", "x2", "y1", "y2",
        "cx", "cy", "r", "rx", "ry", "d", "points", "fill", "fill-rule",
        "fill-opacity", "stroke", "stroke-width", "stroke-linecap", "stroke-linejoin",
        "stroke-dasharray", "stroke-dashoffset", "stroke-opacity", "opacity", "transform",
        "xmlns", "version", "preserveAspectRatio", "offset", "stop-color", "stop-opacity",
        "gradientUnits", "gradientTransform", "spreadMethod", "clip-path", "clip-rule",
        "mask", "patternUnits", "patternContentUnits", "patternTransform", "font-size",
        "font-family", "font-weight", "text-anchor", "dominant-baseline", "href",
    }

    def clean(element: ElementTree.Element) -> None:
        for child in list(element):
            child_name = child.tag.rsplit("}", 1)[-1]
            if child_name not in allowed_elements:
                element.remove(child)
                continue
            clean(child)

        for name, value in list(element.attrib.items()):
            local_name = name.rsplit("}", 1)[-1]
            lowered_name = local_name.lower()
            lowered_value = value.strip().lower()
            if (
                local_name not in allowed_attributes
                or lowered_name.startswith("on")
                or "url(" in lowered_value and not re.fullmatch(r"[^)]*url\(\s*#[a-z0-9_.:-]+\s*\)[^)]*", lowered_value)
                or local_name == "href" and not value.strip().startswith("#")
                or "javascript:" in lowered_value
                or "data:" in lowered_value
                or "http:" in lowered_value
                or "https:" in lowered_value
            ):
                del element.attrib[name]

    clean(root)
    return ElementTree.tostring(root, encoding="utf-8", xml_declaration=True)


def _validate_office_archive(raw: bytes) -> tuple[str, str] | None:
    try:
        with zipfile.ZipFile(io.BytesIO(raw)) as archive:
            entries = archive.infolist()
            if len(entries) > 2000 or sum(entry.file_size for entry in entries) > 100 * 1024 * 1024:
                return None
            if any(entry.file_size > 20 * 1024 * 1024 for entry in entries):
                return None
            names = {entry.filename for entry in entries}
            lower_names = {name.lower() for name in names}
            if any(
                "vbaproject" in name
                or ".bin" in name
                or "/embeddings/" in name
                or "activex" in name
                or "oleobject" in name
                for name in lower_names
            ):
                return None
            if "[Content_Types].xml" not in names:
                return None
            content_types = archive.read("[Content_Types].xml")
            if b"macroenabled" in content_types.lower() or b"vbaproject" in content_types.lower():
                return None

            expected = {
                "word/document.xml": (
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    "docx",
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml",
                    "document",
                ),
                "xl/workbook.xml": (
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    "xlsx",
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml",
                    "workbook",
                ),
                "ppt/presentation.xml": (
                    "application/vnd.openxmlformats-officedocument.presentationml.presentation",
                    "pptx",
                    "application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml",
                    "presentation",
                ),
            }
            matched_entry = next((name for name in expected if name in names), None)
            if matched_entry is None:
                return None
            content_type, extension, main_part_type, expected_root = expected[matched_entry]
            if main_part_type.encode() not in content_types.lower():
                return None
            if entries_by_name := {entry.filename: entry for entry in entries}:
                if entries_by_name[matched_entry].file_size > 4 * 1024 * 1024:
                    return None
            try:
                main_part = ElementTree.fromstring(archive.read(matched_entry))
            except (ElementTree.ParseError, UnicodeError, ValueError):
                return None
            if main_part.tag.rsplit("}", 1)[-1] != expected_root:
                return None
            match = (content_type, extension)

            for rel_name in names:
                if rel_name.endswith(".rels"):
                    rel_data = archive.read(rel_name)
                    if re.search(rb"TargetMode\s*=\s*['\"]External['\"]", rel_data, re.IGNORECASE):
                        return None
            return match
    except (zipfile.BadZipFile, EOFError, KeyError, OSError, RuntimeError, NotImplementedError, zlib.error):
        return None


def _detect_and_validate(raw: bytes, filename: str) -> tuple[str, str, bytes]:
    if not raw:
        raise ValueError("The uploaded file is empty")

    suffix = Path((filename or "").replace("\\", "/")).suffix.lower()
    allowed_suffixes = {
        ".jpg", ".jpeg", ".png", ".webp", ".gif", ".svg", ".pdf",
        ".txt", ".csv", ".docx", ".xlsx", ".pptx",
    }
    if suffix not in allowed_suffixes:
        raise ValueError("Use a supported filename extension: JPG, PNG, WebP, GIF, SVG, PDF, TXT, CSV, DOCX, XLSX, or PPTX")

    try:
        with warnings.catch_warnings():
            warnings.simplefilter("error", Image.DecompressionBombWarning)
            with Image.open(io.BytesIO(raw)) as image:
                image_type = image.format
                if image_type in {"JPEG", "PNG", "WEBP", "GIF"}:
                    if image.width * image.height > MAX_IMAGE_PIXELS:
                        raise ValueError("Image dimensions are too large")
                    image.verify()
                    types = {
                        "JPEG": ("image/jpeg", "jpg", {".jpg", ".jpeg"}),
                        "PNG": ("image/png", "png", {".png"}),
                        "WEBP": ("image/webp", "webp", {".webp"}),
                        "GIF": ("image/gif", "gif", {".gif"}),
                    }
                    content_type, extension, expected_suffixes = types[image_type]
                    if suffix not in expected_suffixes:
                        raise ValueError("The filename extension does not match image content")
                    if image_type == "JPEG" and not raw.endswith(b"\xff\xd9"):
                        raise ValueError("The uploaded JPEG contains trailing or incomplete data")
                    if image_type == "PNG":
                        end_marker = raw.rfind(b"IEND")
                        if end_marker < 4 or end_marker + 8 != len(raw):
                            raise ValueError("The uploaded PNG contains trailing or incomplete data")
                    if image_type == "WEBP":
                        if len(raw) < 12 or int.from_bytes(raw[4:8], "little") + 8 != len(raw):
                            raise ValueError("The uploaded WebP contains trailing or incomplete data")
                    if image_type == "GIF" and not raw.endswith(b";"):
                        raise ValueError("The uploaded GIF contains trailing or incomplete data")
                    return content_type, extension, raw
    except ValueError:
        raise
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError, Image.DecompressionBombWarning):
        pass

    trimmed = raw.lstrip()
    if trimmed.startswith(b"<"):
        try:
            sanitized = _sanitize_svg(raw)
        except ValueError:
            looks_like_svg = re.search(
                rb"<\s*(?:[a-z_][\w.-]*:)?svg\b",
                raw[:8192],
                re.IGNORECASE,
            )
            if suffix == ".svg" or looks_like_svg:
                raise
        else:
            if suffix != ".svg":
                raise ValueError("The filename extension does not match SVG content")
            return "image/svg+xml", "svg", sanitized

    if raw.startswith(b"%PDF-"):
        if suffix != ".pdf":
            raise ValueError("The filename extension does not match PDF content")
        eof_index = raw.rfind(b"%%EOF")
        if eof_index < 0 or raw[eof_index + len(b"%%EOF"):].strip():
            raise ValueError("The uploaded PDF is incomplete or contains trailing data")
        if re.search(rb"/(?:JavaScript|JS|Launch|EmbeddedFile|OpenAction)\b", raw, re.IGNORECASE):
            raise ValueError("Active or embedded PDF content is not supported")
        return "application/pdf", "pdf", raw

    office_type = _validate_office_archive(raw)
    if office_type:
        if suffix != f".{office_type[1]}":
            raise ValueError("The filename extension does not match Office document content")
        return office_type[0], office_type[1], raw

    if raw.startswith((b"MZ", b"\x7fELF", b"#!", b"\xca\xfe\xba\xbe", b"\xfe\xed\xfa")):
        raise ValueError("Executable and script files are not supported")

    try:
        text = raw.decode("utf-8-sig", errors="strict")
    except UnicodeDecodeError as exc:
        raise ValueError("Only supported images, documents, or UTF-8 text files are allowed") from exc
    if any(ord(char) < 32 and char not in "\t\n\r\f" for char in text):
        raise ValueError("Binary or executable content is not supported")
    if re.search(
        r"<!\s*doctype\s+html|<\s*/?\s*(?:html|head|body|script|iframe|object|embed|form)\b|"
        r"(?:^|\n)\s*(?:#!|<\?xml|(?:import\s+\w|from\s+\w+\s+import\s)|"
        r"def\s+\w+\s*\(|function\s+\w*\s*\(|(?:const|let|var)\s+\w+\s*=|"
        r"console\.|document\.|Write-Host|@echo\s+off)",
        text,
        re.IGNORECASE,
    ):
        raise ValueError("Script and HTML files are not supported")

    # CSV is recognized by tabular content. Formula-like cells are rejected to
    # avoid spreadsheet formula execution when a downloaded CSV is opened.
    try:
        dialect = csv.Sniffer().sniff(text[:8192], delimiters=",;\t|")
        row_count = 0
        has_multiple_columns = False
        for row in csv.reader(io.StringIO(text), dialect):
            row_count += 1
            has_multiple_columns |= len(row) > 1
            for cell in row:
                value = cell.strip()
                if value.startswith(("=", "+", "@")) or (
                    value.startswith("-") and not re.fullmatch(r"-\d+(?:\.\d+)?", value)
                ):
                    raise ValueError("Formula-like CSV cells are not supported")
        is_csv = row_count > 1 and has_multiple_columns
    except csv.Error:
        is_csv = False

    if suffix == ".csv":
        if not is_csv:
            raise ValueError("CSV files must contain delimited tabular data")
        return "text/csv", "csv", raw
    if suffix != ".txt":
        raise ValueError("The filename extension does not match text content")
    if is_csv:
        raise ValueError("Tabular data must use the .csv extension")
    return "text/plain", "txt", raw


def _safe_attachment_directory(tenant_id: int) -> tuple[Path, Path]:
    root = Path(settings.UPLOAD_DIR).resolve()
    messages_root = root / "messages"
    messages_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    directory = messages_root / str(tenant_id)
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    resolved_messages_root = messages_root.resolve()
    resolved_directory = directory.resolve()
    if resolved_messages_root != messages_root or resolved_directory != directory:
        raise OSError("Attachment storage directories must not be symlinks")
    try:
        resolved_messages_root.chmod(0o700)
        resolved_directory.chmod(0o700)
    except OSError:
        logger.warning("Could not enforce private permissions on %s", resolved_directory)
    return root, resolved_directory


def store_message_attachment(
    source: BinaryIO,
    tenant_id: int,
    filename: str | None,
    max_bytes: int = MAX_ATTACHMENT_BYTES,
) -> StoredAttachment:
    """Stream, validate, and atomically store one private attachment."""
    root, directory = _safe_attachment_directory(tenant_id)
    token = uuid4().hex
    temporary = directory / f".{token}.tmp"
    final_path: Path | None = None
    size = 0
    effective_limit = min(max_bytes, MAX_ATTACHMENT_BYTES)
    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, stat.S_IRUSR | stat.S_IWUSR)
    try:
        with os.fdopen(fd, "wb") as destination:
            while True:
                chunk = source.read(COPY_CHUNK_BYTES)
                if not chunk:
                    break
                size += len(chunk)
                if size > effective_limit:
                    if max_bytes < MAX_ATTACHMENT_BYTES:
                        raise AttachmentTotalTooLarge("Attachments must total 50 MiB or less")
                    raise AttachmentTooLarge("Each attachment must be 25 MiB or smaller")
                destination.write(chunk)
            destination.flush()
            os.fsync(destination.fileno())

        raw = temporary.read_bytes()
        content_type, extension, validated = _detect_and_validate(raw, filename or "")
        if len(validated) > effective_limit:
            if max_bytes < MAX_ATTACHMENT_BYTES:
                raise AttachmentTotalTooLarge("Attachments must total 50 MiB or less")
            raise AttachmentTooLarge("Each attachment must be 25 MiB or smaller")
        if validated != raw:
            temporary.write_bytes(validated)
            size = len(validated)

        final_path = directory / token
        temporary.replace(final_path)
        relative_path = final_path.relative_to(root).as_posix()
        return StoredAttachment(
            storage_path=relative_path,
            filename=_safe_display_filename(filename, extension),
            content_type=content_type,
            size=size,
        )
    except Exception:
        temporary.unlink(missing_ok=True)
        if final_path is not None:
            final_path.unlink(missing_ok=True)
        raise


async def cleanup_orphaned_message_attachments(
    db: AsyncSession,
    tenant_id: int,
    minimum_age_seconds: int = 3600,
) -> int:
    """Remove old generated files lacking metadata, without racing active uploads."""
    result = await db.execute(
        select(MessageAttachment.storage_path)
        .join(Message, Message.id == MessageAttachment.message_id)
        .where(Message.president_id == tenant_id)
    )
    referenced = set(result.scalars().all())
    root = Path(settings.UPLOAD_DIR).resolve()
    messages_root = root / "messages"
    tenant_directory = messages_root / str(tenant_id)
    try:
        if messages_root.resolve(strict=True) != messages_root or tenant_directory.resolve(strict=True) != tenant_directory:
            return 0
    except (OSError, RuntimeError):
        return 0
    directory = tenant_directory
    if not directory.is_relative_to(root) or not directory.is_dir():
        return 0
    cutoff = time.time() - minimum_age_seconds

    def remove_orphans() -> int:
        removed = 0
        try:
            with os.scandir(directory) as entries:
                for entry in entries:
                    is_final = re.fullmatch(r"[0-9a-f]{32}", entry.name) is not None
                    is_temporary = re.fullmatch(r"\.[0-9a-f]{32}\.tmp", entry.name) is not None
                    if not is_final and not is_temporary:
                        continue
                    relative_path = f"messages/{tenant_id}/{entry.name}"
                    if (is_final and relative_path in referenced) or not entry.is_file(follow_symlinks=False):
                        continue
                    try:
                        if entry.stat(follow_symlinks=False).st_mtime < cutoff:
                            os.unlink(entry.path)
                            removed += 1
                    except OSError:
                        logger.exception("Could not remove orphaned message attachment: %s", relative_path)
        except OSError:
            logger.exception("Could not scan message attachment directory for tenant %s", tenant_id)
        return removed

    return await asyncio.to_thread(remove_orphans)


def resolve_message_attachment_path(relative_path: str, tenant_id: int) -> Path | None:
    """Resolve only the generated tenant/UUID path form; never follow symlinks."""
    if not re.fullmatch(rf"messages/{tenant_id}/[0-9a-f]{{32}}", relative_path):
        return None
    root = Path(settings.UPLOAD_DIR).resolve()
    messages_root = root / "messages"
    directory = messages_root / str(tenant_id)
    try:
        resolved_directory = directory.resolve(strict=True)
        resolved_messages_root = messages_root.resolve(strict=True)
        if resolved_messages_root != messages_root or resolved_directory != directory:
            return None
        target = resolved_directory / relative_path.rsplit("/", 1)[-1]
        target_stat = target.lstat()
    except (OSError, RuntimeError):
        return None
    if stat.S_ISLNK(target_stat.st_mode) or not stat.S_ISREG(target_stat.st_mode):
        return None
    return target


def remove_message_attachment(relative_path: str | None) -> None:
    if not relative_path:
        return
    match = re.fullmatch(r"messages/(\d+)/([0-9a-f]{32})", relative_path)
    if match is None:
        return
    target = resolve_message_attachment_path(relative_path, int(match.group(1)))
    if target is None:
        return
    try:
        target.unlink()
    except OSError:
        logger.exception("Could not remove stored message attachment: %s", relative_path)
