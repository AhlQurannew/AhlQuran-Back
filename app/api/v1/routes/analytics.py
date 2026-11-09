"""Admin BI analytics endpoint (drill-down: platform -> school -> circle -> student)."""
from datetime import date, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.clock import today_algeria
from app.core.dependencies import require_admin
from app.db.session import get_db
from app.services.analytics import ScopeNotFound, build_analytics

analyticsRouter = APIRouter()

MAX_RANGE_DAYS = 3 * 366


@analyticsRouter.get("/")
async def get_analytics(
    date_from: date | None = Query(None, description="Start of the period (inclusive); defaults to 90 days ago"),
    date_to: date | None = Query(None, description="End of the period (inclusive); defaults to today"),
    granularity: Literal["day", "week", "month"] | None = Query(None, description="Time bucket; picked from the range when omitted"),
    school_id: int | None = Query(None),
    lecture_id: int | None = Query(None),
    student_id: int | None = Query(None),
    db: AsyncSession = Depends(get_db),
    admin=Depends(require_admin),
):
    end = date_to or today_algeria()
    start = date_from or end - timedelta(days=89)
    if start > end:
        raise HTTPException(status_code=422, detail="date_from must be on or before date_to")
    if (end - start).days + 1 > MAX_RANGE_DAYS:
        raise HTTPException(status_code=422, detail="The period cannot exceed 3 years")
    try:
        return await build_analytics(
            db, start=start, end=end, granularity=granularity,
            school_id=school_id, lecture_id=lecture_id, student_id=student_id,
        )
    except ScopeNotFound as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc
