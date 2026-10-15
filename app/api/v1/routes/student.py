from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import FileResponse
from pathlib import Path
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, or_, select
from sqlalchemy.orm import selectinload
from datetime import date

from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.admin import Admin
from app.models.student import Student
from app.models.guardian import Guardian
from app.models.acheivements import Achievement
from app.models.attendance import Attendance
from app.models.session import Session
from app.models.lecture import Lecture
from app.models.teacher import Teacher
from app.models.sessionParticipation import SessionParticipation
from app.schemas.student import (
    StudentCreate, StudentUpdate, StudentResponse, StudentList,
    PersonalInfo, AccountInfo, ContactInfo, GuardianInfo, 
    LectureInfo, FormalEducationInfo, MedicalInfo, SubscriptionInfo
)
from app.schemas.achievement import AchievementCreate, AchievementBulkCreate, AchievementUpdate, AchievementResponse, AchievementList
from app.schemas.attendance import AttendanceCreate, AttendanceUpdate, AttendanceResponse, AttendanceList, AttendanceBulkSave
from app.schemas.student_full import StudentCreateFull
from app.core.dependencies import (
    get_current_user,
    require_president_or_supervisor,
    require_president_or_admin,
    require_school_management_access,
    require_teacher_or_above,
)
from app.core.multi_tenancy import get_president_id_for_user
from app.core.security import get_password_hash
from app.core.config import settings
from app.services.profile_images import (
    MAX_PROFILE_IMAGE_BYTES,
    remove_student_profile_image,
    store_student_profile_image,
)

import logging
logger = logging.getLogger(__name__)

studentRouter = APIRouter()


async def _get_accessible_student(
    student_id: int,
    current_user,
    db: AsyncSession,
    school_id: int | None = None,
) -> Student:
    president_id = await get_president_id_for_user(current_user, db, school_id)
    result = await db.execute(
        select(Student).where(
            Student.id == student_id,
            Student.president_id == president_id,
        )
    )
    student = result.scalar_one_or_none()
    if student is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
    return student


async def _validate_guardian_link(
    db: AsyncSession,
    guardian_id: int | None,
    president_id: int,
) -> Guardian | None:
    if guardian_id is None:
        return None
    result = await db.execute(
        select(Guardian).where(
            Guardian.id == guardian_id,
            Guardian.president_id == president_id,
        )
    )
    guardian = result.scalar_one_or_none()
    if guardian is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Guardian not found or does not belong to your organization",
        )
    return guardian


async def _ensure_teacher_owns_lecture(
    current_user: User,
    lecture_id: int,
    db: AsyncSession,
) -> None:
    if getattr(current_user, "role", None) != UserRoleEnum.TEACHER:
        return
    result = await db.execute(
        select(Lecture.id)
        .join(Lecture.teachers)
        .where(Lecture.id == lecture_id, Teacher.user_id == current_user.id)
        .limit(1)
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(status_code=403, detail="You do not teach this lecture")


def map_student_to_response(student: Student) -> StudentResponse:
    """Helper to map DB Student model to nested StudentResponse"""
    
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
        username=student.user.email, # Using email as username
        passcode="", # Security: don't return hash
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
        firstName=student.parent_name, # Assuming full name
        email=student.guardian_email,
        # Other fields not in DB
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
        photo=f"{settings.API_V1_PREFIX}/students/{student.id}/photo" if student.profile_image else None,
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


def _ensure_photo_manager(current_user) -> None:
    if not isinstance(current_user, Admin) and current_user.role not in {
        UserRoleEnum.PRESIDENT, UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR
    }:
        raise HTTPException(status_code=403, detail="You cannot manage student profile images")


async def _get_photo_student(student_id: int, db: AsyncSession, current_user, school_id: int | None) -> Student:
    _ensure_photo_manager(current_user)
    result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture),
        )
        .where(Student.id == student_id)
    )
    student = result.scalar_one_or_none()
    if not student:
        raise HTTPException(status_code=404, detail="Student not found")
    president_id = await get_president_id_for_user(current_user, db, school_id)
    if student.president_id != president_id:
        raise HTTPException(status_code=404, detail="Student not found")
    return student


