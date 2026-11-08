"""Admin BI analytics: platform -> school -> circle (lecture) -> student, over a date range.

The aggregation helpers are pure functions over plain rows so they can be unit-tested
without a database; `build_analytics` loads the rows for a scope and assembles the payload.
"""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Iterable, Literal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.quran_pages import calculate_achievement_pages
from app.models.acheivements import Achievement
from app.models.attendance import Attendance
from app.models.lecture import Lecture, lecture_teachers
from app.models.president import President
from app.models.sessionParticipation import SessionParticipation
from app.models.student import Student
from app.models.teacher import Teacher
from app.models.user import User

Granularity = Literal["day", "week", "month"]
Level = Literal["platform", "school", "lecture", "student"]

ATTENDED = {"present", "late"}
STATUSES = ("present", "late", "excused", "absent")
ACHIEVEMENT_TYPES = ("normal", "small", "big")  # memorization, minor review, major review
MAX_BUCKETS = 400
MIN_RECORDS_FOR_HEALTH = 3
GOOD_RATE, WARNING_RATE = 85.0, 70.0
ALERT_LIMIT = 20
TOP_LIMIT = 5
MIN_RECORDS_FOR_TOP = 5  # sessions needed before a student can be ranked among the top
# Composite score weights: attendance, memorisation (pages vs. the group's best), exam average.
TOP_WEIGHTS = {"attendance": 0.35, "pages": 0.35, "exams": 0.30}


@dataclass(frozen=True)
class AttendanceRow:
    student_id: int
    school_id: int | None
    lecture_id: int | None
    day: date
    status: str


@dataclass(frozen=True)
class AchievementRow:
    student_id: int
    school_id: int | None
    day: date
    kind: str
    pages: float


# ---------------------------------------------------------------- pure helpers


def parse_achievement_day(value: str | None, created_at: datetime | None) -> date | None:
    """Achievements store their date as DD-MM-YYYY text; fall back to the creation time."""
    if value:
        for fmt in ("%d-%m-%Y", "%Y-%m-%d"):
            try:
                return datetime.strptime(value, fmt).date()
            except ValueError:
                continue
    return created_at.date() if created_at else None


def default_granularity(start: date, end: date) -> Granularity:
    days = (end - start).days + 1
    return "day" if days <= 31 else "week" if days <= 184 else "month"


def bucket_start(day: date, granularity: Granularity) -> date:
    if granularity == "day":
        return day
    if granularity == "week":
        return day - timedelta(days=day.weekday())  # ISO week, Monday first
    return day.replace(day=1)


def next_bucket(day: date, granularity: Granularity) -> date:
    if granularity == "day":
        return day + timedelta(days=1)
    if granularity == "week":
        return day + timedelta(days=7)
    return (day.replace(day=28) + timedelta(days=4)).replace(day=1)


def bucket_starts(start: date, end: date, granularity: Granularity) -> list[date]:
    buckets, cursor = [], bucket_start(start, granularity)
    while cursor <= end:
        buckets.append(cursor)
        cursor = next_bucket(cursor, granularity)
    return buckets


def coarsen(start: date, end: date, granularity: Granularity) -> Granularity:
    """Step up to a coarser bucket when the requested one would draw too many points."""
    order: list[Granularity] = ["day", "week", "month"]
    for candidate in order[order.index(granularity):]:
        if len(bucket_starts(start, end, candidate)) <= MAX_BUCKETS:
            return candidate
    return "month"


def rate(attended: int, total: int) -> float | None:
    return round(attended * 100 / total, 1) if total else None


def health(attendance_rate: float | None, records: int) -> str:
    """good / warning / critical by attendance, or "insufficient" when there is too little data."""
    if attendance_rate is None or records < MIN_RECORDS_FOR_HEALTH:
        return "insufficient"
    if attendance_rate >= GOOD_RATE:
        return "good"
    return "warning" if attendance_rate >= WARNING_RATE else "critical"


