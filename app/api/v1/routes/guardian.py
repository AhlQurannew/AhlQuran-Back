from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy import or_
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.sessionParticipation import SessionParticipation
from app.models.acheivements import Achievement
from app.models.attendance import Attendance
from app.schemas.student import StudentResponse, StudentList
from app.schemas.guardian import (
    GuardianResponse, GuardianCreate, GuardianUpdate, GuardianList,
    GuardianStudentOptions,
)
from app.schemas.guardian_student_data import (
    PaginatedAchievementsResponse,
    GuardianAchievementResponse,
    PaginatedAttendanceResponse,
    GuardianAttendanceResponse,
    StudentContext
)
from app.core.dependencies import require_guardian, require_president_or_supervisor
from app.core.security import get_password_hash
from app.core.multi_tenancy import get_president_id_for_user
from typing import Tuple, List, Optional
from datetime import date, datetime
from fastapi import Query
import logging
import math

logger = logging.getLogger(__name__)

guardianRouter = APIRouter()


def _guardian_student_ids(data: GuardianCreate | GuardianUpdate) -> list[int]:
    ids = data.student_ids or ([data.student_id] if data.student_id is not None else [])
    if len(ids) != len(set(ids)):
        raise HTTPException(status_code=422, detail="Student IDs must be unique")
    return ids


async def _get_linkable_students(
    db: AsyncSession,
    student_ids: list[int],
    president_id: int,
    guardian_id: int | None = None,
) -> list[Student]:
    if not student_ids:
        return []

    result = await db.execute(
        select(Student)
        .where(
            Student.id.in_(student_ids),
            Student.president_id == president_id,
            or_(Student.guardian_id.is_(None), Student.guardian_id == guardian_id)
            if guardian_id is not None else Student.guardian_id.is_(None),
        )
        .order_by(Student.id)
        .with_for_update()
    )
    students = result.scalars().all()
    if len(students) != len(student_ids):
        raise HTTPException(
            status_code=409,
            detail="One or more selected students are unavailable, outside your organization, or linked to another guardian",
        )
    return students


def _guardian_response(guardian: Guardian) -> GuardianResponse:
    students = sorted(guardian.students, key=lambda student: (student.user.firstname.casefold(), student.user.lastname.casefold()))
    return GuardianResponse(
        id=guardian.id,
        user_id=guardian.user_id,
        first_name=guardian.first_name,
        last_name=guardian.last_name,
        email=guardian.email,
        phone_number=guardian.phone_number,
        date_of_birth=guardian.date_of_birth,
        relationship_to_student=guardian.relationship_to_student,
        address=guardian.address,
        job=guardian.job,
        username=guardian.user.email if guardian.user else None,
        student_id=students[0].id if students else None,
        student_ids=[student.id for student in students],
        students=[
            {"id": student.id, "first_name": student.user.firstname, "last_name": student.user.lastname,
             "username": student.user.email}
            for student in students
        ],
        is_active=guardian.user.is_active if guardian.user else False,
    )


# ==================== AUTHORIZATION HELPERS ====================


