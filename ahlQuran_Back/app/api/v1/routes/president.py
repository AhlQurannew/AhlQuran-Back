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