def summarize(attendance: Iterable[AttendanceRow], achievements: Iterable[AchievementRow]) -> dict:
    statuses = dict.fromkeys(STATUSES, 0)
    for row in attendance:
        statuses[row.status] = statuses.get(row.status, 0) + 1
    pages_by_kind = dict.fromkeys(ACHIEVEMENT_TYPES, 0.0)
    count = 0
    for row in achievements:
        pages_by_kind[row.kind] = pages_by_kind.get(row.kind, 0.0) + row.pages
        count += 1
    total = sum(statuses.values())
    attended = sum(statuses[s] for s in ATTENDED)
    return {
        "attendance_records": total,
        "attendance_rate": rate(attended, total),
        "status_breakdown": statuses,
        "achievements": count,
        "pages": round(sum(pages_by_kind.values()), 1),
        "pages_by_type": {k: round(v, 1) for k, v in pages_by_kind.items()},
    }


def build_series(
    attendance: Iterable[AttendanceRow],
    achievements: Iterable[AchievementRow],
    start: date,
    end: date,
    granularity: Granularity,
) -> list[dict]:
    buckets = bucket_starts(start, end, granularity)
    att: dict[date, list[AttendanceRow]] = defaultdict(list)
    ach: dict[date, list[AchievementRow]] = defaultdict(list)
    for row in attendance:
        att[bucket_start(row.day, granularity)].append(row)
    for row in achievements:
        ach[bucket_start(row.day, granularity)].append(row)
    series = []
    for bucket in buckets:
        summary = summarize(att.get(bucket, []), ach.get(bucket, []))
        series.append({
            "bucket": bucket.isoformat(),
            "attendance_rate": summary["attendance_rate"],
            "attendance_records": summary["attendance_records"],
            **{status: summary["status_breakdown"][status] for status in STATUSES},
            "achievements": summary["achievements"],
            "pages": summary["pages"],
            **{f"pages_{kind}": summary["pages_by_type"][kind] for kind in ACHIEVEMENT_TYPES},
        })
    return series


def in_period(day: date, start: date, end: date) -> bool:
    return start <= day <= end


def entity_rows(
    entities: dict[int, dict],
    attendance: list[AttendanceRow],
    achievements: list[AchievementRow],
    key_attendance,
    key_achievement,
    students_of: dict[int, set[int]],
) -> list[dict]:
    """One row per entity (school / lecture / student) with its period summary and health."""
    att: dict[int, list[AttendanceRow]] = defaultdict(list)
    ach: dict[int, list[AchievementRow]] = defaultdict(list)
    for row in attendance:
        for key in key_attendance(row):
            att[key].append(row)
    for row in achievements:
        for key in key_achievement(row):
            ach[key].append(row)
    rows = []
    for entity_id, info in entities.items():
        summary = summarize(att.get(entity_id, []), ach.get(entity_id, []))
        members = students_of.get(entity_id, set())
        active = {r.student_id for r in att.get(entity_id, [])} | {r.student_id for r in ach.get(entity_id, [])}
        days = [r.day for r in att.get(entity_id, [])] + [r.day for r in ach.get(entity_id, [])]
        rows.append({
            **info,
            "id": entity_id,
            "students": len(members),
            "active_students": len(active & members) if members else len(active),
            "attendance_rate": summary["attendance_rate"],
            "attendance_records": summary["attendance_records"],
            "status_breakdown": summary["status_breakdown"],
            "achievements": summary["achievements"],
            "pages": summary["pages"],
            "last_activity": max(days).isoformat() if days else None,
            "health": health(summary["attendance_rate"], summary["attendance_records"]),
        })
    return rows