async def verify_guardian_student_access(
    db: AsyncSession,
    guardian_user_id: int,
    student_id: int,
    president_id: int
) -> bool:
    """
    Verify that a guardian has access to a student's data.
    
    This function checks:
    1. Student.guardian_id points to the guardian record
    2. Both guardian and student belong to the same president_id (multi-tenancy)
    
    Args:
        db: Database session
        guardian_user_id: The user_id of the guardian
        student_id: The student_id to verify access for
        president_id: The president_id of the guardian (for multi-tenancy)
    
    Returns:
        True if authorized
        
    Raises:
        HTTPException(403): If guardian is not authorized to access the student's data
        HTTPException(404): If student does not exist
    """
    # First, verify the student exists
    student_result = await db.execute(
        select(Student)
        .where(Student.id == student_id)
    )
    student = student_result.scalar_one_or_none()
    
    if not student:
        logger.info(f"Student {student_id} not found for guardian user {guardian_user_id}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )
    
    # Verify guardian-student link exists
    guardian_result = await db.execute(
        select(Guardian).where(Guardian.user_id == guardian_user_id)
    )
    guardian = guardian_result.scalar_one_or_none()
    if guardian is None:
        return False
    guardian_link_result = await db.execute(
        select(Student.id).where(
            Student.id == student_id,
            Student.guardian_id == guardian.id,
        )
    )
    guardian_link = guardian_link_result.scalar_one_or_none()
    
    if not guardian_link:
        logger.warning(
            f"Authorization failed: Guardian user {guardian_user_id} attempted to access "
            f"student {student_id} data without proper authorization"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this student's data"
        )
    
    # Verify multi-tenancy: both guardian and student must have matching president_id
    if student.president_id != president_id or guardian.president_id != president_id:
        logger.warning(
            f"Authorization failed: Guardian user {guardian_user_id} (president {guardian.president_id}) "
            f"attempted to access student {student_id} (president {student.president_id})"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have permission to access this student's data"
        )
    
    logger.info(f"Guardian user {guardian_user_id} authorized to access student {student_id}")
    return True


# ==================== DATABASE QUERY FUNCTIONS ====================


async def get_achievements_for_student(
    db: AsyncSession,
    student_id: int,
    president_id: int,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    skip: int = 0,
    limit: int = 50
) -> Tuple[List[Achievement], int]:
    """
    Query achievements for a student with optional date range filtering and pagination.
    
    Args:
        db: Database session
        student_id: The student's ID
        president_id: The president_id for multi-tenancy filtering
        start_date: Optional start date filter (DD-MM-YYYY format)
        end_date: Optional end date filter (DD-MM-YYYY format)
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return
    
    Returns:
        Tuple of (achievement_records, total_count)
        
    Raises:
        HTTPException(500): If database error occurs
    """
    try:
        # Build base query with student_id and president_id filters
        query = (
            select(Achievement)
            .join(Student, Achievement.student_id == Student.id)
            .where(Achievement.student_id == student_id)
            .where(Achievement.president_id == president_id)
            .options(selectinload(Achievement.student).selectinload(Student.user))
        )
        
        # Add date range filtering if provided
        if start_date:
            # Convert DD-MM-YYYY to comparable format for filtering
            # Since dates are stored as strings in DD-MM-YYYY format, we need to compare them properly
            query = query.where(Achievement.date >= start_date)
        
        if end_date:
            query = query.where(Achievement.date <= end_date)
        
        # Order by date descending (most recent first)
        query = query.order_by(Achievement.date.desc())
        
        # Execute count query for total records (before pagination)
        count_query = select(func.count()).select_from(Achievement).where(
            Achievement.student_id == student_id,
            Achievement.president_id == president_id
        )
        
        if start_date:
            count_query = count_query.where(Achievement.date >= start_date)
        
        if end_date:
            count_query = count_query.where(Achievement.date <= end_date)
        
        count_result = await db.execute(count_query)
        total_count = count_result.scalar_one()
        
        # Apply pagination
        query = query.offset(skip).limit(limit)
        
        # Execute query
        result = await db.execute(query)
        achievements = result.scalars().unique().all()
        
        return achievements, total_count
    except Exception as e:
        logger.error(
            f"Database error in get_achievements_for_student for student {student_id}: {str(e)}",
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An internal error occurred while retrieving achievements. Please try again later."
        )


async def get_attendance_for_student(
    db: AsyncSession,
    student_id: int,
    president_id: int,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    skip: int = 0,
    limit: int = 50
) -> Tuple[List[Attendance], int]:
    """
    Query attendance records for a student with optional date range filtering and pagination.
    
    Args:
        db: Database session
        student_id: The student's ID
        president_id: The president_id for multi-tenancy filtering
        start_date: Optional inclusive ISO date filter
        end_date: Optional inclusive ISO date filter
        skip: Number of records to skip (for pagination)
        limit: Maximum number of records to return
    
    Returns:
        Tuple of (attendance_records, total_count)
        
    Raises:
        HTTPException(500): If database error occurs
    """
    try:
        # Build base query with student_id and president_id filters
        query = (
            select(Attendance)
            .join(Student, Attendance.student_id == Student.id)
            .where(Attendance.student_id == student_id)
            .where(Attendance.president_id == president_id)
            .options(selectinload(Attendance.student).selectinload(Student.user))
        )
        
        # Add date range filtering if provided
        if start_date:
            query = query.where(Attendance.date >= start_date)
        
        if end_date:
            query = query.where(Attendance.date <= end_date)
        
        # Order by date descending (most recent first)
        query = query.order_by(Attendance.date.desc())
        
        # Execute count query for total records (before pagination)
        count_query = select(func.count()).select_from(Attendance).where(
            Attendance.student_id == student_id,
            Attendance.president_id == president_id
        )
        
        if start_date:
            count_query = count_query.where(Attendance.date >= start_date)
        
        if end_date:
            count_query = count_query.where(Attendance.date <= end_date)
        
        count_result = await db.execute(count_query)
        total_count = count_result.scalar_one()
        
        # Apply pagination
        query = query.offset(skip).limit(limit)
        
        # Execute query
        result = await db.execute(query)
        attendance_records = result.scalars().unique().all()
        
        return attendance_records, total_count
    except Exception as e:
        logger.error(
            f"Database error in get_attendance_for_student for student {student_id}: {str(e)}",
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An internal error occurred while retrieving attendance records. Please try again later."
        )


# ==================== GUARDIAN DATA ACCESS (READ-ONLY) ====================
# Guardians can view their children's information but cannot modify any data


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


@guardianRouter.get("/my-children", response_model=StudentList)
async def get_my_children(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_guardian)
):
    """
    Get all students (children) linked to the current guardian.
    This is a READ-ONLY endpoint - guardians cannot modify student data.
    """
    
    # Get the guardian record for the current user
    guardian_result = await db.execute(
        select(Guardian)
        .where(Guardian.user_id == current_user.id)
    )
    guardian = guardian_result.scalar_one_or_none()
    
    if not guardian:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Guardian record not found for current user"
        )
    
    logger.info(f"Guardian {guardian.id} requesting children list")
    
    # Each student references their guardian, allowing one guardian to have many children.
    query = (
        select(Student)
        .where(Student.guardian_id == guardian.id)
        .where(Student.president_id == guardian.president_id)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
        .distinct()
    )
    
    # Get total count with same filters (before pagination)
    count_query = (
        select(Student)
        .where(Student.guardian_id == guardian.id)
        .where(Student.president_id == guardian.president_id)
        .distinct()
    )
    
    count_result = await db.execute(count_query)
    total = len(count_result.scalars().unique().all())
    
    # Apply pagination
    query = query.offset(skip).limit(limit)
    
    # Execute query
    result = await db.execute(query)
    students = result.scalars().unique().all()
    
    logger.info(f"Guardian {guardian.id} found {len(students)} children (total: {total})")
    
    # Map students to response format
    student_responses = [map_student_to_response(student) for student in students]
    
    return StudentList(students=student_responses, total=total)


