"""Speciality helpers: circle lookup and keeping students' enrollments in line with their speciality."""
from fastapi import HTTPException
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.sessionParticipation import SessionParticipation
from app.models.speciality import Speciality, SpecialityLecture
from app.models.student import Student


async def speciality_lecture_ids(db: AsyncSession, speciality_id: int, president_id: int) -> list[int]:
    """Circles of a speciality of this school; 404 if it is not this school's, 422 if it has none."""
    owner = await db.scalar(select(Speciality.president_id).where(Speciality.id == speciality_id))
    if owner is None or owner != president_id:
        raise HTTPException(status_code=404, detail="Speciality not found in this school")
    ids = list((await db.execute(
        select(SpecialityLecture.lecture_id).where(SpecialityLecture.speciality_id == speciality_id)
    )).scalars())
    if not ids:
        raise HTTPException(status_code=422, detail="This speciality has no circles yet")
    return ids


async def set_student_lectures(db: AsyncSession, student_id: int, lecture_ids: list[int]) -> None:
    """Make the student's circle enrollments exactly `lecture_ids` (session-level rows are untouched)."""
    current = set((await db.execute(
        select(SessionParticipation.lecture_id).where(
            SessionParticipation.student_id == student_id,
            SessionParticipation.session_id.is_(None),
        )
    )).scalars())
    wanted = set(lecture_ids)
    if current - wanted:
        await db.execute(delete(SessionParticipation).where(
            SessionParticipation.student_id == student_id,
            SessionParticipation.session_id.is_(None),
            SessionParticipation.lecture_id.in_(current - wanted),
        ))
    for lecture_id in wanted - current:
        db.add(SessionParticipation(student_id=student_id, session_id=None, lecture_id=lecture_id))


async def sync_speciality_students(db: AsyncSession, speciality_id: int) -> int:
    """After a speciality's circles change, re-enroll each of its students. Returns the student count."""
    lecture_ids = list((await db.execute(
        select(SpecialityLecture.lecture_id).where(SpecialityLecture.speciality_id == speciality_id)
    )).scalars())
    student_ids = list((await db.execute(select(Student.id).where(Student.speciality_id == speciality_id))).scalars())
    for student_id in student_ids:
        await set_student_lectures(db, student_id, lecture_ids)
    return len(student_ids)