def student_alerts(
    students: dict[int, dict],
    attendance: list[AttendanceRow],
    achievements: list[AchievementRow],
) -> list[dict]:
    """Students needing attention: low attendance, or enrolled with no activity in the period."""
    att: dict[int, list[AttendanceRow]] = defaultdict(list)
    pages: dict[int, float] = defaultdict(float)
    for row in attendance:
        att[row.student_id].append(row)
    for row in achievements:
        pages[row.student_id] += row.pages
    alerts = []
    for student_id, info in students.items():
        records = att.get(student_id, [])
        attended = sum(1 for r in records if r.status in ATTENDED)
        student_rate = rate(attended, len(records))
        if not records and student_id not in pages:
            reason = "no_activity"
        elif student_rate is not None and len(records) >= MIN_RECORDS_FOR_HEALTH and student_rate < WARNING_RATE:
            reason = "low_attendance"
        else:
            continue
        alerts.append({
            **info,
            "id": student_id,
            "reason": reason,
            "attendance_rate": student_rate,
            "attendance_records": len(records),
            "pages": round(pages.get(student_id, 0.0), 1),
        })
    alerts.sort(key=lambda a: (a["reason"] != "low_attendance", a["attendance_rate"] if a["attendance_rate"] is not None else 101))
    return alerts[:ALERT_LIMIT]


def top_students(
    students: dict[int, dict],
    attendance: list[AttendanceRow],
    achievements: list[AchievementRow],
    exam_avg: dict[int, float],
    limit: int = TOP_LIMIT,
) -> list[dict]:
    """Top students per school and schooling mode (internal = full time, external = part time).

    Score (0-100) = weighted mean of attendance rate, memorised pages relative to the best of the
    same group, and exam average; a missing component (e.g. no exam yet) is left out of the weights.
    """
    att: dict[int, list[AttendanceRow]] = defaultdict(list)
    pages: dict[int, float] = defaultdict(float)
    for row in attendance:
        att[row.student_id].append(row)
    for row in achievements:
        pages[row.student_id] += row.pages

    groups: dict[tuple, list[dict]] = defaultdict(list)
    for student_id, info in students.items():
        records = att.get(student_id, [])
        if len(records) < MIN_RECORDS_FOR_TOP:
            continue
        mode = "external" if info.get("enrollment_type") == "external" else "internal"
        groups[(info.get("school_id"), mode)].append({
            "id": student_id,
            "name": info["name"],
            "name_en": info.get("name_en"),
            "attendance_rate": rate(sum(1 for r in records if r.status in ATTENDED), len(records)),
            "pages": round(pages.get(student_id, 0.0), 1),
            "exam_average": exam_avg.get(student_id),
        })

    out: dict = {}
    for (school_id, mode), members in groups.items():
        best_pages = max((m["pages"] for m in members), default=0) or 0
        for m in members:
            parts = {
                "attendance": m["attendance_rate"],
                "pages": (m["pages"] / best_pages * 100) if best_pages else None,
                "exams": m["exam_average"],
            }
            used = {k: v for k, v in parts.items() if v is not None}
            weight = sum(TOP_WEIGHTS[k] for k in used)
            m["score"] = round(sum(TOP_WEIGHTS[k] * v for k, v in used.items()) / weight, 1) if weight else 0.0
        members.sort(key=lambda m: (-m["score"], -m["pages"], m["name"]))
        entry = out.setdefault(school_id, {"school_id": school_id, "internal": [], "external": []})
        entry[mode] = [{**m, "rank": i + 1} for i, m in enumerate(members[:limit])]
    return list(out.values())


# ---------------------------------------------------------------- database loading


class ScopeNotFound(Exception):
    pass