@guardianRouter.get("/my-children/{student_id}", response_model=StudentResponse)
async def get_my_child_detail(
    student_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_guardian)
):
    """
    Get detailed information about a specific child linked to the current guardian.
    This is a READ-ONLY endpoint - guardians cannot modify student data.
    
    Authorization checks:
    - Student must be linked to the guardian via student_id
    - Student must belong to the same president_id as the guardian
    """
    
    # Get the guardian record for the current user
    guardian_result = await db.execute(
        select(Guardian)
        .where(Guardian.user_id == current_user.id)
    )
    guardian = guardian_result.scalar_one_or_none()
    
    if not guardian:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Guardian record not found for current user"
        )
    
    logger.info(f"Guardian {guardian.id} requesting details for student {student_id}")
    
    # Query Student table by student_id with all relationships loaded
    student_result = await db.execute(
        select(Student)
        .where(Student.id == student_id)
        .options(
            selectinload(Student.user),
            selectinload(Student.participations).selectinload(SessionParticipation.lecture)
        )
    )
    student = student_result.scalar_one_or_none()
    
    # Return 404 if student not found
    if not student:
        logger.warning(f"Student {student_id} not found")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Student with ID {student_id} not found"
        )
    
    # Verify student is linked to guardian (check student_id matches)
    # Check if there's a Guardian record linking this user to this student
    guardian_link = student.guardian_id == guardian.id
    
    # Return 403 if student not linked to guardian
    if not guardian_link:
        logger.warning(f"Guardian {guardian.id} attempted to access unlinked student {student_id}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You do not have access to this student's information"
        )
    
    # Verify student belongs to same president_id
    # Return 403 if different president
    if student.president_id != guardian.president_id:
        logger.warning(
            f"Guardian {guardian.id} (president {guardian.president_id}) "
            f"attempted to access student {student_id} (president {student.president_id})"
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied"
        )
    
    logger.info(f"Guardian {guardian.id} authorized to view student {student_id}")
    
    # Map student to StudentResponse format
    return map_student_to_response(student)


