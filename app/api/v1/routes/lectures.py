from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import joinedload
from typing import List, Optional

from app.db.session import get_db
from app.core.dependencies import require_president_or_supervisor, require_president_or_admin
from app.core.multi_tenancy import get_president_id_for_user
from app.schemas.lecture import (
    LectureCreate,
    LectureUpdate,
    LectureResponse,
    LectureListResponse,
    TeacherResponse,
    WeeklyScheduleResponse
)
from app.models.lecture import Lecture, WeeklySchedule
from app.models.teacher import Teacher
from app.models.user import User
from app.models.sessionParticipation import SessionParticipation

lectureRouter = APIRouter()


@lectureRouter.get("/", response_model=List[LectureResponse])
async def get_lectures_basic(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors
    school_id: int = None
):
    """
    Get basic list of lectures (for dropdowns, etc.)
    """
    # Get president ID for filtering (works for presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)
    
    result_query = await db.execute(
        select(Lecture).where(Lecture.president_id == president_id)
    )
    lectures = result_query.scalars().all()
    
    result = []
    for lecture in lectures:
        result.append({
            "lecture_id": lecture.id,
            "lecture_name_ar": lecture.lecture_name_ar,
            "lecture_name_en": lecture.lecture_name_en,
            "circle_type": lecture.circle_type,
            "category": lecture.category,
            "shown_on_website": lecture.shown_on_website,
            "teachers": [],
            "schedules": [],
            "student_count": 0,
            "created_at": lecture.created_at,
            "updated_at": lecture.updated_at
        })
    
    return result


@lectureRouter.get("/special/lectures", response_model=List[LectureResponse])
async def get_all_lectures(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors
    school_id: Optional[int] = Query(None)
):
    """
    Get all lectures with full details including teachers, schedules, and student count
    """
    # Get president ID for filtering (works for presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)
    
    result_query = await db.execute(
        select(Lecture).options(
            joinedload(Lecture.teachers).joinedload(Teacher.user),
            joinedload(Lecture.schedules)
        ).where(Lecture.president_id == president_id)
    )
    lectures = result_query.scalars().unique().all()
    
    result = []
    for lecture in lectures:
        # Get student count for this lecture
        count_query = await db.execute(
            select(func.count(func.distinct(SessionParticipation.student_id))).where(
                SessionParticipation.lecture_id == lecture.id
            )
        )
        student_count = count_query.scalar() or 0
        
        # Build teacher response
        teachers_data = []
        for teacher in lecture.teachers:
            teachers_data.append(TeacherResponse(
                teacher_id=teacher.id,
                first_name=teacher.user.firstname if teacher.user else None,
                last_name=teacher.user.lastname if teacher.user else None
            ))
        
        # Build schedules response
        schedules_data = []
        for schedule in lecture.schedules:
            schedules_data.append(WeeklyScheduleResponse(
                weekly_schedule_id=schedule.id,
                lecture_id=schedule.lecture_id,
                day_of_week=schedule.day_of_week,
                start_time=schedule.start_time,
                end_time=schedule.end_time
            ))
        
        result.append(LectureResponse(
            lecture_id=lecture.id,
            lecture_name_ar=lecture.lecture_name_ar,
            lecture_name_en=lecture.lecture_name_en,
            circle_type=lecture.circle_type,
            category=lecture.category,
            shown_on_website=lecture.shown_on_website,
            teachers=teachers_data,
            schedules=schedules_data,
            student_count=student_count,
            created_at=lecture.created_at,
            updated_at=lecture.updated_at
        ))
    
    return result


@lectureRouter.get("/special/lectures/{lecture_id}", response_model=LectureResponse)
async def get_lecture_by_id(
    lecture_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors
    school_id: int = None
):
    """
    Get a single lecture by ID with full details
    """
    # Get president ID for filtering (works for presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)
    
    result_query = await db.execute(
        select(Lecture).options(
            joinedload(Lecture.teachers).joinedload(Teacher.user),
            joinedload(Lecture.schedules)
        ).where(Lecture.id == lecture_id, Lecture.president_id == president_id)
    )
    lecture = result_query.scalar_one_or_none()
    
    if not lecture:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lecture with id {lecture_id} not found"
        )
    
    # Get student count
    count_query = await db.execute(
        select(func.count(func.distinct(SessionParticipation.student_id))).where(
            SessionParticipation.lecture_id == lecture.id
        )
    )
    student_count = count_query.scalar() or 0
    
    # Build teacher response
    teachers_data = []
    for teacher in lecture.teachers:
        teachers_data.append(TeacherResponse(
            teacher_id=teacher.id,
            first_name=teacher.user.firstname if teacher.user else None,
            last_name=teacher.user.lastname if teacher.user else None
        ))
    
    # Build schedules response
    schedules_data = []
    for schedule in lecture.schedules:
        schedules_data.append(WeeklyScheduleResponse(
            weekly_schedule_id=schedule.id,
            lecture_id=schedule.lecture_id,
            day_of_week=schedule.day_of_week,
            start_time=schedule.start_time,
            end_time=schedule.end_time
        ))
    
    return LectureResponse(
        lecture_id=lecture.id,
        lecture_name_ar=lecture.lecture_name_ar,
        lecture_name_en=lecture.lecture_name_en,
        circle_type=lecture.circle_type,
        category=lecture.category,
        shown_on_website=lecture.shown_on_website,
        teachers=teachers_data,
        schedules=schedules_data,
        student_count=student_count,
        created_at=lecture.created_at,
        updated_at=lecture.updated_at
    )


