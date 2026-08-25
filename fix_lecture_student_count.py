"""
Script to diagnose and display lecture student counts.
This helps identify why student counts show as 0 for teachers.
"""
import asyncio
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import async_session_maker
from app.models.sessionParticipation import SessionParticipation
from app.models.lecture import Lecture
from app.models.student import Student


async def diagnose_student_counts():
    """
    Diagnose why student counts might be showing as 0.
    """
    async with async_session_maker() as db:
        print("=== DIAGNOSIS REPORT ===\n")
        
        # 1. Check total session participations
        total_participations = await db.execute(
            select(func.count(SessionParticipation.id))
        )
        total = total_participations.scalar() or 0
        print(f"1. Total SessionParticipation records: {total}")
        
        # 2. Check participations with lecture_id
        with_lecture_id = await db.execute(
            select(func.count(SessionParticipation.id))
            .where(SessionParticipation.lecture_id.isnot(None))
        )
        with_lecture = with_lecture_id.scalar() or 0
        print(f"2. Participations with lecture_id: {with_lecture}")
        
        # 3. Check participations without lecture_id
        without_lecture_id = await db.execute(
            select(func.count(SessionParticipation.id))
            .where(SessionParticipation.lecture_id.is_(None))
        )
        without_lecture = without_lecture_id.scalar() or 0
        print(f"3. Participations WITHOUT lecture_id: {without_lecture}")
        
        # 4. Show sample participations
        print("\n4. Sample SessionParticipation records:")
        sample_result = await db.execute(
            select(SessionParticipation).limit(5)
        )
        samples = sample_result.scalars().all()
        for sp in samples:
            print(f"   - ID: {sp.id}, Student: {sp.student_id}, Lecture: {sp.lecture_id}, Session: {sp.session_id}")
        
        # 5. Check lectures and their student counts
        print("\n5. Lecture Student Counts:")
        lectures_result = await db.execute(select(Lecture))
        lectures = lectures_result.scalars().all()
        
        for lecture in lectures:
            count_result = await db.execute(
                select(func.count(func.distinct(SessionParticipation.student_id)))
                .where(SessionParticipation.lecture_id == lecture.id)
            )
            count = count_result.scalar() or 0
            print(f"   - {lecture.lecture_name_ar} (ID: {lecture.id}): {count} students")
        
        # 6. Check if students exist
        students_result = await db.execute(select(func.count(Student.id)))
        student_count = students_result.scalar() or 0
        print(f"\n6. Total students in database: {student_count}")
        
        print("\n=== END DIAGNOSIS ===")


if __name__ == "__main__":
    print("Running diagnosis...\n")
    asyncio.run(diagnose_student_counts())