@guardianRouter.get("/students/{student_id}/achievements", response_model=PaginatedAchievementsResponse)
async def get_student_achievements(
    student_id: int,
    start_date: Optional[str] = Query(None, description="Start date filter in DD-MM-YYYY format"),
    end_date: Optional[str] = Query(None, description="End date filter in DD-MM-YYYY format"),
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of items per page"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_guardian)
) -> PaginatedAchievementsResponse:
    """
    Retrieve achievements for a student linked to the authenticated guardian.
    
    This is a READ-ONLY endpoint that allows guardians to view their children's
    Quran memorization achievements. Supports date range filtering and pagination.
    
    Authorization checks:
    - Guardian must be authenticated
    - Student.guardian_id must match the authenticated guardian
    - Student must belong to the same president_id as the guardian (multi-tenancy)
    
    Args:
        student_id: The ID of the student to retrieve achievements for
        start_date: Optional start date filter (DD-MM-YYYY format)
        end_date: Optional end date filter (DD-MM-YYYY format)
        page: Page number (1-indexed, default: 1)
        page_size: Number of items per page (default: 50, max: 100)
        db: Database session
        current_user: Authenticated guardian user
    
    Returns:
        PaginatedAchievementsResponse with achievement records and pagination metadata
    
    Raises:
        HTTPException(403): If guardian is not authorized to access the student's data
        HTTPException(404): If student does not exist
        HTTPException(500): If an unexpected error occurs
    """
    try:
        # Get the guardian record for the current user
        guardian_result = await db.execute(
            select(Guardian)
            .where(Guardian.user_id == current_user.id)
        )
        guardian = guardian_result.scalar_one_or_none()
        
        if not guardian:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Guardian record not found for current user"
            )
        
        logger.info(
            f"Guardian {guardian.id} requesting achievements for student {student_id} "
            f"(page={page}, page_size={page_size}, start_date={start_date}, end_date={end_date})"
        )
        
        # Verify guardian has access to this student's data
        # This will raise HTTPException(403) if unauthorized or HTTPException(404) if student not found
        await verify_guardian_student_access(
            db=db,
            guardian_user_id=current_user.id,
            student_id=student_id,
            president_id=guardian.president_id
        )
        
        # Calculate offset from page and page_size
        offset = (page - 1) * page_size
        
        # Query achievements with filters and pagination
        achievements, total_count = await get_achievements_for_student(
            db=db,
            student_id=student_id,
            president_id=guardian.president_id,
            start_date=start_date,
            end_date=end_date,
            skip=offset,
            limit=page_size
        )
        
        # Get student information for context
        student_result = await db.execute(
            select(Student)
            .where(Student.id == student_id)
            .options(selectinload(Student.user))
        )
        student = student_result.scalar_one()
        
        # Build student context
        student_context = StudentContext(
            id=student.id,
            name=f"{student.user.firstname} {student.user.lastname}"
        )
        
        # Build achievement responses with student context
        achievement_responses = []
        for achievement in achievements:
            achievement_responses.append(
                GuardianAchievementResponse(
                    id=achievement.id,
                    student=student_context,
                    from_surah=achievement.from_surah,
                    to_surah=achievement.to_surah,
                    from_verse=achievement.from_verse,
                    to_verse=achievement.to_verse,
                    note=achievement.note,
                    achievement_type=achievement.achievement_type.value,
                    date=achievement.date
                )
            )
        
        # Calculate total pages
        total_pages = math.ceil(total_count / page_size) if total_count > 0 else 0
        
        logger.info(
            f"Guardian {guardian.id} retrieved {len(achievement_responses)} achievements "
            f"for student {student_id} (total: {total_count}, page {page}/{total_pages})"
        )
        
        # Build and return paginated response
        return PaginatedAchievementsResponse(
            items=achievement_responses,
            total=total_count,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
    except HTTPException:
        # Re-raise HTTP exceptions (403, 404) as-is
        raise
    except Exception as e:
        logger.error(
            f"Unexpected error in get_student_achievements for student {student_id}: {str(e)}",
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An internal error occurred while retrieving achievements. Please try again later."
        )


@guardianRouter.get("/students/{student_id}/attendance", response_model=PaginatedAttendanceResponse)
async def get_student_attendance(
    student_id: int,
    start_date: Optional[date] = Query(None, description="Inclusive ISO start date"),
    end_date: Optional[date] = Query(None, description="Inclusive ISO end date"),
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=100, description="Number of items per page"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_guardian)
) -> PaginatedAttendanceResponse:
    """
    Retrieve attendance records for a student linked to the authenticated guardian.
    
    This is a READ-ONLY endpoint that allows guardians to view their children's
    class attendance records. Supports date range filtering and pagination.
    
    Authorization checks:
    - Guardian must be authenticated
    - Student.guardian_id must match the authenticated guardian
    - Student must belong to the same president_id as the guardian (multi-tenancy)
    
    Args:
        student_id: The ID of the student to retrieve attendance for
        start_date: Optional inclusive ISO date filter
        end_date: Optional inclusive ISO date filter
        page: Page number (1-indexed, default: 1)
        page_size: Number of items per page (default: 50, max: 100)
        db: Database session
        current_user: Authenticated guardian user
    
    Returns:
        PaginatedAttendanceResponse with attendance records and pagination metadata
    
    Raises:
        HTTPException(403): If guardian is not authorized to access the student's data
        HTTPException(404): If student does not exist
        HTTPException(500): If an unexpected error occurs
    """
    try:
        # Get the guardian record for the current user
        guardian_result = await db.execute(
            select(Guardian)
            .where(Guardian.user_id == current_user.id)
        )
        guardian = guardian_result.scalar_one_or_none()
        
        if not guardian:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Guardian record not found for current user"
            )
        
        logger.info(
            f"Guardian {guardian.id} requesting attendance for student {student_id} "
            f"(page={page}, page_size={page_size}, start_date={start_date}, end_date={end_date})"
        )
        
        # Verify guardian has access to this student's data
        # This will raise HTTPException(403) if unauthorized or HTTPException(404) if student not found
        await verify_guardian_student_access(
            db=db,
            guardian_user_id=current_user.id,
            student_id=student_id,
            president_id=guardian.president_id
        )
        
        # Calculate offset from page and page_size
        offset = (page - 1) * page_size
        
        # Query attendance records with filters and pagination
        attendance_records, total_count = await get_attendance_for_student(
            db=db,
            student_id=student_id,
            president_id=guardian.president_id,
            start_date=start_date,
            end_date=end_date,
            skip=offset,
            limit=page_size
        )
        
        # Get student information for context
        student_result = await db.execute(
            select(Student)
            .where(Student.id == student_id)
            .options(selectinload(Student.user))
        )
        student = student_result.scalar_one()
        
        # Build student context
        student_context = StudentContext(
            id=student.id,
            name=f"{student.user.firstname} {student.user.lastname}"
        )
        
        # Build attendance responses with student context
        attendance_responses = []
        for attendance in attendance_records:
            attendance_responses.append(
                GuardianAttendanceResponse(
                    id=attendance.id,
                    student=student_context,
                    date=attendance.date,
                    lecture_id=attendance.lecture_id,
                    status=attendance.status.value,
                    notes=attendance.notes
                )
            )
        
        # Calculate total pages
        total_pages = math.ceil(total_count / page_size) if total_count > 0 else 0
        
        logger.info(
            f"Guardian {guardian.id} retrieved {len(attendance_responses)} attendance records "
            f"for student {student_id} (total: {total_count}, page {page}/{total_pages})"
        )
        
        # Build and return paginated response
        return PaginatedAttendanceResponse(
            items=attendance_responses,
            total=total_count,
            page=page,
            page_size=page_size,
            total_pages=total_pages
        )
    except HTTPException:
        # Re-raise HTTP exceptions (403, 404) as-is
        raise
    except Exception as e:
        logger.error(
            f"Unexpected error in get_student_attendance for student {student_id}: {str(e)}",
            exc_info=True
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An internal error occurred while retrieving attendance records. Please try again later."
        )


