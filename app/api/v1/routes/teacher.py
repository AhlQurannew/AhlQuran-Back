from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.teacher import Teacher
from app.models.lecture import Lecture
from app.schemas.teacher import TeacherCreate, TeacherUpdate, TeacherResponse, TeacherList
from app.core.dependencies import require_president_or_supervisor, require_teacher, require_president_or_admin
from app.core.security import get_password_hash
from app.core.multi_tenancy import get_president_id_for_user
import logging

logger = logging.getLogger(__name__)

teacherRouter = APIRouter()


# ==================== TEACHER'S STUDENT VIEW (READ-ONLY) ====================
# IMPORTANT: These routes MUST come BEFORE generic routes like "/" and "/{teacher_id}"
# to avoid route matching conflicts in FastAPI

from app.models.student import Student
from app.models.sessionParticipation import SessionParticipation
from app.schemas.student import StudentResponse, StudentList


def map_student_to_response(student: Student) -> StudentResponse:
    """Helper to map DB Student model to nested StudentResponse"""
    from app.schemas.student import (
        PersonalInfo, AccountInfo, ContactInfo, GuardianInfo,
        LectureInfo, FormalEducationInfo, MedicalInfo, SubscriptionInfo
    )
    
    # Personal Info
    personal_info = PersonalInfo(
        firstNameAr=student.user.firstname,
        lastNameAr=student.user.lastname,
        firstNameEn=student.first_name_en,
        lastNameEn=student.last_name_en,
        sex=student.sex,
        dateOfBirth=student.date_of_birth,
        placeOfBirth=student.place_of_birth,
        homeAddress=student.home_address,
        nationality=student.nationality,
        fatherStatus=student.father_status,
        motherStatus=student.mother_status
    )

    # Account Info
    account_info = AccountInfo(
        accountId=student.user.id,
        username=student.user.email,
        passcode="",  # Security: don't return hash
        accountType="Student"
    )

    # Contact Info
    contact_info = ContactInfo(
        phoneNumber=student.parent_phone,
        email=student.user.email
    )

    # Guardian Info
    guardian_info = GuardianInfo(
        guardianId=student.guardian_id,
        firstName=student.parent_name,
        email=student.guardian_email,
        lastName=None,
        relationship=None,
        guardianContactId=None,
        guardianAccountId=None,
        homeAddress=None,
        job=None,
        profileImage=None
    )

    # Formal Education Info
    education_info = FormalEducationInfo(
        academicLevel=student.academic_level,
        grade=student.grade,
        schoolName=student.school_name
    )

    # Lectures
    lectures_info = []
    if student.participations:
        for p in student.participations:
            if p.lecture:
                lectures_info.append(LectureInfo(
                    lectureId=p.lecture.id,
                    lectureNameAr=p.lecture.lecture_name_ar,
                    lectureNameEn=p.lecture.lecture_name_en
                ))

    # Medical Info (Placeholder)
    medical_info = MedicalInfo(
        medicalCondition=None,
        notes=None
    )

    # Subscription Info (Placeholder)
    subscription_info = SubscriptionInfo(
        subscriptionId=None,
        status="Active" if student.user.is_active else "Inactive"
    )

    return StudentResponse(
        id=student.id,
        user_id=student.user.id,
        personalInfo=personal_info,
        accountInfo=account_info,
        contactInfo=contact_info,
        guardian=guardian_info,
        lectures=lectures_info,
        formalEducationInfo=education_info,
        medicalInfo=medical_info,
        subscriptionInfo=subscription_info,
        
        # Legacy flat fields
        firstname=student.user.firstname,
        lastname=student.user.lastname,
        email=student.user.email,
        enrollment_date=student.enrollment_date,
        parent_name=student.parent_name,
        parent_phone=student.parent_phone,
        guardian_email=student.guardian_email,
        golden=student.Golden,
        is_active=student.user.is_active
    )


