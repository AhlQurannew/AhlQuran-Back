from app.core.quran_progress import calculate_eighths, format_quran_progress
from fastapi import APIRouter, HTTPException, Depends, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from datetime import datetime
from app.db.session import get_db
from app.core.security import get_password_hash

from app.models import Supervisor
from app.models.president import President
from app.models.teacher import Teacher
from app.models.student import Student
from app.models.guardian import Guardian
from app.models.user import User, UserRoleEnum

from app.schemas.teacher import TeacherCreate, TeacherResponse
from app.schemas.student import StudentCreate, StudentResponse
from app.schemas.supervisor import SupervisorCreate, SupervisorResponse
from app.schemas.guardian import GuardianResponse, GuardianCreate
from app.core.dependencies import require_president


presidentRouter = APIRouter()


async def get_current_president_id(current_user: User, db: AsyncSession) -> int:
    """Helper function to get the president ID for the current user"""
    result = await db.execute(
        select(President).where(President.user_id == current_user.id)
    )
    president = result.scalar_one_or_none()
    if not president:
        raise HTTPException(status_code=403, detail="Not authorized as president")
    return president.id


@presidentRouter.post("/register_supervisor", response_model=SupervisorResponse)
async def add_supervisor(
        supervisor_data: SupervisorCreate,
        db: AsyncSession = Depends(get_db),
        current_president: User = Depends(require_president),
):
    # Get president ID
    president_id = await get_current_president_id(current_president, db)
    
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
        hashed_password=supervisor_data.password,
        role=UserRoleEnum.SUPERVISOR,
        is_active=True
    )
    db.add(new_user)
    await db.flush()  # Get new_user.id before creating supervisor

    # Create Supervisor profile with president_id
    new_supervisor = Supervisor(
        user_id=new_user.id,
        created_by_id=current_president.id,
        president_id=president_id
    )
    db.add(new_supervisor)
    await db.commit()
    await db.refresh(new_supervisor)

    return {
        "message": "Supervisor registered successfully",
        "supervisor": new_supervisor
    }

@presidentRouter.post("/register_teacher", response_model=TeacherResponse)
async def register_teacher(
    teacher_data: TeacherCreate,
    db: AsyncSession = Depends(get_db),
    current_president: User = Depends(require_president)
):
    # Get president ID
    president_id = await get_current_president_id(current_president, db)
    
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
        created_by_id=current_president.id,
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
    current_president: User = Depends(require_president)
):
    # Get president ID
    president_id = await get_current_president_id(current_president, db)
    
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
        hashed_password=student_data.password,
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
        created_by_id=current_president.id,
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
    current_president: User = Depends(require_president)
):
    # Get president ID
    president_id = await get_current_president_id(current_president, db)
    
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
    current_president: User = Depends(require_president)
):
    # Get president ID
    president_id = await get_current_president_id(current_president, db)
    
    # Filter students by president_id
    result = await db.execute(
        select(Student).where(Student.president_id == president_id)
    )
    students = result.scalars().all()
    return students
from collections import defaultdict
from sqlalchemy import func, desc
from app.models.attendance import Attendance, AttendanceStatus
from app.models.acheivements import Achievement
from app.models.lecture import Lecture
from app.models.sessionParticipation import SessionParticipation
from app.core.dependencies import get_current_user


async def resolve_president_id(current_user: User, db: AsyncSession) -> int:
    try:
        from app.core.multi_tenancy import get_president_id_for_user
        return await get_president_id_for_user(current_user, db)
    except Exception:
        result = await db.execute(select(President.id).limit(1))
        p_id = result.scalar_one_or_none()
        return p_id or 1




