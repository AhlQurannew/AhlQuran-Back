"""Public site content managed by the administrator (login page slideshow)."""
import logging

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.core.dependencies import require_super_admin
from app.db.session import get_db
from app.models.login_slide import LoginSlide
from app.services.profile_images import (
    MAX_LOGIN_SLIDE_BYTES,
    read_profile_image_upload,
    BUILTIN_PREFIX,
    remove_profile_image,
    resolve_builtin_image,
    resolve_profile_image,
    store_login_slide_image,
)

logger = logging.getLogger(__name__)
siteRouter = APIRouter()

MAX_LOGIN_SLIDES = 10


BUILTIN_PATH = f"{BUILTIN_PREFIX}masjid.jpg"


class LoginSlideResponse(BaseModel):
    id: int
    url: str
    position: int
    builtin: bool = False


class SlideOrder(BaseModel):
    ids: list[int] = Field(min_length=1, max_length=MAX_LOGIN_SLIDES)


def _slide_response(slide: LoginSlide) -> LoginSlideResponse:
    return LoginSlideResponse(
        id=slide.id,
        url=f"{settings.API_V1_PREFIX}/site/login-slides/{slide.id}/image",
        position=slide.position,
        builtin=slide.is_builtin,
    )


async def _ordered_slides(db: AsyncSession) -> list[LoginSlide]:
    result = await db.execute(select(LoginSlide).order_by(LoginSlide.position, LoginSlide.id))
    return list(result.scalars().all())


@siteRouter.get("/login-slides", response_model=list[LoginSlideResponse])
async def list_login_slides(db: AsyncSession = Depends(get_db)):
    """Public: slides shown on the login page (empty list means the default image)."""
    return [_slide_response(slide) for slide in await _ordered_slides(db)]


@siteRouter.get("/login-slides/{slide_id}/image")
async def get_login_slide_image(slide_id: int, db: AsyncSession = Depends(get_db)):
    slide = await db.get(LoginSlide, slide_id)
    if slide is not None and slide.is_builtin:
        builtin = resolve_builtin_image(slide.image_path)
        if builtin is None:
            raise HTTPException(status_code=404, detail="Slide not found")
        return FileResponse(builtin, media_type="image/jpeg", headers={"Cache-Control": "public, max-age=86400"})
    image_path = resolve_profile_image(slide.image_path if slide else None)
    if image_path is None:
        raise HTTPException(status_code=404, detail="Slide not found")
    # File names are random per upload, so the image at this URL never changes.
    return FileResponse(image_path, media_type="image/webp", headers={"Cache-Control": "public, max-age=86400"})


@siteRouter.post("/login-slides/builtin", response_model=LoginSlideResponse, status_code=status.HTTP_201_CREATED)
async def restore_builtin_slide(db: AsyncSession = Depends(get_db), admin=Depends(require_super_admin)):
    """Put the default photo back in the slideshow (first position) after it was removed."""
    existing = await db.scalar(select(LoginSlide).where(LoginSlide.is_builtin.is_(True)))
    if existing is not None:
        return _slide_response(existing)
    count = await db.scalar(select(func.count(LoginSlide.id))) or 0
    if count >= MAX_LOGIN_SLIDES:
        raise HTTPException(status_code=409, detail=f"A maximum of {MAX_LOGIN_SLIDES} slides is allowed")
    first = await db.scalar(select(func.min(LoginSlide.position)))
    slide = LoginSlide(image_path=BUILTIN_PATH, position=(first or 1) - 1, is_builtin=True)
    db.add(slide)
    await db.commit()
    await db.refresh(slide)
    logger.info("Built-in login slide restored by admin %s", admin.id)
    return _slide_response(slide)


@siteRouter.post("/login-slides", response_model=LoginSlideResponse, status_code=status.HTTP_201_CREATED)
async def upload_login_slide(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_super_admin),
):
    count = await db.scalar(select(func.count(LoginSlide.id))) or 0
    if count >= MAX_LOGIN_SLIDES:
        raise HTTPException(status_code=409, detail=f"A maximum of {MAX_LOGIN_SLIDES} slides is allowed")
    contents = await read_profile_image_upload(file, max_bytes=MAX_LOGIN_SLIDE_BYTES)
    try:
        stored_path = await run_in_threadpool(store_login_slide_image, contents)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    last_position = await db.scalar(select(func.max(LoginSlide.position)))
    slide = LoginSlide(image_path=stored_path, position=(last_position or 0) + 1)
    db.add(slide)
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        await run_in_threadpool(remove_profile_image, stored_path)
        raise
    await db.refresh(slide)
    logger.info("Login slide %s uploaded by admin %s", slide.id, admin.id)
    return _slide_response(slide)


@siteRouter.put("/login-slides/order", response_model=list[LoginSlideResponse])
async def reorder_login_slides(
    order: SlideOrder,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_super_admin),
):
    slides = {slide.id: slide for slide in await _ordered_slides(db)}
    if set(order.ids) != set(slides) or len(order.ids) != len(slides):
        raise HTTPException(status_code=422, detail="The order must list every slide exactly once")
    for position, slide_id in enumerate(order.ids, start=1):
        slides[slide_id].position = position
    await db.commit()
    return [_slide_response(slide) for slide in await _ordered_slides(db)]


@siteRouter.delete("/login-slides/{slide_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_login_slide(
    slide_id: int,
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_super_admin),
):
    slide = await db.get(LoginSlide, slide_id)
    if slide is None:
        raise HTTPException(status_code=404, detail="Slide not found")
    old_path = None if slide.is_builtin else slide.image_path  # the built-in file ships with the code
    await db.delete(slide)
    await db.commit()
    if old_path:
        await run_in_threadpool(remove_profile_image, old_path)
    logger.info("Login slide %s deleted by admin %s", slide_id, admin.id)
