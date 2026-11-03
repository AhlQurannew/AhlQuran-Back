import logging
from io import BytesIO
from pathlib import Path
from uuid import uuid4

from fastapi import HTTPException, UploadFile
from PIL import Image, ImageOps, UnidentifiedImageError

from app.core.config import settings

logger = logging.getLogger(__name__)

MAX_PROFILE_IMAGE_BYTES = 2 * 1024 * 1024
MAX_PROFILE_IMAGE_PIXELS = 12_000_000
ALLOWED_IMAGE_FORMATS = {"PNG", "JPEG", "WEBP"}
ALLOWED_IMAGE_CONTENT_TYPES = {"image/png", "image/jpeg", "image/webp"}


async def read_profile_image_upload(file: UploadFile, max_bytes: int = MAX_PROFILE_IMAGE_BYTES) -> bytes:
    """Read an uploaded image, enforcing content type and size limits."""
    if file.content_type and file.content_type not in ALLOWED_IMAGE_CONTENT_TYPES:
        raise HTTPException(status_code=415, detail="Upload a PNG, JPG, JPEG, or WebP image")
    contents = bytearray()
    while chunk := await file.read(64 * 1024):
        contents.extend(chunk)
        if len(contents) > max_bytes:
            raise HTTPException(status_code=413, detail=f"Image must be {max_bytes // (1024 * 1024)} MB or smaller")
    if not contents:
        raise HTTPException(status_code=400, detail="The uploaded image is empty")
    return bytes(contents)


def store_profile_image(raw: bytes, directory: Path, max_side: int = 1024) -> str:
    """Validate, normalize to WebP and store an image under UPLOAD_DIR/directory.

    Returns the path relative to UPLOAD_DIR.
    """
    try:
        with Image.open(BytesIO(raw)) as image:
            if image.format not in ALLOWED_IMAGE_FORMATS:
                raise ValueError("Only PNG, JPG, JPEG, and WebP images are supported")
            if image.width * image.height > MAX_PROFILE_IMAGE_PIXELS:
                raise ValueError("Image dimensions are too large")
            image.verify()

        with Image.open(BytesIO(raw)) as image:
            image = ImageOps.exif_transpose(image)
            if image.mode not in ("RGB", "RGBA"):
                image = image.convert("RGBA" if "transparency" in image.info else "RGB")
            image.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)

            relative_path = directory / f"{uuid4().hex}.webp"
            destination = Path(settings.UPLOAD_DIR) / relative_path
            destination.parent.mkdir(parents=True, exist_ok=True)
            temporary = destination.with_suffix(".tmp")
            try:
                image.save(temporary, format="WEBP", quality=85, method=6)
                temporary.replace(destination)
            finally:
                temporary.unlink(missing_ok=True)
            return relative_path.as_posix()
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise ValueError("The uploaded file is not a valid supported image") from exc


def store_student_profile_image(raw: bytes, student_id: int) -> str:
    return store_profile_image(raw, Path("students") / str(student_id))


def store_account_profile_image(raw: bytes, owner: str) -> str:
    """Store an account (user or admin) avatar; owner is e.g. "user-5" or "admin-1"."""
    return store_profile_image(raw, Path("accounts") / owner)


MAX_LOGIN_SLIDE_BYTES = 5 * 1024 * 1024


def store_login_slide_image(raw: bytes) -> str:
    """Store a login page slide; kept larger than avatars since it fills half the screen."""
    return store_profile_image(raw, Path("site") / "login", max_side=1920)


def resolve_profile_image(relative_path: str | None) -> Path | None:
    """Return the absolute path of a stored image, or None if missing or outside UPLOAD_DIR."""
    if not relative_path:
        return None
    upload_root = Path(settings.UPLOAD_DIR).resolve()
    target = (upload_root / relative_path).resolve()
    if not target.is_relative_to(upload_root) or not target.is_file():
        return None
    return target


def remove_profile_image(relative_path: str | None) -> None:
    target = resolve_profile_image(relative_path)
    if target is None:
        return
    try:
        target.unlink()
    except OSError:
        logger.exception("Could not remove profile image")


remove_student_profile_image = remove_profile_image
