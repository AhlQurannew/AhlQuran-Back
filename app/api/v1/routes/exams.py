"""Exams (امتحانات) per circle: CRUD, roster, attendance, marks, notes and ranking.

Chief supervisors and supervisors (and admins viewing a school) manage every exam of the school;
teachers manage the exams of their own circles.
"""
import logging
from collections import defaultdict
from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.clock import today_algeria
from app.core.dependencies import require_teacher_or_school_manager
from app.core.multi_tenancy import get_creator_user_id, get_president_id_for_user
from app.db.session import get_db
from app.models.exam import Exam, ExamResult
from app.models.lecture import Lecture, lecture_teachers
from app.models.sessionParticipation import SessionParticipation
from app.models.speciality import Speciality, SpecialityLecture
from app.models.student import Student
from app.models.teacher import Teacher
from app.models.user import User, UserRoleEnum
from app.services.exams import ATTENDANCE_VALUES, MarkRow, competition_ranks, exam_stats, rank_values, weighted_average

logger = logging.getLogger(__name__)
examRouter = APIRouter()

EXAM_TYPES = ("monthly", "term", "final", "tajwid", "other")


# ---------------------------------------------------------------- schemas

class ExamIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    lecture_id: int
    title: str = Field(min_length=1, max_length=200)
    exam_type: str | None = None
    exam_date: date
    max_mark: Decimal = Field(default=Decimal("20"), gt=0, le=1000, max_digits=6, decimal_places=2)
    pass_mark: Decimal = Field(default=Decimal("10"), ge=0, le=1000, max_digits=6, decimal_places=2)
    notes: str | None = Field(default=None, max_length=4000)

    @field_validator("title")
    @classmethod
    def strip_title(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Title is required")
        return value

    @field_validator("exam_type")
    @classmethod
    def check_type(cls, value: str | None) -> str | None:
        if value in (None, ""):
            return None
        if value not in EXAM_TYPES:
            raise ValueError(f"exam_type must be one of {', '.join(EXAM_TYPES)}")
        return value

    @model_validator(mode="after")
    def check_pass_mark(self):
        if self.pass_mark > self.max_mark:
            raise ValueError("The pass mark cannot exceed the maximum mark")
        return self


class ResultIn(BaseModel):
    model_config = ConfigDict(extra="forbid")

    student_id: int
    attendance: str = "present"
    mark: Decimal | None = Field(default=None, ge=0, max_digits=6, decimal_places=2)
    notes: str | None = Field(default=None, max_length=2000)

    @field_validator("attendance")
    @classmethod
    def check_attendance(cls, value: str) -> str:
        if value not in ATTENDANCE_VALUES:
            raise ValueError(f"attendance must be one of {', '.join(ATTENDANCE_VALUES)}")
        return value


class ResultsIn(BaseModel):
    """The full roster of the exam: students missing from the list are removed from it."""
    model_config = ConfigDict(extra="forbid")

    results: list[ResultIn]


class ExamStats(BaseModel):
    total: int
    present: int
    absent: int
    excused: int
    graded: int
    pending: int
    average: float | None
    average_pct: float | None
    highest: float | None
    lowest: float | None
    passed: int
    pass_rate: float | None
    attendance_rate: float | None


class ExamOut(BaseModel):
    id: int
    title: str
    exam_type: str | None
    exam_date: date
    lecture_id: int
    lecture_name_ar: str
    lecture_name_en: str | None
    max_mark: float
    pass_mark: float
    notes: str | None
    can_edit: bool
    stats: ExamStats


class ResultOut(BaseModel):
    student_id: int
    name: str
    registration_number: str | None
    speciality_name: str | None
    attendance: str
    mark: float | None
    percent: float | None
    passed: bool | None
    rank: int | None
    notes: str | None


class CandidateOut(BaseModel):
    student_id: int
    name: str
    registration_number: str | None
    in_lecture: bool


class ExamDetailOut(ExamOut):
    results: list[ResultOut]
    candidates: list[CandidateOut]


class SpecialityStandingRow(BaseModel):
    student_id: int
    name: str
    registration_number: str | None
    average_pct: float | None
    average_20: float | None
    rank: int | None
    circles_graded: int


class SpecialityStandingOut(BaseModel):
    speciality_id: int
    speciality_name: str
    circles: list[dict]
    rows: list[SpecialityStandingRow]


class ExamOverviewOut(BaseModel):
    exam_count: int
    upcoming_count: int
    graded_results: int
    average_pct: float | None
    pass_rate: float | None
    attendance_rate: float | None
    speciality_count: int
    specialities: list[dict]
    recent: list[ExamOut]
    upcoming: list[ExamOut]
    by_lecture: list[dict]


# ---------------------------------------------------------------- scope

class _Scope:
    def __init__(self, president_id: int, lecture_ids: set[int] | None, user_id: int):
        self.president_id = president_id
        self.lecture_ids = lecture_ids  # None = whole school
        self.user_id = user_id

    def can_manage(self, lecture_id: int) -> bool:
        return self.lecture_ids is None or lecture_id in self.lecture_ids


async def _scope(db: AsyncSession, current_user, school_id: int | None) -> _Scope:
    president_id = await get_president_id_for_user(current_user, db, school_id)
    user_id = await get_creator_user_id(current_user, president_id, db)
    role = getattr(getattr(current_user, "role", None), "value", getattr(current_user, "role", None))
    if role != UserRoleEnum.TEACHER.value:
        return _Scope(president_id, None, user_id)
    ids = set((await db.execute(
        select(lecture_teachers.c.lecture_id)
        .join(Teacher, Teacher.id == lecture_teachers.c.teacher_id)
        .join(Lecture, Lecture.id == lecture_teachers.c.lecture_id)
        .where(Teacher.user_id == current_user.id, Lecture.president_id == president_id)
    )).scalars())
    return _Scope(president_id, ids, user_id)


def _scoped(query, scope: _Scope):
    query = query.where(Exam.president_id == scope.president_id)
    if scope.lecture_ids is not None:
        query = query.where(Exam.lecture_id.in_(scope.lecture_ids or {-1}))
    return query


async def _get_exam(db: AsyncSession, scope: _Scope, exam_id: int) -> Exam:
    exam = await db.scalar(
        _scoped(select(Exam), scope)
        .options(selectinload(Exam.lecture), selectinload(Exam.results))
        .where(Exam.id == exam_id)
        .execution_options(populate_existing=True)
    )
    if exam is None:
        raise HTTPException(status_code=404, detail="Exam not found")
    return exam


async def _check_lecture(db: AsyncSession, scope: _Scope, lecture_id: int) -> Lecture:
    lecture = await db.scalar(select(Lecture).where(Lecture.id == lecture_id, Lecture.president_id == scope.president_id))
    if lecture is None:
        raise HTTPException(status_code=404, detail="Circle not found in this school")
    if not scope.can_manage(lecture_id):
        raise HTTPException(status_code=403, detail="You can only manage exams of your own circles")
    return lecture


async def _lecture_student_ids(db: AsyncSession, lecture_ids: set[int] | list[int]) -> dict[int, set[int]]:
    rows = (await db.execute(
        select(SessionParticipation.lecture_id, SessionParticipation.student_id)
        .where(SessionParticipation.lecture_id.in_(list(lecture_ids) or [-1]))
        .distinct()
    )).all()
    out: dict[int, set[int]] = defaultdict(set)
    for lecture_id, student_id in rows:
        out[lecture_id].add(student_id)
    return out


async def _student_info(db: AsyncSession, student_ids) -> dict[int, dict]:
    rows = (await db.execute(
        select(Student.id, User.firstname, User.lastname, Student.registration_number, Speciality.name)
        .join(User, User.id == Student.user_id)
        .outerjoin(Speciality, Speciality.id == Student.speciality_id)
        .where(Student.id.in_(list(student_ids) or [-1]))
    )).all()
    return {
        sid: {"name": f"{first or ''} {last or ''}".strip(), "registration_number": reg, "speciality_name": spec}
        for sid, first, last, reg, spec in rows
    }


def _mark_rows(exam: Exam) -> list[MarkRow]:
    return [
        MarkRow(r.student_id, r.attendance, float(r.mark) if r.mark is not None else None)
        for r in exam.results
    ]


def _exam_out(exam: Exam, scope: _Scope) -> ExamOut:
    return ExamOut(
        id=exam.id, title=exam.title, exam_type=exam.exam_type, exam_date=exam.exam_date,
        lecture_id=exam.lecture_id,
        lecture_name_ar=exam.lecture.lecture_name_ar if exam.lecture else "",
        lecture_name_en=exam.lecture.lecture_name_en if exam.lecture else None,
        max_mark=float(exam.max_mark), pass_mark=float(exam.pass_mark), notes=exam.notes,
        can_edit=scope.can_manage(exam.lecture_id),
        stats=ExamStats(**exam_stats(_mark_rows(exam), float(exam.max_mark), float(exam.pass_mark))),
    )


async def _detail(db: AsyncSession, scope: _Scope, exam: Exam) -> ExamDetailOut:
    rows = _mark_rows(exam)
    ranks = competition_ranks(rows)
    lecture_students = (await _lecture_student_ids(db, [exam.lecture_id])).get(exam.lecture_id, set())
    roster = {r.student_id for r in exam.results}

    # Students that can be added: the circle's students first, then any student of the
    # circles the user manages (whole school for managers).
    if scope.lecture_ids is None:
        pool = set((await db.execute(select(Student.id).where(Student.president_id == scope.president_id))).scalars())
    else:
        pool = set().union(*(await _lecture_student_ids(db, scope.lecture_ids)).values()) if scope.lecture_ids else set()
    pool |= lecture_students
    candidates_ids = pool - roster
    info = await _student_info(db, roster | candidates_ids)

    max_mark, pass_mark = float(exam.max_mark), float(exam.pass_mark)
    results = []
    for r in exam.results:
        mark = float(r.mark) if r.mark is not None else None
        graded = r.attendance == "present" and mark is not None
        meta = info.get(r.student_id, {})
        results.append(ResultOut(
            student_id=r.student_id, name=meta.get("name", ""), registration_number=meta.get("registration_number"),
            speciality_name=meta.get("speciality_name"), attendance=r.attendance, mark=mark,
            percent=round(mark / max_mark * 100, 1) if graded else None,
            passed=(mark >= pass_mark) if graded else None,
            rank=ranks.get(r.student_id), notes=r.notes,
        ))
    results.sort(key=lambda item: (item.rank is None, item.rank or 0, item.name))
    candidates = sorted(
        (CandidateOut(student_id=sid, name=info.get(sid, {}).get("name", ""),
                      registration_number=info.get(sid, {}).get("registration_number"),
                      in_lecture=sid in lecture_students)
         for sid in candidates_ids if sid in info),
        key=lambda item: (not item.in_lecture, item.name),
    )
    return ExamDetailOut(**_exam_out(exam, scope).model_dump(), results=results, candidates=candidates)


# ---------------------------------------------------------------- routes

@examRouter.get("/", response_model=list[ExamOut])
async def list_exams(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
    lecture_id: int | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
):
    scope = await _scope(db, current_user, school_id)
    query = _scoped(select(Exam), scope).options(selectinload(Exam.lecture), selectinload(Exam.results))
    if lecture_id is not None:
        query = query.where(Exam.lecture_id == lecture_id)
    if date_from is not None:
        query = query.where(Exam.exam_date >= date_from)
    if date_to is not None:
        query = query.where(Exam.exam_date <= date_to)
    exams = (await db.execute(query.order_by(Exam.exam_date.desc(), Exam.id.desc()))).scalars().unique()
    return [_exam_out(exam, scope) for exam in exams]


@examRouter.get("/overview", response_model=ExamOverviewOut)
async def exams_overview(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    """Dashboard summary: counts, averages, recent/upcoming exams, circles and specialities."""
    scope = await _scope(db, current_user, school_id)
    exams = list((await db.execute(
        _scoped(select(Exam), scope).options(selectinload(Exam.lecture), selectinload(Exam.results))
        .order_by(Exam.exam_date.desc(), Exam.id.desc())
    )).scalars().unique())
    today = today_algeria()
    past = [e for e in exams if e.exam_date <= today]
    upcoming = sorted((e for e in exams if e.exam_date > today), key=lambda e: e.exam_date)

    all_rows = [(row, e) for e in past for row in _mark_rows(e)]
    graded = [(row, e) for row, e in all_rows if row.attendance == "present" and row.mark is not None]
    pct = [row.mark / float(e.max_mark) * 100 for row, e in graded]
    passed = sum(1 for row, e in graded if row.mark >= float(e.pass_mark))
    present = sum(1 for row, _ in all_rows if row.attendance == "present")

    per_lecture: dict[int, list[float]] = defaultdict(list)
    lecture_names: dict[int, tuple[str, str | None]] = {}
    exam_counts: dict[int, int] = defaultdict(int)
    for e in past:
        exam_counts[e.lecture_id] += 1
        if e.lecture:
            lecture_names[e.lecture_id] = (e.lecture.lecture_name_ar, e.lecture.lecture_name_en)
    for row, e in graded:
        per_lecture[e.lecture_id].append(row.mark / float(e.max_mark) * 100)
    by_lecture = sorted(
        ({"lecture_id": lid, "lecture_name_ar": lecture_names.get(lid, ("", None))[0],
          "lecture_name_en": lecture_names.get(lid, ("", None))[1], "exam_count": exam_counts[lid],
          "average_pct": round(sum(v) / len(v), 1) if v else None}
         for lid, v in ((lid, per_lecture.get(lid, [])) for lid in exam_counts)),
        key=lambda item: (item["average_pct"] is None, -(item["average_pct"] or 0)),
    )

    specialities = await _speciality_summaries(db, scope)
    return ExamOverviewOut(
        exam_count=len(exams), upcoming_count=len(upcoming), graded_results=len(graded),
        average_pct=round(sum(pct) / len(pct), 1) if pct else None,
        pass_rate=round(passed / len(graded) * 100, 1) if graded else None,
        attendance_rate=round(present / len(all_rows) * 100, 1) if all_rows else None,
        speciality_count=len(specialities), specialities=specialities,
        recent=[_exam_out(e, scope) for e in past[:5]],
        upcoming=[_exam_out(e, scope) for e in upcoming[:5]],
        by_lecture=by_lecture,
    )


async def _standings(db: AsyncSession, president_id: int, speciality: Speciality,
                     date_from: date | None = None, date_to: date | None = None) -> SpecialityStandingOut:
    coefficients = {link.lecture_id: float(link.coefficient) for link in speciality.lectures}
    student_ids = list((await db.execute(select(Student.id).where(Student.speciality_id == speciality.id))).scalars())
    query = (
        select(ExamResult.student_id, Exam.lecture_id, ExamResult.mark, Exam.max_mark)
        .join(Exam, Exam.id == ExamResult.exam_id)
        .where(Exam.president_id == president_id, ExamResult.student_id.in_(student_ids or [-1]),
               Exam.lecture_id.in_(list(coefficients) or [-1]), ExamResult.attendance == "present",
               ExamResult.mark.is_not(None))
    )
    if date_from is not None:
        query = query.where(Exam.exam_date >= date_from)
    if date_to is not None:
        query = query.where(Exam.exam_date <= date_to)
    sums: dict[int, dict[int, list[float]]] = defaultdict(lambda: defaultdict(list))
    for student_id, lecture_id, mark, max_mark in (await db.execute(query)).all():
        sums[student_id][lecture_id].append(float(mark) / float(max_mark) * 100)
    averages: dict[int, float] = {}
    graded_counts: dict[int, int] = {}
    for student_id, by_lecture in sums.items():
        per_lecture = {lid: sum(v) / len(v) for lid, v in by_lecture.items()}
        value = weighted_average(per_lecture, coefficients)
        if value is not None:
            averages[student_id] = value
            graded_counts[student_id] = len(per_lecture)
    ranks = rank_values(averages)
    info = await _student_info(db, student_ids)
    rows = sorted(
        (SpecialityStandingRow(
            student_id=sid, name=info.get(sid, {}).get("name", ""),
            registration_number=info.get(sid, {}).get("registration_number"),
            average_pct=averages.get(sid), average_20=round(averages[sid] / 5, 2) if sid in averages else None,
            rank=ranks.get(sid), circles_graded=graded_counts.get(sid, 0))
         for sid in student_ids),
        key=lambda row: (row.rank is None, row.rank or 0, row.name),
    )
    circles = sorted(
        ({"lecture_id": link.lecture_id, "lecture_name_ar": link.lecture.lecture_name_ar if link.lecture else "",
          "lecture_name_en": link.lecture.lecture_name_en if link.lecture else None,
          "coefficient": float(link.coefficient)} for link in speciality.lectures),
        key=lambda item: item["lecture_name_ar"],
    )
    return SpecialityStandingOut(speciality_id=speciality.id, speciality_name=speciality.name, circles=circles, rows=rows)


async def _load_specialities(db: AsyncSession, president_id: int, speciality_id: int | None = None) -> list[Speciality]:
    query = (
        select(Speciality)
        .options(selectinload(Speciality.lectures).selectinload(SpecialityLecture.lecture))
        .where(Speciality.president_id == president_id)
        .order_by(Speciality.is_common.desc(), func.lower(Speciality.name))
    )
    if speciality_id is not None:
        query = query.where(Speciality.id == speciality_id)
    return list((await db.execute(query)).scalars().unique())


async def _speciality_summaries(db: AsyncSession, scope: _Scope) -> list[dict]:
    """Per speciality: students, circles, weighted average and the top 3 students."""
    out = []
    for speciality in await _load_specialities(db, scope.president_id):
        if scope.lecture_ids is not None and not ({l.lecture_id for l in speciality.lectures} & scope.lecture_ids):
            continue
        standing = await _standings(db, scope.president_id, speciality)
        values = [row.average_pct for row in standing.rows if row.average_pct is not None]
        out.append({
            "speciality_id": speciality.id, "name": speciality.name, "is_common": speciality.is_common,
            "student_count": len(standing.rows), "circle_count": len(standing.circles),
            "average_pct": round(sum(values) / len(values), 1) if values else None,
            "ranked_count": len(values),
            "top": [row.model_dump() for row in standing.rows if row.rank is not None][:3],
        })
    return out


@examRouter.get("/specialities/{speciality_id}/standings", response_model=SpecialityStandingOut)
async def speciality_standings(
    speciality_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
    date_from: date | None = None,
    date_to: date | None = None,
):
    """Coefficient-weighted average and rank of each student of a speciality."""
    scope = await _scope(db, current_user, school_id)
    found = await _load_specialities(db, scope.president_id, speciality_id)
    if not found:
        raise HTTPException(status_code=404, detail="Speciality not found in this school")
    # Teachers only see the rankings of specialities that include one of their circles.
    if scope.lecture_ids is not None and not ({link.lecture_id for link in found[0].lectures} & scope.lecture_ids):
        raise HTTPException(status_code=404, detail="Speciality not found in this school")
    return await _standings(db, scope.president_id, found[0], date_from, date_to)


@examRouter.get("/lectures")
async def manageable_lectures(
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    """Circles the user can hold exams for (their own for teachers), with their student counts."""
    scope = await _scope(db, current_user, school_id)
    query = select(Lecture).where(Lecture.president_id == scope.president_id)
    if scope.lecture_ids is not None:
        query = query.where(Lecture.id.in_(scope.lecture_ids or {-1}))
    lectures = list((await db.execute(query.order_by(Lecture.lecture_name_ar))).scalars())
    students = await _lecture_student_ids(db, [l.id for l in lectures])
    return [
        {"lecture_id": l.id, "lecture_name_ar": l.lecture_name_ar, "lecture_name_en": l.lecture_name_en,
         "student_count": len(students.get(l.id, set()))}
        for l in lectures
    ]


@examRouter.get("/{exam_id}", response_model=ExamDetailOut)
async def get_exam(
    exam_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    scope = await _scope(db, current_user, school_id)
    return await _detail(db, scope, await _get_exam(db, scope, exam_id))


@examRouter.post("/", response_model=ExamDetailOut, status_code=status.HTTP_201_CREATED)
async def create_exam(
    data: ExamIn,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
    include_students: bool = Query(default=True, description="Add the circle's students to the roster"),
):
    scope = await _scope(db, current_user, school_id)
    await _check_lecture(db, scope, data.lecture_id)
    exam = Exam(
        president_id=scope.president_id, lecture_id=data.lecture_id, title=data.title, exam_type=data.exam_type,
        exam_date=data.exam_date, max_mark=data.max_mark, pass_mark=data.pass_mark,
        notes=(data.notes or "").strip() or None, created_by_id=scope.user_id,
    )
    if include_students:
        students = (await _lecture_student_ids(db, [data.lecture_id])).get(data.lecture_id, set())
        exam.results = [ExamResult(student_id=sid, attendance="present") for sid in sorted(students)]
    db.add(exam)
    await db.commit()
    logger.info("Exam %s created by user %s", exam.id, scope.user_id)
    return await _detail(db, scope, await _get_exam(db, scope, exam.id))


@examRouter.put("/{exam_id}", response_model=ExamDetailOut)
async def update_exam(
    exam_id: int,
    data: ExamIn,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    scope = await _scope(db, current_user, school_id)
    exam = await _get_exam(db, scope, exam_id)
    if not scope.can_manage(exam.lecture_id):
        raise HTTPException(status_code=403, detail="You can only manage exams of your own circles")
    if data.lecture_id != exam.lecture_id:
        await _check_lecture(db, scope, data.lecture_id)
        if any(r.mark is not None for r in exam.results):
            raise HTTPException(status_code=409, detail="The circle cannot be changed once marks have been entered")
        students = (await _lecture_student_ids(db, [data.lecture_id])).get(data.lecture_id, set())
        exam.results.clear()
        await db.flush()
        exam.results.extend(ExamResult(student_id=sid, attendance="present") for sid in sorted(students))
    over = [r for r in exam.results if r.mark is not None and r.mark > data.max_mark]
    if over:
        raise HTTPException(status_code=422, detail="Some marks are higher than the new maximum mark")
    exam.lecture_id = data.lecture_id
    exam.title = data.title
    exam.exam_type = data.exam_type
    exam.exam_date = data.exam_date
    exam.max_mark = data.max_mark
    exam.pass_mark = data.pass_mark
    exam.notes = (data.notes or "").strip() or None
    await db.commit()
    logger.info("Exam %s updated by user %s", exam.id, scope.user_id)
    return await _detail(db, scope, await _get_exam(db, scope, exam.id))


@examRouter.put("/{exam_id}/results", response_model=ExamDetailOut)
async def save_results(
    exam_id: int,
    data: ResultsIn,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    """Replace the roster with its attendance, marks and notes; returns the ranked results."""
    scope = await _scope(db, current_user, school_id)
    exam = await _get_exam(db, scope, exam_id)
    if not scope.can_manage(exam.lecture_id):
        raise HTTPException(status_code=403, detail="You can only manage exams of your own circles")

    ids = [item.student_id for item in data.results]
    if len(ids) != len(set(ids)):
        raise HTTPException(status_code=422, detail="A student can only appear once in an exam")
    found = set((await db.execute(
        select(Student.id).where(Student.id.in_(ids or [-1]), Student.president_id == scope.president_id)
    )).scalars())
    if found != set(ids):
        raise HTTPException(status_code=404, detail="One or more students were not found in this school")
    if scope.lecture_ids is not None:
        existing = {r.student_id for r in exam.results}
        allowed = set().union(*(await _lecture_student_ids(db, scope.lecture_ids)).values()) if scope.lecture_ids else set()
        if set(ids) - existing - allowed:
            raise HTTPException(status_code=403, detail="You can only add students of your own circles")
    for item in data.results:
        if item.mark is not None and item.mark > exam.max_mark:
            raise HTTPException(status_code=422, detail="A mark cannot be higher than the maximum mark")

    current = {r.student_id: r for r in exam.results}
    wanted = {item.student_id: item for item in data.results}
    for student_id, result in current.items():
        if student_id not in wanted:
            exam.results.remove(result)
    for student_id, item in wanted.items():
        result = current.get(student_id)
        if result is None:
            result = ExamResult(student_id=student_id)
            exam.results.append(result)
        result.attendance = item.attendance
        result.mark = item.mark if item.attendance == "present" else None
        result.notes = (item.notes or "").strip() or None
    await db.commit()
    logger.info("Exam %s results saved by user %s (%s students)", exam.id, scope.user_id, len(wanted))
    return await _detail(db, scope, await _get_exam(db, scope, exam.id))


@examRouter.delete("/{exam_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_exam(
    exam_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_teacher_or_school_manager),
    school_id: int | None = None,
):
    scope = await _scope(db, current_user, school_id)
    exam = await _get_exam(db, scope, exam_id)
    if not scope.can_manage(exam.lecture_id):
        raise HTTPException(status_code=403, detail="You can only manage exams of your own circles")
    await db.delete(exam)
    await db.commit()
    logger.info("Exam %s deleted by user %s", exam_id, scope.user_id)