# ==================== ADMIN GUARDIAN MANAGEMENT ====================
# These routes require president/supervisor privileges


@guardianRouter.post("/", response_model=GuardianResponse, status_code=status.HTTP_201_CREATED)
async def create_guardian(
    guardian_data: GuardianCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """
    Create a new guardian for the current president's organization.
    Creates both a User account and Guardian profile.
    Only presidents and supervisors can create guardians.
    """
    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)
    
    # Check if email already exists
    existing_user = await db.execute(
        select(User).where(User.email == guardian_data.account_info.username)
    )
    if existing_user.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")
    
    linked_students = await _get_linkable_students(
        db, _guardian_student_ids(guardian_data), president_id
    )
    
    # Create User account
    new_user = User(
        firstname=guardian_data.guardian_info.first_name,
        lastname=guardian_data.guardian_info.last_name,
        email=guardian_data.account_info.username,
        hashed_password=get_password_hash(guardian_data.account_info.password),
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    db.add(new_user)
    await db.flush()  # Get new_user.id before creating guardian
    
    # Create Guardian profile with president_id
    new_guardian = Guardian(
        user_id=new_user.id,
        president_id=president_id,
        first_name=guardian_data.guardian_info.first_name,
        last_name=guardian_data.guardian_info.last_name,
        relationship_to_student=guardian_data.guardian_info.relationship,
        date_of_birth=guardian_data.guardian_info.date_of_birth,
        phone_number=guardian_data.guardian_info.phone_number,
        email=guardian_data.guardian_info.email,
        job=guardian_data.guardian_info.job,
        address=guardian_data.guardian_info.address,
        created_by_id=current_user.id
    )
    db.add(new_guardian)
    await db.flush()
    for student in linked_students:
        student.guardian_id = new_guardian.id
    new_guardian.user = new_user
    new_guardian.students = linked_students
    await db.commit()
    loaded = await db.execute(
        select(Guardian)
        .options(selectinload(Guardian.user), selectinload(Guardian.students).selectinload(Student.user))
        .where(Guardian.id == new_guardian.id)
    )
    new_guardian = loaded.scalar_one()
    
    logger.info(f"Guardian created: {new_guardian.id} by user {current_user.id}")
    
    return _guardian_response(new_guardian)


@guardianRouter.get("/", response_model=GuardianList)
async def list_guardians(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """
    Get all guardians for the current president's organization.
    Filters guardians by president_id for multi-tenancy.
    Only presidents and supervisors can view all guardians.
    """
    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)
    
    # Filter guardians by president_id with eager loading
    result = await db.execute(
        select(Guardian)
        .where(Guardian.president_id == president_id)
        .options(
            selectinload(Guardian.user),
            selectinload(Guardian.students).selectinload(Student.user)
        )
        .offset(skip)
        .limit(limit)
    )
    guardians = result.scalars().unique().all()
    
    # Get total count with same filter
    count_result = await db.execute(
        select(Guardian).where(Guardian.president_id == president_id)
    )
    total = len(count_result.scalars().all())
    
    # Build response list
    guardians_list = []
    for guardian in guardians:
        guardians_list.append(_guardian_response(guardian))
    
    return GuardianList(guardians=guardians_list, total=total)


@guardianRouter.get("/available-students", response_model=GuardianStudentOptions)
async def get_linkable_students(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=500),
    guardian_id: int | None = Query(None, gt=0),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor),
):
    president_id = await get_president_id_for_user(current_user, db)
    if guardian_id is not None:
        guardian_result = await db.execute(
            select(Guardian.id).where(
                Guardian.id == guardian_id,
                Guardian.president_id == president_id,
            )
        )
        if guardian_result.scalar_one_or_none() is None:
            raise HTTPException(status_code=404, detail="Guardian not found")

    eligible = or_(Student.guardian_id.is_(None), Student.guardian_id == guardian_id) if guardian_id else Student.guardian_id.is_(None)
    rows = await db.execute(
        select(Student, User)
        .join(User, User.id == Student.user_id)
        .where(Student.president_id == president_id, eligible)
        .order_by(User.firstname, User.lastname, Student.id)
        .offset(skip)
        .limit(limit)
    )
    students = rows.all()
    count = await db.scalar(
        select(func.count(Student.id)).where(Student.president_id == president_id, eligible)
    )
    return GuardianStudentOptions(
        students=[
            {"id": student.id, "first_name": user.firstname, "last_name": user.lastname, "username": user.email}
            for student, user in students
        ],
        total=count or 0,
    )


