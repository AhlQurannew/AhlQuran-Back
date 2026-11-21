"""Download a full backup of the platform, or restore one. Main administrator only."""
import logging
from datetime import datetime

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.clock import _ALGERIA as ALGERIA_TZ
from app.core.config import settings
from app.core.dependencies import require_super_admin
from app.db.session import get_db
from app.services.backup import BackupError, build_backup, read_backup, restore_backup, write_files

logger = logging.getLogger(__name__)
backupRouter = APIRouter()

MAX_UPLOAD_BYTES = 300 * 1024 * 1024


async def require_main_admin(admin=Depends(require_super_admin)):
    """Only the main administrator (not created by another admin) may export or replace all data."""
    if getattr(admin, "created_by_id", None) is not None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only the main administrator can do this")
    return admin


@backupRouter.get("/")
async def download_backup(db: AsyncSession = Depends(get_db), admin=Depends(require_main_admin)):
    conn = await db.connection()
    content = await build_backup(conn, settings.UPLOAD_DIR)
    stamp = datetime.now(ALGERIA_TZ).strftime("%Y-%m-%d_%H-%M-%S")
    logger.info("Backup downloaded by admin %s (%d bytes)", admin.id, len(content))
    return Response(
        content,
        media_type="application/zip",
        headers={"Content-Disposition": f'attachment; filename="ahlquran-backup-{stamp}.zip"', "Cache-Control": "no-store"},
    )


@backupRouter.post("/restore")
async def restore(file: UploadFile = File(...), db: AsyncSession = Depends(get_db), admin=Depends(require_main_admin)):
    raw = await file.read(MAX_UPLOAD_BYTES + 1)
    if len(raw) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="The backup is too large")
    try:
        data, files = await run_in_threadpool(read_backup, raw)
        conn = await db.connection()
        counts = await restore_backup(conn, data)
    except BackupError as exc:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc)) from exc
    await db.commit()
    written = await run_in_threadpool(write_files, settings.UPLOAD_DIR, files)
    logger.warning("Backup from %s restored by admin %s: %d rows, %d files", data.get("created_at"), admin.id, sum(counts.values()), written)
    return {"created_at": data.get("created_at"), "rows": sum(counts.values()), "files": written, "tables": counts}