@presidentRouter.get("/statistics/summary")
async def get_statistics_summary(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    president_id = await resolve_president_id(current_user, db)
    
    total_students_res = await db.execute(
        select(func.count(Student.id)).where(Student.president_id == president_id)
    )
    total_students = total_students_res.scalar() or 0
    
    total_lectures_res = await db.execute(
        select(func.count(Lecture.id)).where(Lecture.president_id == president_id)
    )
    total_lectures = total_lectures_res.scalar() or 0
    
    att_res = await db.execute(
        select(Attendance.date, Attendance.status).where(Attendance.president_id == president_id)
    )
    all_att = att_res.all()
    
    today_str = datetime.now().strftime("%d-%m-%Y")
    present_today = sum(
        1 for d, s in all_att 
        if d == today_str and ("present" in str(s).lower() or "late" in str(s).lower())
    )
    if present_today == 0 and all_att:
        date_presents = defaultdict(int)
        for d, s in all_att:
          if "present" in str(s).lower() or "late" in str(s).lower():
              date_presents[d] += 1
        if date_presents:
          latest_d = list(date_presents.keys())[-1]
          present_today = date_presents[latest_d]
          
    achievements_res = await db.execute(
        select(Achievement.from_surah, Achievement.to_surah, Achievement.from_verse, Achievement.to_verse, Achievement.note)
        .where(Achievement.president_id == president_id)
    )
    achievements = achievements_res.all()
    total_pages = 0
    total_thoumoun = 0
    for ach in achievements:
        thoumoun = calculate_eighths(
            ach.from_surah,
            ach.from_verse,
            ach.to_surah,
            ach.to_verse
        )
        pages = max(1, round(thoumoun * 1.25))
        total_pages += pages
        total_thoumoun += thoumoun
        
    return {
        "total_students": total_students,
        "present_today": present_today,
        "total_eighths_memorized": total_thoumoun,
        "total_thoumoun_memorized": total_thoumoun,
        "formatted_progress": format_quran_progress(total_thoumoun),
        "total_pages_memorized": total_pages,
        "total_lectures": total_lectures
    }


@presidentRouter.get("/statistics/attendance-trend")
async def get_attendance_trend(
    limit: int = 10,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    president_id = await resolve_president_id(current_user, db)
    
    result = await db.execute(
        select(Attendance.date, Attendance.status)
        .where(Attendance.president_id == president_id)
    )
    records = result.all()
    
    grouped = defaultdict(lambda: {"present": 0, "absent": 0})
    for date_str, status in records:
        if not date_str:
          continue
        st = str(status).lower()
        if "present" in st or "late" in st:
          grouped[date_str]["present"] += 1
        else:
          grouped[date_str]["absent"] += 1

    def parse_d(d):
        try:
          parts = [int(p) for p in d.split("-")]
          if len(parts) == 3:
              if parts[0] > 31:
                  return (parts[0], parts[1], parts[2])
              return (parts[2], parts[1], parts[0])
        except Exception:
          pass
        return (0, 0, 0)
        
    sorted_dates = sorted(grouped.keys(), key=parse_d)
    latest_dates = sorted_dates[-limit:] if len(sorted_dates) > limit else sorted_dates
    
    data = []
    for d in latest_dates:
        pres = grouped[d]["present"]
        ab = grouped[d]["absent"]
        tot = pres + ab
        pct = f"{(pres / tot * 100):.1f}%" if tot > 0 else "0%"
        data.append({
          "date": d,
          "present": pres,
          "absent": ab,
          "total": tot,
          "percentage": pct
        })
        
    return data


@presidentRouter.get("/statistics/top-memorizers")
async def get_top_memorizers(
    limit: int = 5,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    president_id = await resolve_president_id(current_user, db)
    
    students_res = await db.execute(
        select(Student.id, User.firstname, User.lastname)
        .join(User, Student.user_id == User.id)
        .where(Student.president_id == president_id)
    )
    students = students_res.all()
    
    achievements_res = await db.execute(
        select(Achievement.student_id, Achievement.from_surah, Achievement.to_surah, Achievement.from_verse, Achievement.to_verse, Achievement.note)
        .where(Achievement.president_id == president_id)
    )
    achievements = achievements_res.all()
    
    student_pages = defaultdict(int)
    student_thoumoun = defaultdict(int)
    for ach in achievements:
        thoumoun = calculate_eighths(
            ach.from_surah,
            ach.from_verse,
            ach.to_surah,
            ach.to_verse
        )
        pages = max(1, round(thoumoun * 1.25))
        student_pages[ach.student_id] += pages
        student_thoumoun[ach.student_id] += thoumoun
        
    ranked = []
    for s_id, fname, lname in students:
        full_name = f"{fname or ''} {lname or ''}".strip() or f"طالب #{s_id}"
        pages = student_pages.get(s_id, 0)
        thoumoun = student_thoumoun.get(s_id, 0)
        ranked.append({
          "student": full_name,
          "eighths": thoumoun,
          "thoumoun": thoumoun,
          "formatted_progress": format_quran_progress(thoumoun),
          "pages": pages
        })
        
    ranked.sort(key=lambda x: x["thoumoun"], reverse=True)
    top = ranked[:limit]
    
    for idx, item in enumerate(top):
        item["rank"] = idx + 1
        
    return top


@presidentRouter.get("/statistics/lecture-distribution")
async def get_lecture_distribution(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    president_id = await resolve_president_id(current_user, db)
    
    lectures_res = await db.execute(
        select(Lecture.id, Lecture.lecture_name_ar, Lecture.lecture_name_en)
        .where(Lecture.president_id == president_id)
    )
    lectures = lectures_res.all()
    
    sp_res = await db.execute(
        select(SessionParticipation.lecture_id, func.count(func.distinct(SessionParticipation.student_id)))
        .where(SessionParticipation.lecture_id.isnot(None))
        .group_by(SessionParticipation.lecture_id)
    )
    counts = dict(sp_res.all())
    
    ach_res = await db.execute(
        select(Achievement.lecture_id, func.count(func.distinct(Achievement.student_id)))
        .where(Achievement.lecture_id.isnot(None), Achievement.president_id == president_id)
        .group_by(Achievement.lecture_id)
    )
    for l_id, c in ach_res.all():
        counts[l_id] = max(counts.get(l_id, 0), c)
        
    total_assigned = sum(counts.get(lec.id, 0) for lec in lectures)
    
    data = []
    for lec in lectures:
        cnt = counts.get(lec.id, 0)
        pct = f"{(cnt / total_assigned * 100):.1f}%" if total_assigned > 0 else "0.0%"
        data.append({
          "className": lec.lecture_name_ar or lec.lecture_name_en or f"حلقة #{lec.id}",
          "students": cnt,
          "percentage": pct
        })
        
    return data