async def _load_students(db: AsyncSession, school_ids: list[int] | None, lecture_id: int | None, student_id: int | None):
    query = (
        select(Student.id, Student.president_id, Student.enrollment_date, User.firstname, User.lastname,
               Student.first_name_en, Student.last_name_en, Student.sex, Student.enrollment_type)
        .join(User, User.id == Student.user_id)
    )
    if school_ids is not None:
        query = query.where(Student.president_id.in_(school_ids))
    if student_id is not None:
        query = query.where(Student.id == student_id)
    if lecture_id is not None:
        query = query.where(Student.id.in_(
            select(SessionParticipation.student_id).where(SessionParticipation.lecture_id == lecture_id)
        ))
    students = {}
    for sid, school_id, enrolled, first, last, first_en, last_en, sex, mode in (await db.execute(query)).all():
        students[sid] = {
            "name": f"{first} {last}".strip(),
            "name_en": f"{first_en or ''} {last_en or ''}".strip() or None,
            "school_id": school_id,
            "enrollment_date": enrolled.date().isoformat() if enrolled else None,
            "sex": sex,
            "enrollment_type": mode,
        }
    return students


async def _load_exam_averages(db: AsyncSession, student_ids: Iterable[int], start: date, end: date) -> dict[int, float]:
    """Average exam result (0-100) of each student over the period, present and marked sittings only."""
    from app.models.exam import Exam, ExamResult

    ids = list(student_ids)
    if not ids:
        return {}
    rows = (await db.execute(
        select(ExamResult.student_id, func.avg(ExamResult.mark * 100 / Exam.max_mark))
        .join(Exam, Exam.id == ExamResult.exam_id)
        .where(ExamResult.student_id.in_(ids), ExamResult.attendance == "present", ExamResult.mark.is_not(None),
               Exam.exam_date >= start, Exam.exam_date <= end)
        .group_by(ExamResult.student_id)
    )).all()
    return {sid: round(float(avg), 1) for sid, avg in rows if avg is not None}


async def _load_enrollments(db: AsyncSession, student_ids: Iterable[int]) -> dict[int, set[int]]:
    ids = list(student_ids)
    lectures_of: dict[int, set[int]] = defaultdict(set)
    if not ids:
        return lectures_of
    result = await db.execute(
        select(SessionParticipation.student_id, SessionParticipation.lecture_id)
        .where(SessionParticipation.student_id.in_(ids), SessionParticipation.lecture_id.is_not(None))
        .distinct()
    )
    for sid, lid in result.all():
        lectures_of[sid].add(lid)
    return lectures_of


async def _load_attendance(db, school_ids, lecture_id, student_ids, start, end) -> list[AttendanceRow]:
    query = select(Attendance.student_id, Attendance.president_id, Attendance.lecture_id, Attendance.date, Attendance.status).where(
        Attendance.date >= start, Attendance.date <= end
    )
    if school_ids is not None:
        query = query.where(Attendance.president_id.in_(school_ids))
    if lecture_id is not None:
        query = query.where(Attendance.lecture_id == lecture_id)
    if student_ids is not None:
        query = query.where(Attendance.student_id.in_(list(student_ids) or [-1]))
    return [
        AttendanceRow(sid, school, lec, day, getattr(status, "value", str(status)))
        for sid, school, lec, day, status in (await db.execute(query)).all()
    ]


async def _load_achievements(db, school_ids, student_ids, start, end) -> list[AchievementRow]:
    query = select(
        Achievement.student_id, Achievement.president_id, Achievement.date, Achievement.created_at,
        Achievement.achievement_type, Achievement.from_surah, Achievement.from_verse, Achievement.to_surah, Achievement.to_verse,
    )
    if school_ids is not None:
        query = query.where(Achievement.president_id.in_(school_ids))
    if student_ids is not None:
        query = query.where(Achievement.student_id.in_(list(student_ids) or [-1]))
    rows = []
    for sid, school, day_text, created, kind, fs, fv, ts, tv in (await db.execute(query)).all():
        day = parse_achievement_day(day_text, created)
        if day is None or not in_period(day, start, end):
            continue
        rows.append(AchievementRow(sid, school, day, getattr(kind, "value", str(kind)),
                                   calculate_achievement_pages(fs, fv, ts, tv)))
    return rows