@lectureRouter.post("/special/lectures/submit", response_model=LectureResponse, status_code=status.HTTP_201_CREATED)
async def create_lecture(
    lecture_data: LectureCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors
    school_id: Optional[int] = Query(None)
):
    """
    Create a new lecture with teachers and schedules
    """
    # Get president ID (works for presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)
    
    # Create the lecture with president_id
    new_lecture = Lecture(
        lecture_name_ar=lecture_data.lecture.lecture_name_ar,
        lecture_name_en=lecture_data.lecture.lecture_name_en,
        circle_type=lecture_data.lecture.circle_type,
        category=lecture_data.lecture.category,
        shown_on_website=lecture_data.lecture.shown_on_website,
        president_id=president_id
    )
    
    db.add(new_lecture)
    await db.flush()  # Get the lecture ID
    
    # Add teachers if provided - use direct SQL to avoid lazy loading
    if lecture_data.teachers:
        teacher_ids = [t.teacher_id for t in lecture_data.teachers]
        # Filter teachers by president_id to ensure supervisors can only assign their own teachers
        teachers_query = await db.execute(
            select(Teacher).where(
                Teacher.id.in_(teacher_ids),
                Teacher.president_id == president_id
            )
        )
        teachers = teachers_query.scalars().all()
        
        # Now refresh with teachers loaded and assign
        await db.refresh(new_lecture, ['teachers'])
        new_lecture.teachers = list(teachers)
    
    # Add schedules
    for schedule_data in lecture_data.schedules:
        schedule = WeeklySchedule(
            lecture_id=new_lecture.id,
            day_of_week=schedule_data.day_of_week,
            start_time=schedule_data.start_time,
            end_time=schedule_data.end_time
        )
        db.add(schedule)
    
    await db.commit()
    await db.refresh(new_lecture)
    
    # Load relationships
    result_query = await db.execute(
        select(Lecture).options(
            joinedload(Lecture.teachers).joinedload(Teacher.user),
            joinedload(Lecture.schedules)
        ).where(Lecture.id == new_lecture.id)
    )
    lecture = result_query.unique().scalar_one()
    
    # Build response
    teachers_data = []
    for teacher in lecture.teachers:
        teachers_data.append(TeacherResponse(
            teacher_id=teacher.id,
            first_name=teacher.user.firstname if teacher.user else None,
            last_name=teacher.user.lastname if teacher.user else None
        ))
    
    schedules_data = []
    for schedule in lecture.schedules:
        schedules_data.append(WeeklyScheduleResponse(
            weekly_schedule_id=schedule.id,
            lecture_id=schedule.lecture_id,
            day_of_week=schedule.day_of_week,
            start_time=schedule.start_time,
            end_time=schedule.end_time
        ))
    
    return LectureResponse(
        lecture_id=lecture.id,
        lecture_name_ar=lecture.lecture_name_ar,
        lecture_name_en=lecture.lecture_name_en,
        circle_type=lecture.circle_type,
        category=lecture.category,
        shown_on_website=lecture.shown_on_website,
        teachers=teachers_data,
        schedules=schedules_data,
        student_count=0,
        created_at=lecture.created_at,
        updated_at=lecture.updated_at
    )


