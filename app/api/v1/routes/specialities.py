"""Specialities (تخصصات) of a school: circles per speciality with coefficients.

Chief supervisors and supervisors (and admins viewing a school) manage them; teachers can read.
"""
import logging
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, ConfigDict, Field, field_validator
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.dependencies import require_school_management_access, require_teacher_or_school_manager
from app.core.multi_tenancy import get_president_id_for_user
from app.db.session import get_db
from app.models.lecture import Lecture
from app.models.speciality import Speciality, SpecialityLecture
from app.models.student import Student
from app.services.specialities import sync_speciality_students

logger = logging.getLogger(__name__)
specialityRouter = APIRouter()


class SpecialityLectureIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    lecture_id: int
    coefficient: Decimal = Field(default=Decimal("1"), gt=0, le=100, max_digits=5, decimal_places=2)


class SpecialityIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    name: str = Field(min_length=1, max_length=150)
    description: str | None = Field(default=None, max_length=2000)
    is_common: bool = False
    lectures: list[SpecialityLectureIn] = Field(default_factory=list)

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Name is required")
        return value


class SpecialityLectureOut(BaseModel):
    lecture_id: int
    lecture_name_ar: str
    lecture_name_en: str | None = None
    coefficient: float


class SpecialityOut(BaseModel):
    id: int
    name: str
    description: str | None
    is_common: bool
    lectures: list[SpecialityLectureOut]
    student_count: int


async def _load(db: AsyncSession, president_id: int, speciality_id: int | None = None) -> list[Speciality]:
    query = (
        select(Speciality)
        .options(selectinload(Speciality.lectures).selectinload(SpecialityLecture.lecture))
        .where(Speciality.president_id == president_id)
        .order_by(Speciality.is_common.desc(), func.lower(Speciality.name))
    )
    if speciality_id is not None:
        query = query.where(Speciality.id == speciality_id)
    return list((await db.execute(query)).scalars().unique())


async def _out(db: AsyncSession, specialities: list[Speciality]) -> list[SpecialityOut]:
    counts = dict((await db.execute(
        select(Student.speciality_id, func.count(Student.id))
        .where(Student.speciality_id.in_([s.id for s in specialities] or [-1]))
        .group_by(Student.speciality_id)
    )).all())
    return [
        SpecialityOut(
            id=s.id,
            name=s.name,
            description=s.description,
            is_common=s.is_common,
            lectures=sorted(
                (SpecialityLectureOut(lecture_id=link.lecture_id, lecture_name_ar=link.lecture.lecture_name_ar,
                                      lecture_name_en=link.lecture.lecture_name_en, coefficient=float(link.coefficient))
                 for link in s.lectures if link.lecture is not None),
                key=lambda item: item.lecture_name_ar,
            ),
            student_count=counts.get(s.id, 0),
        )
        for s in specialities
    ]


async def _validate_lectures(db: AsyncSession, data: SpecialityIn, president_id: int) -> None:
    ids = [item.lecture_id for item in data.lectures]
    if len(ids) != len(set(ids)):
        raise HTTPException(status_code=422, detail="A circle can only be added once to a speciality")
    if ids:
        found = set((await db.execute(
            select(Lecture.id).where(Lecture.id.in_(ids), Lecture.president_id == president_id)
        )).scalars())
        if found != set(ids):
            raise HTTPException(status_code=404, detail="One or more circles were not found in this school")


async def _ensure_unique_name(db: AsyncSession, name: str, president_id: int, exclude_id: int | None = None) -> None:
    query = select(Speciality.id).where(Speciality.president_id == president_id, func.lower(Speciality.name) == name.lower())
    if exclude_id is not None:
        query = query.where(Speciality.id != exclude_id)
    if await db.scalar(query.limit(1)) is not None:
        raise HTTPException(status_code=409, detail="A speciality with this name already exists")


@specialityRouter.get("/", response_model=list[SpecialityOut])
async def list_specialities(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    return await _out(db, await _load(db, president_id))


@specialityRouter.post("/", response_model=SpecialityOut, status_code=status.HTTP_201_CREATED)
async def create_speciality(
    data: SpecialityIn,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
    school_id: int | None = None,
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    await _ensure_unique_name(db, data.name, president_id)
    await _validate_lectures(db, data, president_id)
    speciality = Speciality(
        president_id=president_id, name=data.name, description=(data.description or "").strip() or None,
        is_common=data.is_common,
        lectures=[SpecialityLecture(lecture_id=item.lecture_id, coefficient=item.coefficient) for item in data.lectures],
    )
    db.add(speciality)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(status_code=409, detail="A speciality with this name already exists") from exc
    logger.info("Speciality %s created by user %s", speciality.id, current_user.id)
    return (await _out(db, await _load(db, president_id, speciality.id)))[0]


@specialityRouter.put("/{speciality_id}", response_model=SpecialityOut)
async def update_speciality(
    speciality_id: int,
    data: SpecialityIn,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
    school_id: int | None = None,
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    found = await _load(db, president_id, speciality_id)
    if not found:
        raise HTTPException(status_code=404, detail="Speciality not found in this school")
    speciality = found[0]
    await _ensure_unique_name(db, data.name, president_id, exclude_id=speciality.id)
    await _validate_lectures(db, data, president_id)

    speciality.name = data.name
    speciality.description = (data.description or "").strip() or None
    speciality.is_common = data.is_common
    wanted = {item.lecture_id: item.coefficient for item in data.lectures}
    for link in list(speciality.lectures):
        if link.lecture_id not in wanted:
            speciality.lectures.remove(link)
        else:
            link.coefficient = wanted.pop(link.lecture_id)
    for lecture_id, coefficient in wanted.items():
        speciality.lectures.append(SpecialityLecture(lecture_id=lecture_id, coefficient=coefficient))
    await db.flush()

    # Students of this speciality follow its circles.
    synced = await sync_speciality_students(db, speciality.id)
    try:
        await db.commit()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(status_code=409, detail="A speciality with this name already exists") from exc
    logger.info("Speciality %s updated by user %s (%s students re-enrolled)", speciality.id, current_user.id, synced)
    return (await _out(db, await _load(db, president_id, speciality.id)))[0]


@specialityRouter.delete("/{speciality_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_speciality(
    speciality_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
    school_id: int | None = None,
):
    """Students keep their current circles; their speciality becomes empty (FK SET NULL)."""
    president_id = await get_president_id_for_user(current_user, db, school_id)
    speciality = await db.scalar(select(Speciality).where(Speciality.id == speciality_id, Speciality.president_id == president_id))
    if speciality is None:
        raise HTTPException(status_code=404, detail="Speciality not found in this school")
    await db.delete(speciality)
    await db.commit()
    logger.info("Speciality %s deleted by user %s", speciality_id, current_user.id)