@teacherRouter.get("/my-students", response_model=StudentList)
async def get_my_students(
    skip: int = 0,
    limit: int = 100,
    lecture_id: int = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Get all students enrolled in lectures taught by the current teacher.
    This is a READ-ONLY endpoint - teachers cannot modify student data.
    Optionally filter by a specific lecture_id.
    """
    
    # Get the teacher record for the current user
    teacher_result = await db.execute(
        select(Teacher)
        .options(selectinload(Teacher.lectures))
        .where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    # Get all lecture IDs for this teacher
    teacher_lecture_ids = [lecture.id for lecture in teacher.lectures]
    
    logger.info(f"Teacher {teacher.id} has lectures: {teacher_lecture_ids}")
    
    if not teacher_lecture_ids:
        # Teacher has no lectures assigned
        logger.warning(f"Teacher {teacher.id} has no lectures assigned")
        return StudentList(students=[], total=0)
    
    # Build query to get students enrolled in teacher's lectures
    query = (
        select(Student)
        .join(Student.participations)
        .where(SessionParticipation.lecture_id.in_(teacher_lecture_ids))
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .distinct()
    )
    
    # If specific lecture_id is provided, filter further
    if lecture_id is not None:
        # Verify the lecture belongs to this teacher
        if lecture_id not in teacher_lecture_ids:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have access to students in this lecture"
            )
        query = query.where(SessionParticipation.lecture_id == lecture_id)
    
    # Apply pagination
    query = query.offset(skip).limit(limit)
    
    # Execute query
    result = await db.execute(query)
    students = result.scalars().unique().all()
    
    logger.info(f"Teacher {teacher.id} found {len(students)} students in lectures {teacher_lecture_ids}")
    
    # Get total count with same filters
    count_query = (
        select(Student)
        .join(Student.participations)
        .where(SessionParticipation.lecture_id.in_(teacher_lecture_ids))
        .distinct()
    )
    
    if lecture_id is not None:
        count_query = count_query.where(SessionParticipation.lecture_id == lecture_id)
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().unique().all())
    
    logger.info(f"Teacher {teacher.id} total students: {total}")
    
    # Map students to response format
    student_responses = [map_student_to_response(student) for student in students]
    
    logger.info(f"Teacher {teacher.id} viewed {len(students)} students")
    
    return StudentList(students=student_responses, total=total)


@teacherRouter.get("/my-students/{student_id}", response_model=StudentResponse)
async def get_my_student_detail(
    student_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Get detailed information about a specific student.
    Teachers can only view students enrolled in their lectures.
    This is READ-ONLY - teachers cannot modify student data.
    """
    
    # Get the teacher record for the current user
    teacher_result = await db.execute(
        select(Teacher)
        .options(selectinload(Teacher.lectures))
        .where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    # Get all lecture IDs for this teacher
    teacher_lecture_ids = [lecture.id for lecture in teacher.lectures]
    
    if not teacher_lecture_ids:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You have no lectures assigned"
        )
    
    # Get the student and verify they're in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .where(Student.id == student_id)
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )
    
    # Check if student is enrolled in any of the teacher's lectures
    student_lecture_ids = [p.lecture_id for p in student.participations if p.lecture_id]
    has_access = any(lecture_id in teacher_lecture_ids for lecture_id in student_lecture_ids)
    
    if not has_access:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this student's information"
        )
    
    logger.info(f"Teacher {teacher.id} viewed student {student_id}")
    
    return map_student_to_response(student)


@teacherRouter.get("/my-lectures", response_model=list)
async def get_my_lectures(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Get all lectures assigned to the current teacher with full details.
    Returns the same format as /special/lectures for consistency.
    """
    print("=" * 80)
    print("MY-LECTURES ENDPOINT CALLED!")
    print("=" * 80)
    
    from app.schemas.lecture import LectureResponse, TeacherResponse, WeeklyScheduleResponse
    from sqlalchemy.orm import joinedload
    
    # Get the teacher record
    teacher_result = await db.execute(
        select(Teacher)
        .where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    # Get lectures for this teacher - using join like the working endpoint
    logger.info(f"Fetching lectures for teacher ID: {teacher.id}")
    result_query = await db.execute(
        select(Lecture)
        .join(Lecture.teachers)
        .where(Teacher.id == teacher.id)
        .options(
            joinedload(Lecture.teachers).joinedload(Teacher.user),
            joinedload(Lecture.schedules)
        )
    )
    lectures = result_query.scalars().unique().all()
    logger.info(f"Found {len(lectures)} lectures for teacher {teacher.id}")
    
    # Get all lecture IDs for this teacher
    teacher_lecture_ids = [lecture.id for lecture in lectures]
    
    result = []
    for lecture in lectures:
        # Get student count for this lecture - use explicit join
        count_query = await db.execute(
            select(func.count(func.distinct(Student.id)))
            .select_from(Student)
            .join(SessionParticipation, Student.id == SessionParticipation.student_id)
            .where(SessionParticipation.lecture_id == lecture.id)
        )
        student_count = count_query.scalar() or 0
        
        # Debug logging
        logger.info(f"Teacher {teacher.id} - Lecture {lecture.id} ({lecture.lecture_name_ar}): {student_count} students")
        
        # Build teacher response
        teachers_data = []
        for lec_teacher in lecture.teachers:
            teachers_data.append(TeacherResponse(
                teacher_id=lec_teacher.id,
                first_name=lec_teacher.user.firstname if lec_teacher.user else None,
                last_name=lec_teacher.user.lastname if lec_teacher.user else None
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
    
    # Debug: Print the result before returning
    logger.info(f"Returning {len(result)} lectures to teacher {teacher.id}")
    for lec_response in result:
        logger.info(f"  - {lec_response.lecture_name_ar}: student_count={lec_response.student_count}")
    
    return result


@teacherRouter.post("/session_creation", response_model=dict)
async def create_teacher_session():
    return {"detail": "Session creation endpoint - to be implemented"}


# ==================== ADMIN TEACHER MANAGEMENT ====================
# These routes require president/supervisor privileges

@teacherRouter.post("/", response_model=TeacherResponse, status_code=status.HTTP_201_CREATED)
async def create_teacher(
    teacher_data: TeacherCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Create a new teacher. Only presidents and supervisors can create teachers."""
    logger.debug(f"teacher data :  {teacher_data} \n current user: {current_user}")

    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    # Check if email already exists
    result = await db.execute(
        select(User).where(User.email == teacher_data.email)
    )
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create user record with TEACHER role
    new_user = User(
        firstname=teacher_data.firstname,
        lastname=teacher_data.lastname,
        email=teacher_data.email,
        hashed_password=get_password_hash(teacher_data.password),
        role=UserRoleEnum.TEACHER,
        is_active=True
    )

    db.add(new_user)
    await db.flush()  # Flush to get the user ID

    # Create teacher record with teacher-specific fields and president_id
    new_teacher = Teacher(
        user_id=new_user.id,
        president_id=president_id,
        riwaya=teacher_data.riwaya,
        created_by_id=current_user.id
    )

    db.add(new_teacher)
    await db.commit()
    await db.refresh(new_teacher)
    await db.refresh(new_user)

    logger.info(f"Teacher created: {new_teacher.id} by user {current_user.id}")

    return TeacherResponse(
        id=new_teacher.id,
        user_id=new_user.id,
        firstname=new_user.firstname,
        lastname=new_user.lastname,
        email=new_user.email,
        riwaya=new_teacher.riwaya,
        hire_date=new_teacher.hire_date,
        is_active=new_user.is_active
    )


@teacherRouter.get("/", response_model=TeacherList)
async def list_teachers(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Get all teachers. Only presidents and supervisors can view all teachers."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    result = await db.execute(
        select(Teacher)
        .options(selectinload(Teacher.user))
        .where(Teacher.president_id == president_id)
        .offset(skip)
        .limit(limit)
    )
    teachers = result.scalars().all()

    # Get total count with same filter
    count_result = await db.execute(
        select(Teacher).where(Teacher.president_id == president_id)
    )
    total = len(count_result.scalars().all())

    teacher_responses = [
        TeacherResponse(
            id=teacher.id,
            user_id=teacher.user.id,
            firstname=teacher.user.firstname,
            lastname=teacher.user.lastname,
            email=teacher.user.email,
            riwaya=teacher.riwaya,
            hire_date=teacher.hire_date,
            is_active=teacher.user.is_active
        )
        for teacher in teachers
    ]

    return TeacherList(teachers=teacher_responses, total=total)


@teacherRouter.get("/{teacher_id}", response_model=TeacherResponse)
async def get_teacher(
    teacher_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Get a specific teacher by ID."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    result = await db.execute(
        select(Teacher)
        .options(selectinload(Teacher.user))
        .where(Teacher.id == teacher_id, Teacher.president_id == president_id)
    )
    teacher = result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Teacher with ID {teacher_id} not found"
        )

    return TeacherResponse(
        id=teacher.id,
        user_id=teacher.user.id,
        firstname=teacher.user.firstname,
        lastname=teacher.user.lastname,
        email=teacher.user.email,
        riwaya=teacher.riwaya,
        hire_date=teacher.hire_date,
        is_active=teacher.user.is_active
    )


