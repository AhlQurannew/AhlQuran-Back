import logging
from io import BytesIO
from pathlib import Path
from uuid import uuid4

from PIL import Image, ImageOps, UnidentifiedImageError

from app.core.config import settings

logger = logging.getLogger(__name__)

MAX_PROFILE_IMAGE_BYTES = 2 * 1024 * 1024
MAX_PROFILE_IMAGE_PIXELS = 12_000_000
ALLOWED_IMAGE_FORMATS = {"PNG", "JPEG", "WEBP"}


def store_student_profile_image(raw: bytes, student_id: int) -> str:
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
            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)

            relative_path = Path("students") / str(student_id) / f"{uuid4().hex}.webp"
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


def remove_student_profile_image(relative_path: str | None) -> None:
    if not relative_path:
        return
    upload_root = Path(settings.UPLOAD_DIR).resolve()
    target = (upload_root / relative_path).resolve()
    if target.is_relative_to(upload_root) and target.is_file():
        try:
            target.unlink()
        except OSError:
            logger.exception("Could not remove student profile image")