@studentRouter.get("/{student_id}/photo")
async def get_student_photo(
    student_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
    school_id: int | None = None,
):
    student = await _get_photo_student(student_id, db, current_user, school_id)
    if not student.profile_image:
        raise HTTPException(status_code=404, detail="Student has no profile image")
    upload_root = Path(settings.UPLOAD_DIR).resolve()
    image_path = (upload_root / student.profile_image).resolve()
    if not image_path.is_relative_to(upload_root) or not image_path.is_file():
        raise HTTPException(status_code=404, detail="Student profile image not found")
    return FileResponse(
        image_path,
        media_type="image/webp",
        headers={"Cache-Control": "private, no-store"},
    )


@studentRouter.post("/", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
async def create_student(
    student_data: StudentCreateFull,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_admin),
    school_id: int = None
):
    # Get president ID (works for both presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)
    guardian = await _validate_guardian_link(
        db, student_data.guardian.guardian_id, president_id
    )
    
    # Check if email already exists
    result = await db.execute(
        select(User).where(User.email == student_data.contactInfo.email)
    )
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create user record
    new_user = User(
        firstname=student_data.personalInfo.first_name_ar,
        lastname=student_data.personalInfo.last_name_ar,
        email=student_data.contactInfo.email,
        hashed_password=get_password_hash(student_data.accountInfo.passcode),
        role=UserRoleEnum.STUDENT,
        is_active=True
    )

    db.add(new_user)
    await db.flush()

    # Create student record with president_id
    # Construct parent name from guardian info
    parent_name = (
        f"{guardian.first_name} {guardian.last_name}" if guardian else
        f"{student_data.guardian.first_name or ''} {student_data.guardian.last_name or ''}".strip()
    )
    
    new_student = Student(
        user_id=new_user.id,
        parent_name=parent_name if parent_name else None,
        parent_phone=guardian.phone_number if guardian else student_data.contactInfo.phone_number,
        guardian_email=guardian.email if guardian else student_data.guardian.email,
        created_by_id=current_user.id,
        president_id=president_id,
        Golden=False,
        
        # New Fields Mapped from JSON
        sex=student_data.personalInfo.sex,
        date_of_birth=student_data.personalInfo.date_of_birth,
        place_of_birth=student_data.personalInfo.place_of_birth,
        home_address=student_data.personalInfo.home_address,
        nationality=student_data.personalInfo.nationality,
        
        # English name fields
        first_name_en=student_data.personalInfo.first_name_en,
        last_name_en=student_data.personalInfo.last_name_en,
        
        # Parent status fields
        father_status=student_data.personalInfo.father_status,
        mother_status=student_data.personalInfo.mother_status,
        
        academic_level=student_data.formalEducationInfo.academic_level,
        grade=student_data.formalEducationInfo.grade,
        school_name=student_data.formalEducationInfo.school_name,
        
        guardian_id=guardian.id if guardian else None
    )

    db.add(new_student)
    await db.flush() # Flush to get student ID

    # Handle Lectures (Session Participation)
    if student_data.lectures:
        for lecture in student_data.lectures:
            participation = SessionParticipation(
                student_id=new_student.id,
                session_id=None,  # Will be set when actual sessions are created
                lecture_id=lecture.lecture_id,
                # Add other fields if needed, e.g. join_date
            )
            db.add(participation)

    await db.commit()
    
    # Reload with relationships for response mapping
    result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .where(Student.id == new_student.id)
    )
    loaded_student = result.scalar_one()

    logger.info(f"Student created: {new_student.id} by user {current_user.id}")

    return map_student_to_response(loaded_student)


@studentRouter.post("/{student_id}/photo", response_model=StudentResponse)
async def upload_student_photo(
    student_id: int,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
    school_id: int | None = None,
):
    """Upload a validated student profile image for the current school."""
    student = await _get_photo_student(student_id, db, current_user, school_id)

    allowed_types = {"image/png", "image/jpeg", "image/webp"}
    if file.content_type and file.content_type not in allowed_types:
        raise HTTPException(status_code=415, detail="Upload a PNG, JPG, JPEG, or WebP image")
    contents = bytearray()
    while chunk := await file.read(64 * 1024):
        contents.extend(chunk)
        if len(contents) > MAX_PROFILE_IMAGE_BYTES:
            raise HTTPException(status_code=413, detail="Image must be 2 MB or smaller")
    if not contents:
        raise HTTPException(status_code=400, detail="The uploaded image is empty")

    try:
        stored_path = await run_in_threadpool(store_student_profile_image, bytes(contents), student_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    old_path = student.profile_image
    student.profile_image = stored_path
    try:
        await db.commit()
    except Exception:
        await db.rollback()
        await run_in_threadpool(remove_student_profile_image, stored_path)
        raise
    await run_in_threadpool(remove_student_profile_image, old_path)
    await db.refresh(student)
    logger.info("Student %s profile image updated by user %s", student_id, current_user.id)
    return map_student_to_response(student)


@studentRouter.delete("/{student_id}/photo", status_code=status.HTTP_204_NO_CONTENT)
async def delete_student_photo(
    student_id: int,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(get_current_user),
    school_id: int | None = None,
):
    student = await _get_photo_student(student_id, db, current_user, school_id)
    old_path = student.profile_image
    student.profile_image = None
    await db.commit()
    await run_in_threadpool(remove_student_profile_image, old_path)


@studentRouter.get("/", response_model=StudentList)
async def list_students(
    skip: int = 0,
    limit: int = 100,
    lecture_id: int = None,
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
    current_user = Depends(require_president_or_admin),
    school_id: int = None
):
    """Get all students. Optionally filter by lecture_id. Presidents, supervisors, and admins can view students."""

    # Get president ID for filtering (works for presidents, supervisors, and admins)
    president_id = await get_president_id_for_user(current_user, db, school_id)

    # Build query with president_id filter and optional lecture filter
    query = select(Student).options(
        selectinload(Student.user),
        selectinload(Student.participations).selectinload(SessionParticipation.lecture)
    ).where(Student.president_id == president_id)

    search_term = (search or "").strip()
    if search_term:
        pattern = f"%{search_term}%"
        search_filter = or_(
            User.firstname.ilike(pattern),
            User.lastname.ilike(pattern),
            User.email.ilike(pattern),
            func.concat(User.firstname, " ", User.lastname).ilike(pattern),
            Student.first_name_en.ilike(pattern),
            Student.last_name_en.ilike(pattern),
        )
        query = query.join(User, Student.user_id == User.id).where(search_filter)
    
    # If lecture_id is provided, filter students by lecture
    if lecture_id is not None:
        query = query.join(Student.participations).where(
            SessionParticipation.lecture_id == lecture_id
        ).distinct()
    
    query = query.offset(skip).limit(limit)
    
    result = await db.execute(query)
    students = result.scalars().unique().all()

    # Get total count with same filter
    count_query = select(Student).where(Student.president_id == president_id)
    if search_term:
        count_query = count_query.join(User, Student.user_id == User.id).where(search_filter)
    if lecture_id is not None:
        count_query = count_query.join(Student.participations).where(
            SessionParticipation.lecture_id == lecture_id
        ).distinct()
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().unique().all())

    student_responses = [map_student_to_response(student) for student in students]

    return StudentList(students=student_responses, total=total)


@studentRouter.get("/{student_id}", response_model=StudentResponse)
async def get_student(
    student_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Get a specific student by ID."""

    result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .where(Student.id == student_id)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )

    return map_student_to_response(student)


@studentRouter.put("/{student_id}", response_model=StudentResponse)
async def update_student(
    student_id: int,
    student_data: StudentUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Update student information. Only presidents and supervisors can update students."""

    result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .where(Student.id == student_id)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )

    # Update user fields
    update_data = student_data.model_dump(exclude_unset=True)

    if "firstname" in update_data:
        student.user.firstname = update_data["firstname"]
    if "lastname" in update_data:
        student.user.lastname = update_data["lastname"]
    if "email" in update_data:
        # Check if new email is already taken
        email_result = await db.execute(
            select(User).where(User.email == update_data["email"], User.id != student.user.id)
        )
        if email_result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        student.user.email = update_data["email"]

    # Update student-specific fields
    if "parent_name" in update_data:
        student.parent_name = update_data["parent_name"]
    if "parent_phone" in update_data:
        student.parent_phone = update_data["parent_phone"]
    if "guardian_email" in update_data:
        student.guardian_email = update_data["guardian_email"]
    if "golden" in update_data:
        student.Golden = update_data["golden"]

    await db.commit()
    await db.refresh(student)
    await db.refresh(student.user)
    # Refresh participations if needed, but they are not updated here

    logger.info(f"Student {student_id} updated by user {current_user.id}")

    return map_student_to_response(student)