@teacherRouter.put("/{teacher_id}", response_model=TeacherResponse)
async def update_teacher(
    teacher_id: int,
    teacher_data: TeacherUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Update teacher information. Only presidents and supervisors can update teachers."""

    result = await db.execute(
        select(Teacher)
        .options(selectinload(Teacher.user))
        .where(Teacher.id == teacher_id)
    )
    teacher = result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Teacher with ID {teacher_id} not found"
        )

    # Update user fields
    update_data = teacher_data.model_dump(exclude_unset=True)

    if "firstname" in update_data:
        teacher.user.firstname = update_data["firstname"]
    if "lastname" in update_data:
        teacher.user.lastname = update_data["lastname"]
    if "email" in update_data:
        # Check if new email is already taken
        email_result = await db.execute(
            select(User).where(User.email == update_data["email"], User.id != teacher.user.id)
        )
        if email_result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        teacher.user.email = update_data["email"]

    # Update teacher-specific fields
    if "riwaya" in update_data:
        teacher.riwaya = update_data["riwaya"]

    await db.commit()
    await db.refresh(teacher)
    await db.refresh(teacher.user)

    logger.info(f"Teacher {teacher_id} updated by user {current_user.id}")

    return TeacherResponse(
        id=teacher.id,
        user_id=teacher.user.id,
        firstname=teacher.user.firstname,
        lastname=teacher.user.lastname,
        email=teacher.user.email,
        riwaya=teacher.riwaya,
        hire_date=teacher.hire_date,
        is_active=teacher.user.is_active
    )


@teacherRouter.delete("/{teacher_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_teacher(
    teacher_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Delete a teacher. Only presidents and supervisors can delete teachers."""

    result = await db.execute(
        select(Teacher).where(Teacher.id == teacher_id)
    )
    teacher = result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Teacher with ID {teacher_id} not found"
        )

    # Delete the teacher (will cascade to user due to relationship)
    await db.delete(teacher)
    await db.commit()
    
    logger.info(f"Teacher {teacher_id} deleted by user {current_user.id}")

    return None


# ==================== TEACHER ATTENDANCE OPERATIONS ====================

from app.models.teacher_attendance import TeacherAttendance
from app.schemas.teacher_attendance import (
    TeacherAttendanceCreate,
    TeacherAttendanceUpdate,
    TeacherAttendanceResponse,
    TeacherAttendanceList
)


