from fastapi import APIRouter, HTTPException, Depends, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, String, cast
from sqlalchemy.orm import selectinload
from datetime import datetime, date
from app.db.session import get_db
from app.core.security import get_password_hash

from app.models import Supervisor
from app.models.president import President
from app.models.teacher import Teacher
from app.models.student import Student
from app.models.guardian import Guardian
from app.models.user import User, UserRoleEnum
from app.models.attendance import Attendance
from app.models.acheivements import Achievement
from app.models.lecture import Lecture
from app.models.sessionParticipation import SessionParticipation

from app.schemas.teacher import TeacherCreate, TeacherResponse
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.supervisor import SupervisorCreate, SupervisorResponse
from app.schemas.guardian import GuardianResponse, GuardianCreate
from app.schemas.statistics import (
    StatsSummaryResponse,
    AttendanceRecordResponse,
    MemorizationRecordResponse,
    LectureDistributionResponse,
    AttendanceStatisticsResponse,
)
from app.core.dependencies import (
    require_president_chief_supervisor_or_admin,
    require_school_management_access,
)
from app.core.multi_tenancy import get_president_id_for_user, get_creator_user_id


presidentRouter = APIRouter()


async def get_current_president_id(current_user, db: AsyncSession, school_id: int = None) -> int:
    """
    Helper function to get the president ID for the current user or admin viewing a school.

    Args:
        current_user: Current authenticated user (President or Admin)
        db: Database session
        school_id: Optional school_id when admin is viewing a specific school

    Returns:
        President ID
    """
    return await get_president_id_for_user(current_user, db, school_id)


@presidentRouter.post("/register_supervisor", response_model=SupervisorResponse)
async def add_supervisor(
        supervisor_data: SupervisorCreate,
        db: AsyncSession = Depends(get_db),
        current_user = Depends(require_president_chief_supervisor_or_admin),
        school_id: int | None = None
):
    # Get president ID (handles both president and admin)
    president_id = await get_current_president_id(current_user, db, school_id)

    created_by_user_id = await get_creator_user_id(current_user, president_id, db)

    # Check if email already exists
    existing_user = await db.execute(
        select(User).where(User.email == supervisor_data.email)
    )
    if existing_user.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create User account
    new_user = User(
        firstname=supervisor_data.firstname,
        lastname=supervisor_data.lastname,
        email=supervisor_data.email,
        hashed_password=get_password_hash(supervisor_data.password),
        role=UserRoleEnum.SUPERVISOR,
        is_active=True
    )
    db.add(new_user)
    await db.flush()  # Get new_user.id before creating supervisor

    # Create Supervisor profile with president_id
    new_supervisor = Supervisor(
        user_id=new_user.id,
        created_by_id=created_by_user_id,
        president_id=president_id
    )
    db.add(new_supervisor)
    await db.commit()
    await db.refresh(new_supervisor)
    await db.refresh(new_user)

    return {
        "id": new_supervisor.id,
        "user_id": new_supervisor.user_id,
        "firstname": new_user.firstname,
        "lastname": new_user.lastname,
        "email": new_user.email,
        "is_active": new_user.is_active,
        "created_at": new_supervisor.created_at
    }

@presidentRouter.post("/register_teacher", response_model=TeacherResponse)
async def register_teacher(
    teacher_data: TeacherCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int | None = None
):
    # Get president ID (handles both president and admin)
    president_id = await get_current_president_id(current_user, db, school_id)

    # Check if email already exists
    existing_user = await db.execute(
        select(User).where(User.email == teacher_data.email)
    )
    if existing_user.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create User account
    new_user = User(
        firstname=teacher_data.firstname,
        lastname=teacher_data.lastname,
        email=teacher_data.email,
        hashed_password=get_password_hash(teacher_data.password),
        role=UserRoleEnum.TEACHER,
        is_active=True
    )
    db.add(new_user)
    await db.flush()  # Get new_user.id before creating teacher

    # Create Teacher profile with president_id
    new_teacher = Teacher(
        user_id=new_user.id,
        riwaya=teacher_data.riwaya,
        created_by_id=await get_creator_user_id(current_user, president_id, db),
        president_id=president_id
    )
    db.add(new_teacher)
    await db.commit()
    await db.refresh(new_teacher)
    await db.refresh(new_user)

    return {
        "id": new_teacher.id,
        "user_id": new_teacher.user_id,
        "firstname": new_user.firstname,
        "lastname": new_user.lastname,
        "email": new_user.email,
        "riwaya": new_teacher.riwaya,
        "hire_date": new_teacher.hire_date,
        "is_active": new_user.is_active
    }

