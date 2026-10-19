from fastapi import APIRouter, HTTPException, Depends, Response, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, String, cast
from sqlalchemy.orm import selectinload
from datetime import datetime, date
from typing import Optional, List
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
    LectureDistributionResponse
)
from app.core.dependencies import require_president, require_president_or_admin, require_president_or_supervisor
from app.core.multi_tenancy import get_president_id_for_user, get_created_by_user_id
from app.core.quran_pages import calculate_achievement_pages


presidentRouter = APIRouter()


async def get_current_president_id(current_user, db: AsyncSession, school_id: Optional[int] = None) -> int:
    """
    Helper function to get the president ID for the current user (president, supervisor, chief supervisor) or admin viewing a school.
    Delegates to get_president_id_for_user in app.core.multi_tenancy.
    """
    return await get_president_id_for_user(current_user, db, school_id=school_id)


@presidentRouter.post("/register_supervisor", response_model=SupervisorResponse)
async def add_supervisor(
        supervisor_data: SupervisorCreate,
        db: AsyncSession = Depends(get_db),
        current_user = Depends(require_president_or_admin),  # Only presidents and admins can create supervisors
        school_id: Optional[int] = Query(None)
):
    # Get president ID (handles both president and admin)
    president_id = await get_current_president_id(current_user, db, school_id)
    
    # Get the user_id for created_by_id
    created_by_user_id = get_created_by_user_id(current_user)
    
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
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors to create teachers
    school_id: Optional[int] = Query(None)
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
        created_by_id=get_created_by_user_id(current_user),
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
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors to create students
    school_id: Optional[int] = Query(None)
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
        created_by_id=get_created_by_user_id(current_user),
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
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors to view teachers
    school_id: Optional[int] = Query(None)
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
    current_user = Depends(require_president_or_supervisor),  # Allow supervisors to view students
    school_id: Optional[int] = Query(None)
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
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
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
    today_str = datetime.now().strftime("%d-%m-%Y")
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
    
    # Total pages memorized (sum of achievements for president's students)
    ach_result = await db.execute(
        select(Achievement)
        .join(Student, Achievement.student_id == Student.id)
        .where(Student.president_id == president_id)
    )
    achievements = ach_result.scalars().all()
    total_pages = sum(
        calculate_achievement_pages(ach.from_surah, ach.from_verse, ach.to_surah, ach.to_verse)
        for ach in achievements
    )
    
    return {
        "total_students": total_students,
        "total_teachers": total_teachers,
        "total_supervisors": total_supervisors,
        "present_today": present_today,
        "total_pages_memorized": int(round(total_pages)),
        "total_lectures": total_lectures
    }


@presidentRouter.get("/statistics/attendance-trend", response_model=list[AttendanceRecordResponse])
async def get_attendance_trend(
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
):
    """Get attendance trend over recent days"""
    president_id = await get_current_president_id(current_user, db, school_id)
    
    # Get unique dates with attendance records (date is string DD-MM-YYYY)
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


@presidentRouter.get("/statistics/top-memorizers", response_model=list[MemorizationRecordResponse])
async def get_top_memorizers(
    limit: int = 5,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
):
    """Get top students by memorization progress"""
    president_id = await get_current_president_id(current_user, db, school_id)
    
    # Get students with their total achievement pages
    students_result = await db.execute(
        select(Student, User)
        .join(User, Student.user_id == User.id)
        .where(Student.president_id == president_id)
    )
    students_data = students_result.all()
    if not students_data:
        return []

    student_ids = [s[0].id for s in students_data]
    ach_result = await db.execute(
        select(Achievement).where(Achievement.student_id.in_(student_ids))
    )
    achievements = ach_result.scalars().all()

    pages_by_student: dict[int, float] = {s[0].id: 0.0 for s in students_data}
    for ach in achievements:
        pages_by_student[ach.student_id] = pages_by_student.get(ach.student_id, 0.0) + calculate_achievement_pages(
            ach.from_surah, ach.from_verse, ach.to_surah, ach.to_verse
        )

    # Sort students by total pages descending
    sorted_students = sorted(
        students_data,
        key=lambda pair: pages_by_student.get(pair[0].id, 0.0),
        reverse=True
    )
    top_students = sorted_students[:limit]
    
    return [
        {
            "student": f"{user.firstname} {user.lastname}",
            "pages": int(round(pages_by_student.get(student.id, 0.0))),
            "rank": idx + 1
        }
        for idx, (student, user) in enumerate(top_students)
    ]