async def build_analytics(
    db: AsyncSession,
    *,
    start: date,
    end: date,
    granularity: Granularity | None = None,
    school_id: int | None = None,
    lecture_id: int | None = None,
    student_id: int | None = None,
) -> dict:
    granularity = coarsen(start, end, granularity or default_granularity(start, end))
    length = (end - start).days + 1
    prev_end = start - timedelta(days=1)
    prev_start = prev_end - timedelta(days=length - 1)

    # ---- scope -------------------------------------------------------------------------
    schools = {
        pid: {"name": name}
        for pid, name in (await db.execute(select(President.id, President.school_name).order_by(President.school_name))).all()
    }
    level: Level = "platform"
    scope: dict = {"school": None, "lecture": None, "student": None}
    student_record = None
    if student_id is not None:
        level = "student"
        found = await _load_students(db, None, None, student_id)
        if not found:
            raise ScopeNotFound("Student not found")
        student_record = found[student_id]
        school_id = student_record["school_id"]
        scope["student"] = {"id": student_id, "name": student_record["name"], "name_en": student_record["name_en"]}
    if lecture_id is not None:
        lecture = (await db.execute(
            select(Lecture.id, Lecture.president_id, Lecture.lecture_name_ar, Lecture.lecture_name_en).where(Lecture.id == lecture_id)
        )).first()
        if lecture is None or (school_id is not None and lecture[1] != school_id):
            raise ScopeNotFound("Circle not found")
        school_id = lecture[1]
        scope["lecture"] = {"id": lecture[0], "name": lecture[2], "name_en": lecture[3]}
        if level == "platform":
            level = "lecture"
    if school_id is not None:
        if school_id not in schools:
            raise ScopeNotFound("School not found")
        scope["school"] = {"id": school_id, "name": schools[school_id]["name"]}
        if level == "platform":
            level = "school"

    school_ids = None if school_id is None else [school_id]
    students = await _load_students(db, school_ids, lecture_id, student_id)
    lectures_of = await _load_enrollments(db, students)
    student_filter = set(students) if level in ("lecture", "student") else None

    # One load covering the previous period too, split in memory.
    attendance_all = await _load_attendance(db, school_ids, lecture_id if level != "student" else None, student_filter, prev_start, end)
    achievements_all = await _load_achievements(db, school_ids, student_filter, prev_start, end)
    attendance = [r for r in attendance_all if in_period(r.day, start, end)]
    achievements = [r for r in achievements_all if in_period(r.day, start, end)]
    previous = summarize(
        [r for r in attendance_all if r.day < start],
        [r for r in achievements_all if r.day < start],
    )
    current = summarize(attendance, achievements)

    lecture_query = select(Lecture.id, Lecture.president_id, Lecture.lecture_name_ar, Lecture.lecture_name_en)
    if school_ids is not None:
        lecture_query = lecture_query.where(Lecture.president_id.in_(school_ids))
    lectures = {lid: {"name": ar, "name_en": en, "school_id": sid} for lid, sid, ar, en in (await db.execute(lecture_query)).all()}
    teacher_query = select(Teacher.president_id, func.count(Teacher.id)).group_by(Teacher.president_id)
    teachers_per_school = dict((await db.execute(teacher_query)).all())
    teachers_per_lecture = dict((await db.execute(
        select(lecture_teachers.c.lecture_id, func.count(lecture_teachers.c.teacher_id)).group_by(lecture_teachers.c.lecture_id)
    )).all())

    active_students = {r.student_id for r in attendance} | {r.student_id for r in achievements}
    kpis = {
        **current,
        "students": len(students),
        "active_students": len(active_students & set(students)),
        "schools": len(schools) if level == "platform" else 1,
        "lectures": len(lectures) if level in ("platform", "school") else (1 if level == "lecture" else len(lectures_of.get(student_id, ()))),
        "teachers": sum(teachers_per_school.get(s, 0) for s in (school_ids or schools)) if level in ("platform", "school")
        else teachers_per_lecture.get(lecture_id, 0) if level == "lecture" else None,
        "previous": previous,
    }

    # ---- breakdown one level down ------------------------------------------------------
    breakdown_level = None
    rows: list[dict] = []
    if level == "platform":
        breakdown_level = "school"
        members = defaultdict(set)
        for sid, info in students.items():
            members[info["school_id"]].add(sid)
        rows = entity_rows(
            {pid: {**info, "lectures": sum(1 for l in lectures.values() if l["school_id"] == pid),
                   "teachers": teachers_per_school.get(pid, 0)} for pid, info in schools.items()},
            attendance, achievements, lambda r: [r.school_id], lambda r: [r.school_id], members,
        )
    elif level == "school":
        breakdown_level = "lecture"
        members = defaultdict(set)
        for sid in students:
            for lid in lectures_of.get(sid, ()):
                members[lid].add(sid)
        rows = entity_rows(
            {lid: {"name": info["name"], "name_en": info["name_en"], "teachers": teachers_per_lecture.get(lid, 0)}
             for lid, info in lectures.items()},
            attendance, achievements,
            lambda r: [r.lecture_id] if r.lecture_id else [],
            lambda r: lectures_of.get(r.student_id, ()),
            members,
        )
    elif level == "lecture":
        breakdown_level = "student"
        rows = entity_rows(
            {sid: {"name": info["name"], "name_en": info["name_en"]} for sid, info in students.items()},
            attendance, achievements, lambda r: [r.student_id], lambda r: [r.student_id],
            {sid: {sid} for sid in students},
        )

    alerts = []
    if level in ("school", "lecture"):
        alerts = student_alerts({sid: {"name": i["name"], "name_en": i["name_en"]} for sid, i in students.items()}, attendance, achievements)
    elif level == "platform":
        alerts = student_alerts(
            {sid: {"name": i["name"], "name_en": i["name_en"], "school": schools.get(i["school_id"], {}).get("name")}
             for sid, i in students.items()},
            attendance, achievements,
        )

    tops = []
    if level in ("platform", "school", "lecture"):
        exam_avg = await _load_exam_averages(db, students, start, end)
        tops = top_students(students, attendance, achievements, exam_avg)
        for entry in tops:
            entry["school"] = schools.get(entry["school_id"], {}).get("name")
        tops.sort(key=lambda e: e["school"] or "")

    # ---- student detail ----------------------------------------------------------------
    detail = None
    if level == "student" and student_record is not None:
        cumulative, running = [], 0.0
        for row in sorted(achievements, key=lambda r: r.day):
            running += row.pages
            cumulative.append({"day": row.day.isoformat(), "pages": round(running, 1)})
        detail = {
            "enrollment_date": student_record["enrollment_date"],
            "sex": student_record["sex"],
            "lectures": [
                {"id": lid, "name": lectures[lid]["name"], "name_en": lectures[lid]["name_en"]}
                for lid in sorted(lectures_of.get(student_id, ())) if lid in lectures
            ],
            "attendance": [
                {"day": r.day.isoformat(), "status": r.status,
                 "lecture": lectures.get(r.lecture_id, {}).get("name") if r.lecture_id else None}
                for r in sorted(attendance, key=lambda r: r.day, reverse=True)[:120]
            ],
            "achievements": [
                {"day": r.day.isoformat(), "type": r.kind, "pages": r.pages}
                for r in sorted(achievements, key=lambda r: r.day, reverse=True)[:120]
            ],
            "cumulative_pages": cumulative,
        }

    return {
        "level": level,
        "scope": scope,
        "period": {
            "from": start.isoformat(), "to": end.isoformat(), "granularity": granularity,
            "previous_from": prev_start.isoformat(), "previous_to": prev_end.isoformat(),
        },
        "kpis": kpis,
        "series": build_series(attendance, achievements, start, end, granularity),
        "breakdown": {"level": breakdown_level, "rows": rows},
        "alerts": alerts,
        "top_students": tops,
        "student": detail,
        "generated_at": datetime.now().isoformat(timespec="seconds"),
    }