@presidentRouter.post("/register_student", response_model=StudentResponse)
async def register_student(
    student_data: StudentCreate,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int | None = None
):
    # Get president ID (handles both president and admin)
    president_id = await get_current_president_id(current_user, db, school_id)

    # Check if email already exists
    existing_user = await db.execute(
        select(User).where(User.email == student_data.email)
    )
    if existing_user.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    # Create User account
    new_user = User(
        firstname=student_data.firstname,
        lastname=student_data.lastname,
        email=student_data.email,
        hashed_password=get_password_hash(student_data.password),
        role=UserRoleEnum.STUDENT,
        is_active=True
    )
    db.add(new_user)
    await db.flush()  # Get new_user.id before creating student

    # Create Student profile with president_id
    new_student = Student(
        user_id=new_user.id,
        parent_name=student_data.parent_name,
        parent_phone=student_data.parent_phone,
        guardian_email=student_data.guardian_email,
        created_by_id=await get_creator_user_id(current_user, president_id, db),
        president_id=president_id
    )
    db.add(new_student)
    await db.commit()
    await db.refresh(new_student)

    return {
        "message": "Student registered successfully",
        "student": new_student
    }

@presidentRouter.get("/teachers", response_model=list[TeacherResponse])
async def get_teachers(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int | None = None
):
    # Get president ID (handles both president and admin)
    president_id = await get_current_president_id(current_user, db, school_id)

    # Filter teachers by president_id
    result = await db.execute(
        select(Teacher, User)
        .join(User, Teacher.user_id == User.id)
        .where(Teacher.president_id == president_id)
    )
    teachers_data = result.all()

    return [
        {
            "id": teacher.id,
            "user_id": teacher.user_id,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "email": user.email,
            "riwaya": teacher.riwaya,
            "hire_date": teacher.hire_date,
            "is_active": user.is_active
        }
        for teacher, user in teachers_data
    ]

@presidentRouter.get("/students", response_model=list[StudentResponse])
async def get_students(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int | None = None
):
    # Get president ID (handles both president and admin)
    president_id = await get_current_president_id(current_user, db, school_id)

    # Filter students by president_id
    result = await db.execute(
        select(Student).where(Student.president_id == president_id)
    )
    students = result.scalars().all()
    return students