@presidentRouter.get("/statistics/lecture-distribution", response_model=list[LectureDistributionResponse])
async def get_lecture_distribution(
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
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


def parse_date_safe(d_str: str | None) -> date | None:
    """Helper to safely parse YYYY-MM-DD or DD-MM-YYYY dates"""
    if not d_str:
        return None
    for fmt in ("%Y-%m-%d", "%d-%m-%Y"):
        try:
            return datetime.strptime(d_str.strip(), fmt).date()
        except ValueError:
            pass
    return None


@presidentRouter.get("/statistics/achievement-breakdown")
async def get_president_achievement_breakdown(
    lecture_id: int | None = None,
    student_id: int | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
):
    president_id = await get_current_president_id(current_user, db, school_id)
    
    query = select(Achievement).join(Student, Achievement.student_id == Student.id).where(Student.president_id == president_id)
    
    if lecture_id:
        query = query.join(SessionParticipation, SessionParticipation.student_id == Student.id).where(SessionParticipation.lecture_id == lecture_id)
        
    if student_id:
        query = query.where(Achievement.student_id == student_id)
        
    start_d = parse_date_safe(start_date)
    end_d = parse_date_safe(end_date)
    if start_d:
        query = query.where(func.to_date(Achievement.date, 'DD-MM-YYYY') >= start_d)
    if end_d:
        query = query.where(func.to_date(Achievement.date, 'DD-MM-YYYY') <= end_d)
        
    result = await db.execute(query)
    achievements = result.scalars().all()
    
    breakdown = {"normal": 0.0, "small": 0.0, "big": 0.0}
    for ach in achievements:
        type_key = str(ach.achievement_type.value if hasattr(ach.achievement_type, "value") else ach.achievement_type).lower()
        if type_key in breakdown:
            pages = calculate_achievement_pages(ach.from_surah, ach.from_verse, ach.to_surah, ach.to_verse)
            breakdown[type_key] += pages
            
    return {k: round(v, 1) for k, v in breakdown.items()}


@presidentRouter.get("/statistics/attendance-breakdown")
async def get_president_attendance_breakdown(
    lecture_id: int | None = None,
    student_id: int | None = None,
    start_date: str | None = None,
    end_date: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
):
    president_id = await get_current_president_id(current_user, db, school_id)
    
    query = select(Attendance).join(Student, Attendance.student_id == Student.id).where(Student.president_id == president_id)
    
    if lecture_id:
        query = query.join(SessionParticipation, SessionParticipation.student_id == Student.id).where(SessionParticipation.lecture_id == lecture_id)
        
    if student_id:
        query = query.where(Attendance.student_id == student_id)
        
    start_d = parse_date_safe(start_date)
    end_d = parse_date_safe(end_date)
    if start_d:
        query = query.where(func.to_date(Attendance.date, 'DD-MM-YYYY') >= start_d)
    if end_d:
        query = query.where(func.to_date(Attendance.date, 'DD-MM-YYYY') <= end_d)
        
    result = await db.execute(query)
    attendances = result.scalars().all()
    
    counts = {"present": 0, "late": 0, "absent": 0, "excused": 0}
    for att in attendances:
        status_key = str(att.status.value if hasattr(att.status, "value") else att.status).lower()
        if status_key in counts:
            counts[status_key] += 1
            
    counts["total"] = sum(counts.values())
    return counts


@presidentRouter.get("/statistics/halqa-breakdown")
async def get_president_halqa_breakdown(
    lecture_id: int,
    start_date: str | None = None,
    end_date: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
):
    president_id = await get_current_president_id(current_user, db, school_id)
    
    students_query = await db.execute(
        select(Student, User)
        .join(User, Student.user_id == User.id)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .where(SessionParticipation.lecture_id == lecture_id, Student.president_id == president_id)
        .distinct()
    )
    students = students_query.all()
    if not students:
        return []
        
    student_ids = [s[0].id for s in students]
    query = select(Achievement).where(Achievement.student_id.in_(student_ids))
    start_d = parse_date_safe(start_date)
    end_d = parse_date_safe(end_date)
    if start_d:
        query = query.where(func.to_date(Achievement.date, 'DD-MM-YYYY') >= start_d)
    if end_d:
        query = query.where(func.to_date(Achievement.date, 'DD-MM-YYYY') <= end_d)
        
    ach_result = await db.execute(query)
    achievements = ach_result.scalars().all()
    
    pages_by_student = {s[0].id: 0.0 for s in students}
    for ach in achievements:
        pages = calculate_achievement_pages(ach.from_surah, ach.from_verse, ach.to_surah, ach.to_verse)
        pages_by_student[ach.student_id] = pages_by_student.get(ach.student_id, 0.0) + pages
        
    return [
        {
            "student": f"{user.firstname} {user.lastname}",
            "pages": round(pages_by_student.get(student.id, 0.0), 1)
        }
        for student, user in students
    ]


@presidentRouter.get("/statistics/progress-timeline")
async def get_president_progress_timeline(
    student_id: int,
    start_date: str | None = None,
    end_date: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_supervisor),
    school_id: Optional[int] = Query(None)
):
    president_id = await get_current_president_id(current_user, db, school_id)
    
    check_query = await db.execute(
        select(Student.id).where(Student.id == student_id, Student.president_id == president_id)
    )
    if not check_query.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
        
    query = select(Achievement).where(Achievement.student_id == student_id)
    start_d = parse_date_safe(start_date)
    end_d = parse_date_safe(end_date)
    if start_d:
        query = query.where(func.to_date(Achievement.date, 'DD-MM-YYYY') >= start_d)
    if end_d:
        query = query.where(func.to_date(Achievement.date, 'DD-MM-YYYY') <= end_d)
        
    ach_result = await db.execute(query.order_by(Achievement.created_at.asc()))
    achievements = ach_result.scalars().all()
    
    from collections import OrderedDict
    by_date = OrderedDict()
    for ach in achievements:
        d = ach.date or (ach.created_at.strftime("%d-%m-%Y") if ach.created_at else "01-01-2026")
        short_date = "/".join(d.split("-")[:2]) if "-" in d else d
        if short_date not in by_date:
            by_date[short_date] = {"date": short_date, "memorization": 0.0, "minorRev": 0.0, "majorRev": 0.0}
        
        pages = calculate_achievement_pages(ach.from_surah, ach.from_verse, ach.to_surah, ach.to_verse)
        type_key = str(ach.achievement_type.value if hasattr(ach.achievement_type, "value") else ach.achievement_type).lower()
        if type_key == "normal":
            by_date[short_date]["memorization"] += pages
        elif type_key == "small":
            by_date[short_date]["minorRev"] += pages
        elif type_key == "big":
            by_date[short_date]["majorRev"] += pages
            
    return list(by_date.values())
