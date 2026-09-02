"""
Script to check student counts in the database
Run this inside the Docker container
"""
import asyncio
from sqlalchemy import select, func, text
from app.db.session import async_session_maker
from app.models.teacher import Teacher
from app.models.lecture import Lecture
from app.models.sessionParticipation import SessionParticipation
from app.models.student import Student


async def check_data():
    async with async_session_maker() as db:
        print("=" * 60)
        print("DATABASE DIAGNOSTIC REPORT")
        print("=" * 60)
        
        # 1. Check total students
        student_count = await db.execute(select(func.count(Student.id)))
        total_students = student_count.scalar()
        print(f"\n1. Total Students: {total_students}")
        
        # 2. Check total lectures
        lecture_count = await db.execute(select(func.count(Lecture.id)))
        total_lectures = lecture_count.scalar()
        print(f"2. Total Lectures: {total_lectures}")
        
        # 3. Check total teachers
        teacher_count = await db.execute(select(func.count(Teacher.id)))
        total_teachers = teacher_count.scalar()
        print(f"3. Total Teachers: {total_teachers}")
        
        # 4. Check session participations
        sp_count = await db.execute(select(func.count(SessionParticipation.id)))
        total_sp = sp_count.scalar()
        print(f"4. Total SessionParticipations: {total_sp}")
        
        # 5. Check how many have lecture_id
        sp_with_lecture = await db.execute(
            select(func.count(SessionParticipation.id))
            .where(SessionParticipation.lecture_id.isnot(None))
        )
        with_lecture = sp_with_lecture.scalar()
        print(f"5. SessionParticipations with lecture_id: {with_lecture}")
        
        # 6. Show student count per lecture
        print(f"\n6. Student Count Per Lecture:")
        lectures = await db.execute(select(Lecture))
        for lecture in lectures.scalars():
            count_query = await db.execute(
                select(func.count(func.distinct(SessionParticipation.student_id)))
                .where(SessionParticipation.lecture_id == lecture.id)
            )
            count = count_query.scalar() or 0
            print(f"   - {lecture.lecture_name_ar} (ID: {lecture.id}): {count} students")
        
        # 7. Show teachers and their lectures
        print(f"\n7. Teachers and Their Lectures:")
        teachers = await db.execute(select(Teacher))
        for teacher in teachers.scalars():
            # Get teacher's lectures using the same query as the endpoint
            teacher_lectures = await db.execute(
                select(Lecture)
                .join(Lecture.teachers)
                .where(Teacher.id == teacher.id)
            )
            lecture_list = teacher_lectures.scalars().all()
            print(f"   - Teacher ID {teacher.id}: {len(lecture_list)} lectures")
            for lec in lecture_list:
                # Get student count
                count_query = await db.execute(
                    select(func.count(func.distinct(SessionParticipation.student_id)))
                    .where(SessionParticipation.lecture_id == lec.id)
                )
                count = count_query.scalar() or 0
                print(f"     * {lec.lecture_name_ar} (ID: {lec.id}): {count} students")
        
        print("\n" + "=" * 60)


if __name__ == "__main__":
    asyncio.run(check_data())