@presidentRouter.get("/statistics/summary", response_model=StatsSummaryResponse)
async def get_statistics_summary(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int = None
):
    """Get summary statistics for the president's school"""
    president_id = await get_current_president_id(current_user, db, school_id)

    # Total students
    total_students_result = await db.execute(
        select(func.count(Student.id)).where(Student.president_id == president_id)
    )
    total_students = total_students_result.scalar() or 0

    # Total teachers
    total_teachers_result = await db.execute(
        select(func.count(Teacher.id)).where(Teacher.president_id == president_id)
    )
    total_teachers = total_teachers_result.scalar() or 0

    # Total supervisors
    total_supervisors_result = await db.execute(
        select(func.count(Supervisor.id)).where(Supervisor.president_id == president_id)
    )
    total_supervisors = total_supervisors_result.scalar() or 0

    # Total lectures
    total_lectures_result = await db.execute(
        select(func.count(Lecture.id)).where(Lecture.president_id == president_id)
    )
    total_lectures = total_lectures_result.scalar() or 0

    # Students present today - date is stored as string in DD-MM-YYYY format
    today_str = datetime.now().date()
    present_today_result = await db.execute(
        select(func.count(func.distinct(Attendance.student_id)))
        .join(Student, Attendance.student_id == Student.id)
        .where(
            Attendance.date == today_str,
            cast(Attendance.status, String) == "present",
            Student.president_id == president_id
        )
    )
    present_today = present_today_result.scalar() or 0

    # Total pages memorized (sum of achievements)
    total_pages_result = await db.execute(
        select(func.sum(
            (Achievement.to_surah * 20 + Achievement.to_verse) -
            (Achievement.from_surah * 20 + Achievement.from_verse)
        ))
        .join(Student, Achievement.student_id == Student.id)
        .where(Student.president_id == president_id)
    )
    total_pages = total_pages_result.scalar() or 0

    return {
        "total_students": total_students,
        "total_teachers": total_teachers,
        "total_supervisors": total_supervisors,
        "present_today": present_today,
        "total_pages_memorized": max(0, int(total_pages / 15)),  # Rough estimate
        "total_lectures": total_lectures
    }


@presidentRouter.get("/statistics/attendance-trend", response_model=list[AttendanceRecordResponse])
async def get_attendance_trend(
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int = None
):
    """Get attendance trend over recent days"""
    president_id = await get_current_president_id(current_user, db, school_id)

    # Get unique calendar dates with attendance records.
    dates_result = await db.execute(
        select(Attendance.date)
        .join(Student, Attendance.student_id == Student.id)
        .where(Student.president_id == president_id)
        .distinct()
        .order_by(Attendance.date.desc())
        .limit(limit)
    )
    dates = [row[0] for row in dates_result.all()]

    attendance_data = []
    for date_val in dates:
        # Present count
        present_result = await db.execute(
            select(func.count(Attendance.id))
            .join(Student, Attendance.student_id == Student.id)
            .where(
                Attendance.date == date_val,
                cast(Attendance.status, String) == "present",
                Student.president_id == president_id
            )
        )
        present = present_result.scalar() or 0

        # Absent count
        absent_result = await db.execute(
            select(func.count(Attendance.id))
            .join(Student, Attendance.student_id == Student.id)
            .where(
                Attendance.date == date_val,
                cast(Attendance.status, String) == "absent",
                Student.president_id == president_id
            )
        )
        absent = absent_result.scalar() or 0

        total = present + absent
        percentage = round((present / total * 100), 1) if total > 0 else 0

        attendance_data.append({
            "date": date_val,
            "present": present,
            "absent": absent,
            "total": total,
            "percentage": f"{percentage}%"
        })

    return attendance_data