@studentRouter.put("/{student_id}/full", response_model=StudentResponse)
async def update_student_full(
    student_id: int,
    student_data: StudentCreateFull,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """
    Update complete student information with nested structure.
    This endpoint accepts the same schema as POST for full updates.
    """
    
    president_id = await get_president_id_for_user(current_user, db)

    # Scope the update and guardian assignment to the current organization.
    result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .where(Student.id == student_id, Student.president_id == president_id)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )

    guardian = await _validate_guardian_link(
        db, student_data.guardian.guardian_id, president_id
    )

    # Check if email is being changed and if new email is already taken by another user
    if student_data.contactInfo.email != student.user.email:
        email_result = await db.execute(
            select(User).where(
                User.email == student_data.contactInfo.email,
                User.id != student.user.id
            )
        )
        if email_result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )

    # Update User fields
    student.user.firstname = student_data.personalInfo.first_name_ar
    student.user.lastname = student_data.personalInfo.last_name_ar
    student.user.email = student_data.contactInfo.email
    
    # Update password only if provided and different
    if student_data.accountInfo.passcode:
        student.user.hashed_password = get_password_hash(student_data.accountInfo.passcode)

    # Update Student fields - Personal Info
    student.sex = student_data.personalInfo.sex
    student.date_of_birth = student_data.personalInfo.date_of_birth
    student.place_of_birth = student_data.personalInfo.place_of_birth
    student.home_address = student_data.personalInfo.home_address
    student.nationality = student_data.personalInfo.nationality
    
    # Update English name fields
    student.first_name_en = student_data.personalInfo.first_name_en
    student.last_name_en = student_data.personalInfo.last_name_en
    
    # Update Parent status fields
    student.father_status = student_data.personalInfo.father_status
    student.mother_status = student_data.personalInfo.mother_status

    # Update Contact Info
    student.parent_phone = student_data.contactInfo.phone_number

    # Update Guardian Info
    parent_name = (
        f"{guardian.first_name} {guardian.last_name}" if guardian else
        f"{student_data.guardian.first_name or ''} {student_data.guardian.last_name or ''}".strip()
    )
    student.parent_name = parent_name if parent_name else None
    student.guardian_email = guardian.email if guardian else student_data.guardian.email
    student.parent_phone = guardian.phone_number if guardian else student_data.contactInfo.phone_number
    student.guardian_id = guardian.id if guardian else None

    # Update Formal Education Info
    student.academic_level = student_data.formalEducationInfo.academic_level
    student.grade = student_data.formalEducationInfo.grade
    student.school_name = student_data.formalEducationInfo.school_name

    # Update Lectures (Session Participations)
    # Remove existing participations
    await db.execute(
        SessionParticipation.__table__.delete().where(
            SessionParticipation.student_id == student_id
        )
    )
    
    # Add new participations
    if student_data.lectures:
        for lecture in student_data.lectures:
            participation = SessionParticipation(
                student_id=student_id,
                session_id=None,  # Will be set when actual sessions are created
                lecture_id=lecture.lecture_id,
            )
            db.add(participation)

    await db.commit()
    
    # Reload with relationships for response
    result = await db.execute(
        select(Student)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .where(Student.id == student_id)
    )
    updated_student = result.scalar_one()

    logger.info(f"Student {student_id} fully updated by user {current_user.id}")

    return map_student_to_response(updated_student)