@teacherRouter.post("/{teacher_id}/attendance", response_model=TeacherAttendanceResponse, status_code=status.HTTP_201_CREATED)
async def create_teacher_attendance(
    teacher_id: int,
    attendance_data: TeacherAttendanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Create or update attendance record for a teacher on a specific date."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    # Verify teacher exists and belongs to this president
    result = await db.execute(
        select(Teacher).where(Teacher.id == teacher_id, Teacher.president_id == president_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Teacher with ID {teacher_id} not found"
        )

    # Check if attendance already exists for this teacher and date
    existing_result = await db.execute(
        select(TeacherAttendance).where(
            TeacherAttendance.teacher_id == teacher_id,
            TeacherAttendance.date == attendance_data.date,
            TeacherAttendance.president_id == president_id
        )
    )
    existing_attendance = existing_result.scalar_one_or_none()

    if existing_attendance:
        # Update existing attendance
        existing_attendance.status = attendance_data.status
        existing_attendance.notes = attendance_data.notes
        await db.commit()
        await db.refresh(existing_attendance)
        logger.info(f"Teacher attendance updated for teacher {teacher_id} on {attendance_data.date} by user {current_user.id}")
        return existing_attendance

    # Create new attendance record with president_id
    new_attendance = TeacherAttendance(
        teacher_id=teacher_id,
        president_id=president_id,
        date=attendance_data.date,
        status=attendance_data.status,
        notes=attendance_data.notes
    )

    db.add(new_attendance)
    await db.commit()
    await db.refresh(new_attendance)

    logger.info(f"Teacher attendance created for teacher {teacher_id} on {attendance_data.date} by user {current_user.id}")

    return new_attendance


@teacherRouter.get("/{teacher_id}/attendance", response_model=TeacherAttendanceList)
async def get_teacher_attendance(
    teacher_id: int,
    date: str = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Get attendance records for a specific teacher. Optionally filter by date."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    # Verify teacher exists and belongs to this president
    result = await db.execute(
        select(Teacher).where(Teacher.id == teacher_id, Teacher.president_id == president_id)
    )
    teacher = result.scalar_one_or_none()

    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Teacher with ID {teacher_id} not found"
        )

    # Build query with president_id filter
    query = select(TeacherAttendance).where(
        TeacherAttendance.teacher_id == teacher_id,
        TeacherAttendance.president_id == president_id
    )
    
    # Filter by date if provided
    if date:
        query = query.where(TeacherAttendance.date == date)
    
    query = query.order_by(TeacherAttendance.created_at.desc()).offset(skip).limit(limit)

    # Get attendance records
    attendance_result = await db.execute(query)
    attendances = attendance_result.scalars().all()

    # Get total count with same filters
    count_query = select(TeacherAttendance).where(
        TeacherAttendance.teacher_id == teacher_id,
        TeacherAttendance.president_id == president_id
    )
    if date:
        count_query = count_query.where(TeacherAttendance.date == date)
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().all())

    return TeacherAttendanceList(attendances=list(attendances), total=total)


@teacherRouter.put("/{teacher_id}/attendance/{attendance_id}", response_model=TeacherAttendanceResponse)
async def update_teacher_attendance(
    teacher_id: int,
    attendance_id: int,
    attendance_data: TeacherAttendanceUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Update a teacher attendance record."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    result = await db.execute(
        select(TeacherAttendance).where(
            TeacherAttendance.id == attendance_id,
            TeacherAttendance.teacher_id == teacher_id,
            TeacherAttendance.president_id == president_id
        )
    )
    attendance = result.scalar_one_or_none()

    if not attendance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Attendance with ID {attendance_id} not found for teacher {teacher_id}"
        )

    # Update fields
    update_data = attendance_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(attendance, field, value)

    await db.commit()
    await db.refresh(attendance)

    logger.info(f"Teacher attendance {attendance_id} updated by user {current_user.id}")

    return attendance


@teacherRouter.delete("/{teacher_id}/attendance/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_teacher_attendance(
    teacher_id: int,
    attendance_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Delete a teacher attendance record."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    result = await db.execute(
        select(TeacherAttendance).where(
            TeacherAttendance.id == attendance_id,
            TeacherAttendance.teacher_id == teacher_id,
            TeacherAttendance.president_id == president_id
        )
    )
    attendance = result.scalar_one_or_none()

    if not attendance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Attendance with ID {attendance_id} not found for teacher {teacher_id}"
        )

    await db.delete(attendance)
    await db.commit()

    logger.info(f"Teacher attendance {attendance_id} deleted by user {current_user.id}")

    return None


# ==================== STUDENT ATTENDANCE OPERATIONS (TEACHER ACCESS) ====================

from app.models.attendance import Attendance
from app.schemas.attendance import (
    AttendanceCreate,
    AttendanceUpdate,
    AttendanceResponse,
    AttendanceList
)


