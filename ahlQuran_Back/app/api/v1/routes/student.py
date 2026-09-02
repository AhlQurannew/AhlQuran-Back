from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from typing import Optional
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.student import Student
from app.models.acheivements import Achievement
from app.models.attendance import Attendance
from app.models.lecture import Lecture
from app.models.session import Session
from app.models.sessionParticipation import SessionParticipation
from app.schemas.student import (
    StudentCreate, StudentUpdate, StudentResponse, StudentList,
    PersonalInfo, AccountInfo, ContactInfo, GuardianInfo, 
    LectureInfo, FormalEducationInfo, MedicalInfo, SubscriptionInfo
)
from app.schemas.achievement import AchievementCreate, AchievementUpdate, AchievementResponse, AchievementList
from app.schemas.attendance import AttendanceCreate, AttendanceUpdate, AttendanceResponse, AttendanceList
from app.schemas.student_full import StudentCreateFull
from app.core.dependencies import get_current_user, require_president_or_supervisor
from app.core.multi_tenancy import get_president_id_for_user
from app.core.security import get_password_hash

import logging
logger = logging.getLogger(__name__)

studentRouter = APIRouter()


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


@studentRouter.post("/", response_model=StudentResponse, status_code=status.HTTP_201_CREATED)
async def create_student(
    student_data: StudentCreateFull,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)
    
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
    parent_name = f"{student_data.guardian.first_name or ''} {student_data.guardian.last_name or ''}".strip()
    
    new_student = Student(
        user_id=new_user.id,
        parent_name=parent_name if parent_name else None,
        parent_phone=student_data.contactInfo.phone_number,
        guardian_email=student_data.guardian.email,
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
        
        guardian_id=student_data.guardian.guardian_id
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


@studentRouter.get("/", response_model=StudentList)
async def list_students(
    skip: int = 0,
    limit: int = 100,
    lecture_id: int = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Get all students. Optionally filter by lecture_id. Only presidents and supervisors can view all students."""

    # Get president ID for filtering (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)

    # Build query with president_id filter and optional lecture filter
    query = select(Student).options(
        selectinload(Student.user),
        selectinload(Student.participations).selectinload(SessionParticipation.lecture)
    ).where(Student.president_id == president_id)
    
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
    
    # Get existing student with all relationships
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
    parent_name = f"{student_data.guardian.first_name or ''} {student_data.guardian.last_name or ''}".strip()
    student.parent_name = parent_name if parent_name else None
    student.guardian_email = student_data.guardian.email
    student.guardian_id = student_data.guardian.guardian_id

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

    # Delete the student (will cascade to user due to relationship)
    await db.delete(student)
    await db.commit()

    logger.info(f"Student {student_id} deleted by user {current_user.id}")

    return None


# ==================== ACHIEVEMENT OPERATIONS ====================

# ============================================================
# ACHIEVEMENT OPERATIONS
# ============================================================


@studentRouter.post(
    "/{student_id}/achievements",
    response_model=AchievementResponse,
    status_code=status.HTTP_201_CREATED,
)
async def add_achievement(
    student_id: int,
    achievement_data: AchievementCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_president_or_supervisor
    ),
):
    """
    Add a Quran memorization achievement
    for a student and associate it with a lecture.
    """

    # ========================================================
    # 1. Get president ID
    # ========================================================

    president_id = await get_president_id_for_user(
        current_user,
        db,
    )


    # ========================================================
    # 2. Verify student
    # ========================================================

    result = await db.execute(
        select(Student).where(
            Student.id == student_id,
            Student.president_id == president_id,
        )
    )

    student = result.scalar_one_or_none()


    if not student:

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Student with ID "
                f"{student_id} not found"
            ),
        )


    # ========================================================
    # 3. Make sure body student_id matches URL
    # ========================================================

    if (
        achievement_data.student_id
        != student_id
    ):

        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=(
                "Student ID in URL must match "
                "student_id in request body"
            ),
        )


    # ========================================================
    # 4. Verify lecture
    # ========================================================

    lecture_result = await db.execute(
        select(Lecture).where(
            Lecture.id ==
            achievement_data.lecture_id,

            Lecture.president_id ==
            president_id,
        )
    )

    lecture = (
        lecture_result
        .scalar_one_or_none()
    )


    if not lecture:

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Lecture with ID "
                f"{achievement_data.lecture_id} "
                f"not found"
            ),
        )


    # ========================================================
    # 5. Create achievement
    # ========================================================

    new_achievement = Achievement(

        student_id=
            student_id,

        # ⭐⭐⭐ IMPORTANT ⭐⭐⭐
        # This is what stores the selected
        # lecture/halqa in PostgreSQL.

        lecture_id=
            achievement_data.lecture_id,

        president_id=
            president_id,

        from_surah=
            achievement_data.from_surah,

        to_surah=
            achievement_data.to_surah,

        from_verse=
            achievement_data.from_verse,

        to_verse=
            achievement_data.to_verse,

        note=
            achievement_data.note,

        achievement_type=
            achievement_data.achievement_type,

        date=
            achievement_data.date,
    )


    # ========================================================
    # 6. Save
    # ========================================================

    db.add(
        new_achievement
    )

    await db.commit()

    await db.refresh(
        new_achievement
    )


    logger.info(
        "Achievement added: "
        f"id={new_achievement.id}, "
        f"student_id={student_id}, "
        f"lecture_id={achievement_data.lecture_id}, "
        f"user_id={current_user.id}"
    )


    return new_achievement

@studentRouter.get(
    "/{student_id}/achievements",
    response_model=AchievementList,
)
async def get_student_achievements(
    student_id: int,
    skip: int = 0,
    limit: int = 100,
    date: Optional[str] = None,
    lecture_id: Optional[int] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        get_current_user
    ),
):
    """
    Get achievements for a student.

    Optional filters:
    - date
    - lecture_id
    """

    # ========================================================
    # 1. President
    # ========================================================

    president_id = await get_president_id_for_user(
        current_user,
        db,
    )


    # ========================================================
    # 2. Verify student
    # ========================================================

    result = await db.execute(
        select(Student).where(
            Student.id == student_id,
            Student.president_id == president_id,
        )
    )

    student = result.scalar_one_or_none()


    if not student:

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Student with ID "
                f"{student_id} not found"
            ),
        )


    # ========================================================
    # 3. Build query
    # ========================================================

    query = select(Achievement).where(

        Achievement.student_id
        == student_id,

        Achievement.president_id
        == president_id,
    )


    # ========================================================
    # 4. Date filter
    # ========================================================

    if date:

        query = query.where(
            Achievement.date == date
        )


    # ========================================================
    # 5. Lecture filter
    # ========================================================

    if lecture_id is not None:

        query = query.where(
            Achievement.lecture_id
            == lecture_id
        )


    # ========================================================
    # 6. Get achievements
    # ========================================================

    achievements_result = await db.execute(

        query
        .order_by(
            Achievement.created_at.desc()
        )
        .offset(skip)
        .limit(limit)
    )


    achievements = (
        achievements_result
        .scalars()
        .all()
    )


    # ========================================================
    # 7. Count
    # ========================================================

    count_query = select(
        Achievement
    ).where(

        Achievement.student_id
        == student_id,

        Achievement.president_id
        == president_id,
    )


    if date:

        count_query = count_query.where(
            Achievement.date == date
        )


    if lecture_id is not None:

        count_query = count_query.where(
            Achievement.lecture_id
            == lecture_id
        )


    count_result = await db.execute(
        count_query
    )


    total = len(
        count_result
        .scalars()
        .all()
    )


    return AchievementList(
        achievements=
            list(achievements),

        total=
            total,
    )

@studentRouter.put(
    "/{student_id}/achievements/{achievement_id}",
    response_model=AchievementResponse,
)
async def update_achievement(
    student_id: int,
    achievement_id: int,
    achievement_data: AchievementUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(
        require_president_or_supervisor
    ),
):
    """
    Update an achievement.

    The lecture can also be changed.
    """

    # ========================================================
    # 1. President
    # ========================================================

    president_id = await get_president_id_for_user(
        current_user,
        db,
    )


    # ========================================================
    # 2. Find achievement
    # ========================================================

    result = await db.execute(
        select(Achievement).where(

            Achievement.id
            == achievement_id,

            Achievement.student_id
            == student_id,

            Achievement.president_id
            == president_id,
        )
    )

    achievement = (
        result
        .scalar_one_or_none()
    )


    if not achievement:

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=(
                f"Achievement with ID "
                f"{achievement_id} not found"
            ),
        )


    # ========================================================
    # 3. If lecture_id is being changed,
    #    verify that lecture exists
    # ========================================================

    if (
        achievement_data.lecture_id
        is not None
    ):

        lecture_result = await db.execute(
            select(Lecture).where(

                Lecture.id
                == achievement_data.lecture_id,

                Lecture.president_id
                == president_id,
            )
        )

        lecture = (
            lecture_result
            .scalar_one_or_none()
        )


        if not lecture:

            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=(
                    f"Lecture with ID "
                    f"{achievement_data.lecture_id} "
                    f"not found"
                ),
            )


    # ========================================================
    # 4. Update fields
    # ========================================================

    update_data = (
        achievement_data
        .model_dump(
            exclude_unset=True
        )
    )


    for field, value in update_data.items():

        setattr(
            achievement,
            field,
            value,
        )


    # ========================================================
    # 5. Save
    # ========================================================

    await db.commit()

    await db.refresh(
        achievement
    )


    logger.info(
        "Achievement updated: "
        f"id={achievement_id}, "
        f"lecture_id={achievement.lecture_id}, "
        f"user_id={current_user.id}"
    )


    return achievement

@studentRouter.delete("/{student_id}/achievements/{achievement_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_achievement(
    student_id: int,
    achievement_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Delete an achievement record."""

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

@studentRouter.post("/{student_id}/attendance", response_model=AttendanceResponse, status_code=status.HTTP_201_CREATED)
async def create_attendance(
    student_id: int,
    attendance_data: AttendanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Create or update attendance record for a student on a specific date."""

    # Get president_id for multi-tenancy
    president_id = await get_president_id_for_user(current_user, db)

    # Verify student exists
    result = await db.execute(
        select(Student).where(Student.id == student_id)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
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
        logger.info(f"Attendance updated for student {student_id} on {attendance_data.date} by user {current_user.id}")
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

    logger.info(f"Attendance created for student {student_id} on {attendance_data.date} by user {current_user.id}")

    return new_attendance


@studentRouter.get("/{student_id}/attendance", response_model=AttendanceList)
async def get_student_attendance(
    student_id: int,
    date: str = None,
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Get attendance records for a specific student. Optionally filter by date."""

    # Verify student exists
    result = await db.execute(
        select(Student).where(Student.id == student_id)
    )
    student = result.scalar_one_or_none()

    if not student:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )

    # Build query
    query = select(Attendance).where(Attendance.student_id == student_id)
    
    # Filter by date if provided
    if date:
        query = query.where(Attendance.date == date)
    
    query = query.order_by(Attendance.created_at.desc()).offset(skip).limit(limit)

    # Get attendance records
    attendance_result = await db.execute(query)
    attendances = attendance_result.scalars().all()

    # Get total count
    count_query = select(Attendance).where(Attendance.student_id == student_id)
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
    current_user: User = Depends(require_president_or_supervisor)
):
    """Update an attendance record."""

    result = await db.execute(
        select(Attendance).where(
            Attendance.id == attendance_id,
            Attendance.student_id == student_id
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

    logger.info(f"Attendance {attendance_id} updated by user {current_user.id}")

    return attendance


@studentRouter.delete("/{student_id}/attendance/{attendance_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_attendance(
    student_id: int,
    attendance_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Delete an attendance record."""

    result = await db.execute(
        select(Attendance).where(
            Attendance.id == attendance_id,
            Attendance.student_id == student_id
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

    logger.info(f"Attendance {attendance_id} deleted by user {current_user.id}")

    return None