@studentRouter.delete("/{student_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_student(
    student_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Delete a student. Only presidents and supervisors can delete students."""

    result = await db.execute(
        select(Student).where(Student.id == student_id)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )

    profile_image = student.profile_image
    # Delete the student (will cascade to user due to relationship)
    await db.delete(student)
    await db.commit()
    await run_in_threadpool(remove_student_profile_image, profile_image)

    logger.info(f"Student {student_id} deleted by user {current_user.id}")

    return None


# ==================== ACHIEVEMENT OPERATIONS ====================

@studentRouter.get("/achievements/daily", response_model=AchievementList)
async def get_daily_lecture_achievements(
    date: str,
    lecture_id: int | None = None,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
):
    """Fetch one lecture's achievements for a date within the caller's school."""
    president_id = await get_president_id_for_user(current_user, db, school_id)
    query = (
        select(Achievement)
        .join(Student, Achievement.student_id == Student.id)
        .where(Student.president_id == president_id, Achievement.date == date)
    )
    if lecture_id is not None:
        query = query.join(
            SessionParticipation,
            SessionParticipation.student_id == Student.id,
        ).where(SessionParticipation.lecture_id == lecture_id).distinct()

    result = await db.execute(query.order_by(Achievement.created_at.desc()))
    achievements = result.scalars().unique().all()
    return AchievementList(achievements=achievements, total=len(achievements))


@studentRouter.post("/achievements/bulk", response_model=AchievementList, status_code=status.HTTP_201_CREATED)
async def add_achievements_bulk(
    achievement_data: AchievementBulkCreate,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
):
    """Create the same dated achievement for multiple students atomically."""
    student_ids = achievement_data.student_ids
    if len(student_ids) != len(set(student_ids)):
        raise HTTPException(status_code=400, detail="Duplicate student IDs are not allowed")

    president_id = await get_president_id_for_user(current_user, db, school_id)
    student_result = await db.execute(
        select(Student).where(Student.id.in_(student_ids), Student.president_id == president_id)
    )
    students = student_result.scalars().all()
    if len(students) != len(student_ids):
        raise HTTPException(status_code=404, detail="One or more students were not found in this school")

    if achievement_data.lecture_id is not None:
        member_result = await db.execute(
            select(SessionParticipation.student_id)
            .join(Student, Student.id == SessionParticipation.student_id)
            .where(
                SessionParticipation.student_id.in_(student_ids),
                SessionParticipation.lecture_id == achievement_data.lecture_id,
                Student.president_id == president_id,
            )
            .distinct()
        )
        lecture_student_ids = set(member_result.scalars().all())
        if lecture_student_ids != set(student_ids):
            raise HTTPException(status_code=400, detail="All selected students must belong to the selected lecture")

    values = achievement_data.model_dump(exclude={"student_ids", "lecture_id"})
    records = [
        Achievement(student_id=student_id, president_id=president_id, **values)
        for student_id in student_ids
    ]
    db.add_all(records)
    await db.flush()
    record_ids = [record.id for record in records]
    await db.commit()
    saved_result = await db.execute(
        select(Achievement).where(Achievement.id.in_(record_ids)).order_by(Achievement.id)
    )
    saved_records = saved_result.scalars().all()
    return AchievementList(achievements=saved_records, total=len(saved_records))

@studentRouter.post("/{student_id}/achievements", response_model=AchievementResponse, status_code=status.HTTP_201_CREATED)
async def add_achievement(
    student_id: int,
    achievement_data: AchievementCreate,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
):
    """Add an achievement/progress record for a student."""

    student = await _get_accessible_student(student_id, current_user, db, school_id)

    # Validate achievement data belongs to the correct student
    if achievement_data.student_id != student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student ID in URL must match student_id in request body"
        )

    # Get president_id from current user (works for both presidents and supervisors)
    president_id = student.president_id
    
    # Create achievement record
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

    logger.info(f"Achievement added for student {student_id} by user {current_user.id}")

    return new_achievement


@studentRouter.get("/{student_id}/achievements", response_model=AchievementList)
async def get_student_achievements(
    student_id: int,
    skip: int = 0,
    limit: int = 100,
    date: str = None,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access)
):
    """Get all achievements for a specific student, optionally filtered by date."""

    await _get_accessible_student(student_id, current_user, db, school_id)

    # Build query with optional date filter
    query = select(Achievement).where(Achievement.student_id == student_id)
    
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

    # Get total count with same filter
    count_query = select(Achievement.id).where(Achievement.student_id == student_id)
    if date:
        count_query = count_query.where(Achievement.date == date)
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().all())

    return AchievementList(achievements=list(achievements), total=total)


@studentRouter.put("/{student_id}/achievements/{achievement_id}", response_model=AchievementResponse)
async def update_achievement(
    student_id: int,
    achievement_id: int,
    achievement_data: AchievementUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
    school_id: int | None = None,
):
    """Update an achievement record."""

    await _get_accessible_student(student_id, current_user, db, school_id)
    result = await db.execute(
        select(Achievement).where(
            Achievement.id == achievement_id,
            Achievement.student_id == student_id
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

    logger.info(f"Achievement {achievement_id} updated by user {current_user.id}")

    return achievement


@studentRouter.delete("/{student_id}/achievements/{achievement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_achievement(
    student_id: int,
    achievement_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
    school_id: int | None = None,
):
    """Delete an achievement record."""

    await _get_accessible_student(student_id, current_user, db, school_id)
    result = await db.execute(
        select(Achievement).where(
            Achievement.id == achievement_id,
            Achievement.student_id == student_id
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

    logger.info(f"Achievement {achievement_id} deleted by user {current_user.id}")

    return None



# ==================== ATTENDANCE OPERATIONS ====================

@studentRouter.get("/attendance/lectures/{lecture_id}/daily", response_model=AttendanceList)
async def get_lecture_daily_attendance(
    lecture_id: int,
    date: date,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    lecture_result = await db.execute(
        select(Lecture.id).where(Lecture.id == lecture_id, Lecture.president_id == president_id)
    )
    if lecture_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Lecture not found")

    result = await db.execute(
        select(Attendance)
        .join(Student, Attendance.student_id == Student.id)
        .where(
            Attendance.lecture_id == lecture_id,
            Attendance.date == date,
            Attendance.president_id == president_id,
            Student.president_id == president_id,
        )
        .order_by(Attendance.student_id)
    )
    records = result.scalars().all()
    return AttendanceList(attendances=records, total=len(records))


@studentRouter.put("/attendance/lectures/{lecture_id}/daily", response_model=AttendanceList)
async def save_lecture_daily_attendance(
    lecture_id: int,
    payload: AttendanceBulkSave,
    school_id: int | None = None,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_school_management_access),
):
    president_id = await get_president_id_for_user(current_user, db, school_id)
    student_ids = [record.student_id for record in payload.records]
    if len(student_ids) != len(set(student_ids)):
        raise HTTPException(status_code=400, detail="Duplicate student IDs are not allowed")

    lecture_result = await db.execute(
        select(Lecture.id).where(Lecture.id == lecture_id, Lecture.president_id == president_id)
    )
    if lecture_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Lecture not found")

    if student_ids:
        enrolled_result = await db.execute(
            select(SessionParticipation.student_id)
            .join(Student, Student.id == SessionParticipation.student_id)
            .where(
                SessionParticipation.lecture_id == lecture_id,
                SessionParticipation.student_id.in_(student_ids),
                Student.president_id == president_id,
            )
            .distinct()
        )
        enrolled_ids = set(enrolled_result.scalars().all())
        if enrolled_ids != set(student_ids):
            raise HTTPException(status_code=400, detail="One or more students are not enrolled in this lecture")

    existing_result = await db.execute(
        select(Attendance).where(
            Attendance.lecture_id == lecture_id,
            Attendance.date == payload.date,
            Attendance.president_id == president_id,
        )
    )
    existing_by_student = {record.student_id: record for record in existing_result.scalars().all()}
    for entry in payload.records:
        existing = existing_by_student.get(entry.student_id)
        if entry.status is None:
            if existing:
                await db.delete(existing)
            continue
        if existing:
            existing.status = entry.status
            existing.notes = entry.notes
        else:
            db.add(Attendance(
                student_id=entry.student_id,
                lecture_id=lecture_id,
                president_id=president_id,
                date=payload.date,
                status=entry.status,
                notes=entry.notes,
            ))

    await db.commit()
    saved_result = await db.execute(
        select(Attendance).where(
            Attendance.lecture_id == lecture_id,
            Attendance.date == payload.date,
            Attendance.president_id == president_id,
        ).order_by(Attendance.student_id)
    )
    saved = saved_result.scalars().all()
    return AttendanceList(attendances=saved, total=len(saved))

@studentRouter.post("/{student_id}/attendance", response_model=AttendanceResponse, status_code=status.HTTP_201_CREATED)
async def create_attendance(
    student_id: int,
    attendance_data: AttendanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher_or_above),
    school_id: int = None
):
    """Create or update attendance record for a student on a specific date."""

    # Get president_id for multi-tenancy (handles admin case with school_id)
    president_id = await get_president_id_for_user(current_user, db, school_id)

    # Verify student exists and belongs to the same president
    result = await db.execute(
        select(Student).where(
            Student.id == student_id,
            Student.president_id == president_id
        )
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found or not accessible"
        )

    enrollment_result = await db.execute(
        select(SessionParticipation.id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .where(
            SessionParticipation.student_id == student_id,
            SessionParticipation.lecture_id == attendance_data.lecture_id,
            Lecture.president_id == president_id,
        ).limit(1)
    )
    if enrollment_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=400, detail="Student is not enrolled in this lecture")
    await _ensure_teacher_owns_lecture(current_user, attendance_data.lecture_id, db)

    # Validate attendance data belongs to the correct student (if student_id provided)
    if attendance_data.student_id is not None and attendance_data.student_id != student_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Student ID in URL must match student_id in request body"
        )

    # Check if attendance already exists for this student and date
    existing_result = await db.execute(
        select(Attendance).where(
            Attendance.student_id == student_id,
            Attendance.lecture_id == attendance_data.lecture_id,
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
        logger.info(f"Attendance updated for student {student_id} on {attendance_data.date} by user {current_user.id}")
        return existing_attendance

    # Create new attendance record with president_id
    new_attendance = Attendance(
        student_id=student_id,
        lecture_id=attendance_data.lecture_id,
        president_id=president_id,
        date=attendance_data.date,
        status=attendance_data.status,
        notes=attendance_data.notes
    )

    db.add(new_attendance)
    await db.commit()
    await db.refresh(new_attendance)

    logger.info(f"Attendance created for student {student_id} on {attendance_data.date} by user {current_user.id}")

    return new_attendance


@studentRouter.get("/{student_id}/attendance", response_model=AttendanceList)
async def get_student_attendance(
    student_id: int,
    lecture_id: int,
    date: date | None = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
    school_id: int = None
):
    """Get attendance records for a specific student. Optionally filter by date."""

    # Get president_id for multi-tenancy (handles admin case with school_id)
    president_id = await get_president_id_for_user(current_user, db, school_id)

    # Verify student exists and belongs to the same president
    result = await db.execute(
        select(Student).where(
            Student.id == student_id,
            Student.president_id == president_id
        )
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found or not accessible"
        )

    await _ensure_teacher_owns_lecture(current_user, lecture_id, db)
    enrollment_result = await db.execute(
        select(SessionParticipation.id)
        .join(Lecture, SessionParticipation.lecture_id == Lecture.id)
        .where(
            SessionParticipation.student_id == student_id,
            SessionParticipation.lecture_id == lecture_id,
            Lecture.president_id == president_id,
        )
        .limit(1)
    )
    if enrollment_result.scalar_one_or_none() is None:
        raise HTTPException(status_code=404, detail="Student is not enrolled in this lecture")

    # Build query with president_id filter for multi-tenancy
    query = select(Attendance).where(
        Attendance.student_id == student_id,
        Attendance.president_id == president_id,
        Attendance.lecture_id == lecture_id,
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
        Attendance.president_id == president_id,
        Attendance.lecture_id == lecture_id,
    )
    if date:
        count_query = count_query.where(Attendance.date == date)
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().all())

    return AttendanceList(attendances=list(attendances), total=total)


@studentRouter.put("/{student_id}/attendance/{attendance_id}", response_model=AttendanceResponse)
async def update_attendance(
    student_id: int,
    attendance_id: int,
    attendance_data: AttendanceUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher_or_above),
    school_id: int = None
):
    """Update an attendance record."""

    # Get president_id for multi-tenancy
    president_id = await get_president_id_for_user(current_user, db, school_id)

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

    await _ensure_teacher_owns_lecture(current_user, attendance.lecture_id, db)

    # Update fields
    update_data = attendance_data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(attendance, field, value)

    await db.commit()
    await db.refresh(attendance)

    logger.info(f"Attendance {attendance_id} updated by user {current_user.id}")

    return attendance


@studentRouter.delete("/{student_id}/attendance/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_attendance(
    student_id: int,
    attendance_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_teacher_or_above),
    school_id: int = None
):
    """Delete an attendance record."""

    # Get president_id for multi-tenancy
    president_id = await get_president_id_for_user(current_user, db, school_id)

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

    await _ensure_teacher_owns_lecture(current_user, attendance.lecture_id, db)

    await db.delete(attendance)
    await db.commit()

    logger.info(f"Attendance {attendance_id} deleted by user {current_user.id}")

    return None