@teacherRouter.post("/my-students/{student_id}/attendance", response_model=AttendanceResponse, status_code=status.HTTP_201_CREATED)
async def create_student_attendance_as_teacher(
    student_id: int,
    attendance_data: AttendanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Create or update attendance record for a student.
    Teachers can only mark attendance for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Validate attendance data belongs to the correct student
    if attendance_data.student_id != student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student ID in URL must match student_id in request body"
        )
    
    # Check if attendance already exists for this student and date
    existing_result = await db.execute(
        select(Attendance).where(
            Attendance.student_id == student_id,
            Attendance.date == attendance_data.date,
            Attendance.president_id == president_id
        )
    )
    existing_attendance = existing_result.scalar_one_or_none()
    
    if existing_attendance:
        # Update existing attendance
        existing_attendance.status = attendance_data.status
        existing_attendance.notes = attendance_data.notes
        await db.commit()
        await db.refresh(existing_attendance)
        logger.info(f"Attendance updated for student {student_id} on {attendance_data.date} by teacher {teacher.id}")
        return existing_attendance
    
    # Create new attendance record with president_id
    new_attendance = Attendance(
        student_id=student_id,
        president_id=president_id,
        date=attendance_data.date,
        status=attendance_data.status,
        notes=attendance_data.notes
    )
    
    db.add(new_attendance)
    await db.commit()
    await db.refresh(new_attendance)
    
    logger.info(f"Attendance created for student {student_id} on {attendance_data.date} by teacher {teacher.id}")
    
    return new_attendance


@teacherRouter.get("/my-students/{student_id}/attendance", response_model=AttendanceList)
async def get_student_attendance_as_teacher(
    student_id: int,
    date: str = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Get attendance records for a specific student.
    Teachers can only view attendance for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Build query with president_id filter
    query = select(Attendance).where(
        Attendance.student_id == student_id,
        Attendance.president_id == president_id
    )
    
    # Filter by date if provided
    if date:
        query = query.where(Attendance.date == date)
    
    query = query.order_by(Attendance.created_at.desc()).offset(skip).limit(limit)
    
    # Get attendance records
    attendance_result = await db.execute(query)
    attendances = attendance_result.scalars().all()
    
    # Get total count with president_id filter
    count_query = select(Attendance).where(
        Attendance.student_id == student_id,
        Attendance.president_id == president_id
    )
    if date:
        count_query = count_query.where(Attendance.date == date)
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().all())
    
    return AttendanceList(attendances=list(attendances), total=total)


@teacherRouter.put("/my-students/{student_id}/attendance/{attendance_id}", response_model=AttendanceResponse)
async def update_student_attendance_as_teacher(
    student_id: int,
    attendance_id: int,
    attendance_data: AttendanceUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Update an attendance record.
    Teachers can only update attendance for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Get the attendance record with president_id filter
    result = await db.execute(
        select(Attendance).where(
            Attendance.id == attendance_id,
            Attendance.student_id == student_id,
            Attendance.president_id == president_id
        )
    )
    attendance = result.scalar_one_or_none()
    
    if not attendance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Attendance with ID {attendance_id} not found for student {student_id}"
        )
    
    # Update fields
    update_data = attendance_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(attendance, field, value)
    
    await db.commit()
    await db.refresh(attendance)
    
    logger.info(f"Attendance {attendance_id} updated by teacher {teacher.id}")
    
    return attendance


@teacherRouter.delete("/my-students/{student_id}/attendance/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_student_attendance_as_teacher(
    student_id: int,
    attendance_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Delete an attendance record.
    Teachers can only delete attendance for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Get the attendance record with president_id filter
    result = await db.execute(
        select(Attendance).where(
            Attendance.id == attendance_id,
            Attendance.student_id == student_id,
            Attendance.president_id == president_id
        )
    )
    attendance = result.scalar_one_or_none()
    
    if not attendance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Attendance with ID {attendance_id} not found for student {student_id}"
        )
    
    await db.delete(attendance)
    await db.commit()
    
    logger.info(f"Attendance {attendance_id} deleted by teacher {teacher.id}")
    
    return None


# ==================== STUDENT ACHIEVEMENT OPERATIONS (TEACHER ACCESS) ====================

from app.models.acheivements import Achievement
from app.schemas.achievement import (
    AchievementCreate,
    AchievementUpdate,
    AchievementResponse,
    AchievementList
)