@guardianRouter.get("/{guardian_id}", response_model=GuardianResponse)
async def get_guardian(
    guardian_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """Get a specific guardian by ID."""
    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)
    
    result = await db.execute(
        select(Guardian)
        .where(Guardian.id == guardian_id, Guardian.president_id == president_id)
        .options(
            selectinload(Guardian.user),
            selectinload(Guardian.students).selectinload(Student.user),
        )
    )
    guardian = result.scalar_one_or_none()
    
    if not guardian:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Guardian with ID {guardian_id} not found"
        )
    
    return _guardian_response(guardian)


@guardianRouter.put("/{guardian_id}", response_model=GuardianResponse)
async def update_guardian(
    guardian_id: int,
    guardian_data: GuardianUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """
    Update an existing guardian.
    Only guardians belonging to the current president's organization can be updated.
    Only presidents and supervisors can update guardians.
    """
    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)
    
    # Get guardian and verify it belongs to this president
    result = await db.execute(
        select(Guardian)
        .where(Guardian.id == guardian_id, Guardian.president_id == president_id)
        .options(
            selectinload(Guardian.user),
            selectinload(Guardian.students).selectinload(Student.user),
        )
    )
    guardian = result.scalar_one_or_none()
    
    if not guardian:
        raise HTTPException(
            status_code=404,
            detail="Guardian not found or does not belong to your organization"
        )
    
    linked_students = await _get_linkable_students(
        db,
        _guardian_student_ids(guardian_data),
        president_id,
        guardian_id=guardian.id,
    )
    
    # Update guardian fields
    guardian.first_name = guardian_data.guardian_info.first_name
    guardian.last_name = guardian_data.guardian_info.last_name
    guardian.relationship_to_student = guardian_data.guardian_info.relationship
    guardian.date_of_birth = guardian_data.guardian_info.date_of_birth
    guardian.phone_number = guardian_data.guardian_info.phone_number
    guardian.email = guardian_data.guardian_info.email
    guardian.job = guardian_data.guardian_info.job
    guardian.address = guardian_data.guardian_info.address
    guardian.students = linked_students
    
    # Update user account if needed
    if guardian.user:
        guardian.user.firstname = guardian_data.guardian_info.first_name
        guardian.user.lastname = guardian_data.guardian_info.last_name
        guardian.user.email = guardian_data.account_info.username
        
        # Update password only if provided
        if guardian_data.account_info.password:
            guardian.user.hashed_password = get_password_hash(
                guardian_data.account_info.password
            )
    
    await db.commit()
    logger.info(f"Guardian {guardian_id} updated by user {current_user.id}")
    loaded = await db.execute(
        select(Guardian)
        .options(selectinload(Guardian.user), selectinload(Guardian.students).selectinload(Student.user))
        .where(Guardian.id == guardian_id)
    )
    guardian = loaded.scalar_one()
    return _guardian_response(guardian)


@guardianRouter.delete("/{guardian_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_guardian(
    guardian_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_supervisor)
):
    """
    Delete a guardian.
    Only guardians belonging to the current president's organization can be deleted.
    This will also delete the associated user account (CASCADE).
    Only presidents and supervisors can delete guardians.
    """
    # Get president ID (works for both presidents and supervisors)
    president_id = await get_president_id_for_user(current_user, db)
    
    # Get guardian and verify it belongs to this president
    result = await db.execute(
        select(Guardian).where(
            Guardian.id == guardian_id,
            Guardian.president_id == president_id
        )
    )
    guardian = result.scalar_one_or_none()
    
    if not guardian:
        raise HTTPException(
            status_code=404,
            detail="Guardian not found or does not belong to your organization"
        )
    
    # Delete guardian (user will be deleted via CASCADE)
    await db.delete(guardian)
    await db.commit()
    
    logger.info(f"Guardian {guardian_id} deleted by user {current_user.id}")
    
    return None