@presidentRouter.get("/statistics/attendance", response_model=AttendanceStatisticsResponse)
async def get_attendance_statistics(
    lecture_id: int,
    start_date: date,
    end_date: date,
    student_id: int | None = None,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
):
    if start_date > end_date:
        raise HTTPException(status_code=422, detail="start_date must be on or before end_date")

    president_id = await get_current_president_id(current_user, db, school_id)
    lecture_result = await db.execute(
        select(Lecture.id).where(Lecture.id == lecture_id, Lecture.president_id == president_id)
    )
    if lecture_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Lecture not found")

    if student_id is not None:
        enrollment_result = await db.execute(
            select(SessionParticipation.id)
            .join(Student, Student.id == SessionParticipation.student_id)
            .where(
                SessionParticipation.lecture_id == lecture_id,
                SessionParticipation.student_id == student_id,
                Student.president_id == president_id,
            )
            .limit(1)
        )
        if enrollment_result.scalar_one_or_none() is None:
            raise HTTPException(status_code=404, detail="Student is not enrolled in this lecture")

    grouped_result = await db.execute(
        select(Attendance.date, Attendance.status, func.count(Attendance.id))
        .join(Student, Student.id == Attendance.student_id)
        .where(
            Attendance.president_id == president_id,
            Student.president_id == president_id,
            Attendance.lecture_id == lecture_id,
            Attendance.date >= start_date,
            Attendance.date <= end_date,
            *([Attendance.student_id == student_id] if student_id is not None else []),
        )
        .group_by(Attendance.date, Attendance.status)
        .order_by(Attendance.date)
    )

    status_totals = {"present": 0, "late": 0, "absent": 0, "excused": 0}
    daily_map: dict[date, dict[str, int]] = {}
    for attendance_date, status_value, count in grouped_result.all():
        status_key = status_value.value if hasattr(status_value, "value") else str(status_value)
        if status_key not in status_totals:
            continue
        status_totals[status_key] += count
        daily_map.setdefault(attendance_date, {"present": 0, "late": 0, "absent": 0, "excused": 0})[status_key] += count

    total = sum(status_totals.values())
    daily = []
    for day, counts in sorted(daily_map.items()):
        daily.append({"date": day, **counts, "total": sum(counts.values())})

    legacy_result = await db.execute(
        select(func.count(Attendance.id))
        .join(Student, Student.id == Attendance.student_id)
        .where(
            Attendance.president_id == president_id,
            Student.president_id == president_id,
            Attendance.lecture_id.is_(None),
            Attendance.date >= start_date,
            Attendance.date <= end_date,
            *([Attendance.student_id == student_id] if student_id is not None else []),
        )
    )
    percentages = {
        key: round(value * 100 / total, 1) if total else 0.0
        for key, value in status_totals.items()
    }
    return {
        "lecture_id": lecture_id,
        "student_id": student_id,
        "start_date": start_date,
        "end_date": end_date,
        **status_totals,
        "total": total,
        "percentages": percentages,
        "daily": daily,
        "unassigned_legacy_count": legacy_result.scalar() or 0,
    }


@presidentRouter.get("/statistics/top-memorizers", response_model=list[MemorizationRecordResponse])
async def get_top_memorizers(
    limit: int = 5,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int = None
):
    """Get top students by memorization progress"""
    president_id = await get_current_president_id(current_user, db, school_id)

    # Get students with their total achievement pages
    result = await db.execute(
        select(
            Student,
            User,
            func.count(Achievement.id).label('total_achievements')
        )
        .join(User, Student.user_id == User.id)
        .outerjoin(Achievement, Achievement.student_id == Student.id)
        .where(Student.president_id == president_id)
        .group_by(Student.id, User.id)
        .order_by(func.count(Achievement.id).desc())
        .limit(limit)
    )

    students_data = result.all()

    return [
        {
            "student": f"{user.firstname} {user.lastname}",
            "pages": count,
            "rank": idx + 1
        }
        for idx, (student, user, count) in enumerate(students_data)
    ]


@presidentRouter.get("/statistics/lecture-distribution", response_model=list[LectureDistributionResponse])
async def get_lecture_distribution(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_school_management_access),
    school_id: int = None
):
    """Get student distribution across lectures"""
    president_id = await get_current_president_id(current_user, db, school_id)

    # Get total students for percentage calculation
    total_students_result = await db.execute(
        select(func.count(Student.id)).where(Student.president_id == president_id)
    )
    total_students = total_students_result.scalar() or 0

    if total_students == 0:
        return []

    # Get lectures with student counts through SessionParticipation
    result = await db.execute(
        select(
            Lecture.lecture_name_ar,
            func.count(func.distinct(SessionParticipation.student_id)).label('student_count')
        )
        .select_from(Lecture)
        .outerjoin(SessionParticipation, SessionParticipation.lecture_id == Lecture.id)
        .where(Lecture.president_id == president_id)
        .group_by(Lecture.id, Lecture.lecture_name_ar)
        .order_by(func.count(func.distinct(SessionParticipation.student_id)).desc())
    )

    lectures_data = result.all()

    return [
        {
            "className": lecture_name,
            "students": count,
            "percentage": f"{round(count / total_students * 100, 1)}%"
        }
        for lecture_name, count in lectures_data
    ]