@teacherRouter.post("/my-students/{student_id}/achievements", response_model=AchievementResponse, status_code=status.HTTP_201_CREATED)
async def add_student_achievement_as_teacher(
    student_id: int,
    achievement_data: AchievementCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Add an achievement/progress record for a student.
    Teachers can only add achievements for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Validate achievement data belongs to the correct student
    if achievement_data.student_id != student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student ID in URL must match student_id in request body"
        )
    
    # Create achievement record with president_id
    new_achievement = Achievement(
        student_id=student_id,
        president_id=president_id,
        from_surah=achievement_data.from_surah,
        to_surah=achievement_data.to_surah,
        from_verse=achievement_data.from_verse,
        to_verse=achievement_data.to_verse,
        note=achievement_data.note,
        achievement_type=achievement_data.achievement_type,
        date=achievement_data.date
    )
    
    db.add(new_achievement)
    await db.commit()
    await db.refresh(new_achievement)
    
    logger.info(f"Achievement added for student {student_id} by teacher {teacher.id}")
    
    return new_achievement


@teacherRouter.get("/my-students/{student_id}/achievements", response_model=AchievementList)
async def get_student_achievements_as_teacher(
    student_id: int,
    skip: int = 0,
    limit: int = 100,
    date: str = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Get all achievements for a specific student, optionally filtered by date.
    Teachers can only view achievements for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Build query with president_id and optional date filter
    query = select(Achievement).where(
        Achievement.student_id == student_id,
        Achievement.president_id == president_id
    )
    
    if date:
        query = query.where(Achievement.date == date)
    
    # Get achievements
    achievements_result = await db.execute(
        query
        .offset(skip)
        .limit(limit)
        .order_by(Achievement.created_at.desc())
    )
    achievements = achievements_result.scalars().all()
    
    # Get total count with same filters
    count_query = select(Achievement).where(
        Achievement.student_id == student_id,
        Achievement.president_id == president_id
    )
    if date:
        count_query = count_query.where(Achievement.date == date)
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().all())
    
    return AchievementList(achievements=list(achievements), total=total)


@teacherRouter.put("/my-students/{student_id}/achievements/{achievement_id}", response_model=AchievementResponse)
async def update_student_achievement_as_teacher(
    student_id: int,
    achievement_id: int,
    achievement_data: AchievementUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Update an achievement record.
    Teachers can only update achievements for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Get the achievement record with president_id filter
    result = await db.execute(
        select(Achievement).where(
            Achievement.id == achievement_id,
            Achievement.student_id == student_id,
            Achievement.president_id == president_id
        )
    )
    achievement = result.scalar_one_or_none()
    
    if not achievement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Achievement with ID {achievement_id} not found for student {student_id}"
        )
    
    # Update fields
    update_data = achievement_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(achievement, field, value)
    
    await db.commit()
    await db.refresh(achievement)
    
    logger.info(f"Achievement {achievement_id} updated by teacher {teacher.id}")
    
    return achievement


@teacherRouter.delete("/my-students/{student_id}/achievements/{achievement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_student_achievement_as_teacher(
    student_id: int,
    achievement_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher)
):
    """
    Delete an achievement record.
    Teachers can only delete achievements for students in their lectures.
    """
    
    # Get the teacher record with president_id
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == current_user.id)
    )
    teacher = teacher_result.scalar_one_or_none()
    
    if not teacher:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Teacher record not found for current user"
        )
    
    president_id = teacher.president_id
    
    # Verify student exists and is in one of the teacher's lectures
    student_result = await db.execute(
        select(Student)
        .join(SessionParticipation, Student.id == SessionParticipation.student_id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .join(Lecture.teachers)
        .where(
            Student.id == student_id,
            Teacher.id == teacher.id,
            Student.president_id == president_id
        )
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Student with ID {student_id} not found in your lectures"
        )
    
    # Get the achievement record with president_id filter
    result = await db.execute(
        select(Achievement).where(
            Achievement.id == achievement_id,
            Achievement.student_id == student_id,
            Achievement.president_id == president_id
        )
    )
    achievement = result.scalar_one_or_none()
    
    if not achievement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Achievement with ID {achievement_id} not found for student {student_id}"
        )
    
    await db.delete(achievement)
    await db.commit()
    
    logger.info(f"Achievement {achievement_id} deleted by teacher {teacher.id}")
    
    return None
