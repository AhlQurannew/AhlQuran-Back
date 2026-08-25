import asyncio
from sqlalchemy import select, func
from app.db.session import async_session_maker
from app.models.student import Student
from app.models.sessionParticipation import SessionParticipation

async def test():
    async with async_session_maker() as db:
        # Test the exact query we're using
        result = await db.execute(
            select(func.count(func.distinct(Student.id)))
            .select_from(Student)
            .join(SessionParticipation, Student.id == SessionParticipation.student_id)
            .where(SessionParticipation.lecture_id == 1)
        )
        count = result.scalar()
        print(f'Student count for lecture 1: {count}')

asyncio.run(test())