@lectureRouter.put("/special/lectures/{lecture_id}", response_model=LectureResponse)
async def update_lecture(
    lecture_id: int,
    lecture_data: LectureUpdate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors
    school_id: Optional[int] = Query(None)
):
    """
    Update an existing lecture
    """
    # DEBUG: Log received data
    import logging
    logger = logging.getLogger(__name__)
    logger.info(f"UPDATE LECTURE {lecture_id}: Received {len(lecture_data.teachers)} teachers")
    for t in lecture_data.teachers:
        logger.info(f"  Teacher ID: {t.teacher_id}")
    
    # Get president ID for filtering (works for presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)
    logger.info(f"UPDATE LECTURE {lecture_id}: President ID = {president_id}")
    
    # Load lecture with relationships to avoid lazy loading issues
    result_query = await db.execute(
        select(Lecture).options(
            joinedload(Lecture.teachers),
            joinedload(Lecture.schedules)
        ).where(Lecture.id == lecture_id, Lecture.president_id == president_id)
    )
    lecture = result_query.unique().scalar_one_or_none()
    
    if not lecture:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lecture with id {lecture_id} not found"
        )
    
    # Update lecture fields
    lecture.lecture_name_ar = lecture_data.lecture.lecture_name_ar
    lecture.lecture_name_en = lecture_data.lecture.lecture_name_en
    lecture.circle_type = lecture_data.lecture.circle_type
    lecture.category = lecture_data.lecture.category
    lecture.shown_on_website = lecture_data.lecture.shown_on_website
    
    # Update teachers - use direct assignment to avoid lazy loading
    if lecture_data.teachers:
        teacher_ids = [t.teacher_id for t in lecture_data.teachers]
        logger.info(f"UPDATE LECTURE {lecture_id}: Assigning teacher IDs: {teacher_ids}")
        # Filter teachers by president_id to ensure supervisors can only assign their own teachers
        teachers_query = await db.execute(
            select(Teacher).where(
                Teacher.id.in_(teacher_ids),
                Teacher.president_id == president_id
            )
        )
        teachers = teachers_query.scalars().all()
        logger.info(f"UPDATE LECTURE {lecture_id}: Found {len(teachers)} matching teachers")
        lecture.teachers = list(teachers)
    else:
        logger.info(f"UPDATE LECTURE {lecture_id}: No teachers to assign")
        lecture.teachers = []
    
    # Update schedules - delete old ones and create new ones
    schedules_to_delete = await db.execute(select(WeeklySchedule).where(WeeklySchedule.lecture_id == lecture_id))
    for schedule in schedules_to_delete.scalars():
        await db.delete(schedule)
    for schedule_data in lecture_data.schedules:
        schedule = WeeklySchedule(
            lecture_id=lecture.id,
            day_of_week=schedule_data.day_of_week,
            start_time=schedule_data.start_time,
            end_time=schedule_data.end_time
        )
        db.add(schedule)
    
    await db.commit()
    await db.refresh(lecture)
    
    # Load relationships
    result_query = await db.execute(
        select(Lecture).options(
            joinedload(Lecture.teachers).joinedload(Teacher.user),
            joinedload(Lecture.schedules)
        ).where(Lecture.id == lecture_id)
    )
    lecture = result_query.unique().scalar_one()
    
    # Get student count
    count_query = await db.execute(
        select(func.count(func.distinct(SessionParticipation.student_id))).where(
            SessionParticipation.lecture_id == lecture.id
        )
    )
    student_count = count_query.scalar() or 0
    
    # Build response
    teachers_data = []
    for teacher in lecture.teachers:
        teachers_data.append(TeacherResponse(
            teacher_id=teacher.id,
            first_name=teacher.user.firstname if teacher.user else None,
            last_name=teacher.user.lastname if teacher.user else None
        ))
    
    schedules_data = []
    for schedule in lecture.schedules:
        schedules_data.append(WeeklyScheduleResponse(
            weekly_schedule_id=schedule.id,
            lecture_id=schedule.lecture_id,
            day_of_week=schedule.day_of_week,
            start_time=schedule.start_time,
            end_time=schedule.end_time
        ))
    
    return LectureResponse(
        lecture_id=lecture.id,
        lecture_name_ar=lecture.lecture_name_ar,
        lecture_name_en=lecture.lecture_name_en,
        circle_type=lecture.circle_type,
        category=lecture.category,
        shown_on_website=lecture.shown_on_website,
        teachers=teachers_data,
        schedules=schedules_data,
        student_count=student_count,
        created_at=lecture.created_at,
        updated_at=lecture.updated_at
    )


@lectureRouter.delete("/{lecture_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_lecture(
    lecture_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors
    school_id: int = None
):
    """
    Delete a lecture by ID
    """
    result_query = await db.execute(select(Lecture).where(Lecture.id == lecture_id))
    lecture = result_query.scalar_one_or_none()
    
    if not lecture:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Lecture with id {lecture_id} not found"
        )
    
    await db.delete(lecture)
    await db.commit()
    
    return None

