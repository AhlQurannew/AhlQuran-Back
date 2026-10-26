## this file contains admin-only routes for managing users and presidents

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from datetime import datetime

from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.president import President
from app.core.dependencies import require_admin
import logging


adminRouter = APIRouter()
logger = logging.getLogger(__name__)

@adminRouter.get("/pending-presidents")
async def list_pending_presidents(
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    result = await db.execute(
        select(User)
        .join(President)
        .options(selectinload(User.president))
        .where(User.role == UserRoleEnum.PRESIDENT)
        .where(User.is_active == False)
    )
    pending_presidents = result.scalars().all()

    presidents_list = []

    for user in pending_presidents:
        presidents_list.append({
            "id": user.id,
            "email": user.email,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "school_name": user.president.school_name if user.president else None,
            "phone_number": user.president.phone_number if user.president else None,
        })
    
    return {
        "total": len(presidents_list),
        "pending_presidents": presidents_list
    }


@adminRouter.post("/approve-president/{user_id}")
async def approve_president(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    result = await db.execute(
        select(User).options(selectinload(User.president)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role != UserRoleEnum.PRESIDENT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a president"
        )
    
    if user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="President is already approved"
        )
    
    # Approve the president
    user.is_active = True
    
    # Update president profile
    if user.president:
        user.president.approval_date = datetime.utcnow()
    
    await db.commit()
    await db.refresh(user)
    
    return {
        "message": f"President {user.email} has been approved",
        "user": {
            "id": user.id,
            "email": user.email,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "role": user.role.value,
            "is_active": user.is_active,
            "school_name": user.president.school_name if user.president else None,
        }
    }


@adminRouter.delete("/reject-president/{user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def reject_president(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)  # ← Only admins
):
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role != UserRoleEnum.PRESIDENT:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is not a president"
        )
    
    if user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot reject an already approved president"
        )
    
    # Delete the user (cascade will delete president profile)
    await db.delete(user)
    await db.commit()
    
    return None  # 204 No Content


@adminRouter.get("/all-users")
async def list_all_users(
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)  # ← Only admins
):
    """
    ADMIN ONLY: List all users in the system.
    
    Shows all users regardless of role or status.
    """
    result = await db.execute(select(User))
    users = result.scalars().all()
    
    return {
        "total": len(users),
        "users": [
            {
                "id": user.id,
                "email": user.email,
                "firstname": user.firstname,
                "lastname": user.lastname,
                "role": user.role.value,
                "is_active": user.is_active,
                "created_at": user.created_at.isoformat()
            }
            for user in users
        ]
    }


@adminRouter.patch("/deactivate-user/{user_id}")
async def deactivate_user(
    user_id: int,
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    if user.role == UserRoleEnum.ADMIN:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot deactivate admin accounts"
        )
    
    user.is_active = False
    await db.commit()
    await db.refresh(user)
    
    return {
        "message": f"User {user.email} has been deactivated",
        "user": {
            "id": user.id,
            "email": user.email,
            "is_active": user.is_active
        }
    }


## School Management Endpoints

@adminRouter.get("/schools")
async def get_all_schools(
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    """
    ADMIN ONLY: Get all schools with detailed chief supervisor information and role counts.
    """
    from sqlalchemy import func as sql_func
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.models.supervisor import Supervisor
    from app.models.guardian import Guardian
    from app.models.chief_supervisor import ChiefSupervisor
    
    logger.info(f"[SCHOOLS] Admin requesting all schools")
    
    try:
        # Get all presidents (school placeholders)
        result = await db.execute(
            select(President)
            .options(
                selectinload(President.user),
                selectinload(President.chief_supervisors).selectinload(ChiefSupervisor.user)
            )
            .order_by(President.school_name)
        )
        presidents = result.scalars().all()
        
        logger.info(f"[SCHOOLS] Found {len(presidents)} schools")
        
        schools_list = []
        
        for president in presidents:
            # Get student count for this president
            student_result = await db.execute(
                select(sql_func.count(Student.id))
                .where(Student.president_id == president.id)
            )
            student_count = student_result.scalar() or 0
            
            # Get teacher count for this president
            teacher_result = await db.execute(
                select(sql_func.count(Teacher.id))
                .where(Teacher.president_id == president.id)
            )
            teacher_count = teacher_result.scalar() or 0
            
            # Get supervisor count for this president
            supervisor_result = await db.execute(
                select(sql_func.count(Supervisor.id))
                .where(Supervisor.president_id == president.id)
            )
            supervisor_count = supervisor_result.scalar() or 0
            
            # Get guardian count for this president
            guardian_result = await db.execute(
                select(sql_func.count(Guardian.id))
                .where(Guardian.president_id == president.id)
            )
            guardian_count = guardian_result.scalar() or 0
            
            # Use the Chief Supervisor's real email and name (not the placeholder president)
            chief = president.chief_supervisors[0] if president.chief_supervisors else None
            if chief and chief.user:
                display_email = chief.user.email
                display_name = f"{chief.user.firstname or ''} {chief.user.lastname or ''}".strip()
                is_active = chief.user.is_active
                chief_user_id = chief.user.id
            else:
                # Fallback to placeholder president data
                display_email = president.user.email if president.user else "غير محدد"
                display_name = f"{president.user.firstname or ''} {president.user.lastname or ''}".strip() if president.user else "غير محدد"
                is_active = president.user.is_active if president.user else False
                chief_user_id = president.user_id
            
            schools_list.append({
                "id": president.id,
                "user_id": chief_user_id,
                "school_name": president.school_name,
                "president_name": display_name or "غير محدد",
                "email": display_email,
                "phone_number": president.phone_number or "غير محدد",
                "student_count": student_count,
                "teacher_count": teacher_count,
                "supervisor_count": supervisor_count,
                "guardian_count": guardian_count,
                "president_count": 1,
                "approval_date": president.approval_date.isoformat() if president.approval_date else None,
                "created_at": president.created_at.isoformat() if president.created_at else None,
                "is_active": is_active
            })
        
        logger.info(f"[SCHOOLS] Returning {len(schools_list)} schools")
        
        return {
            "total": len(schools_list),
            "schools": schools_list
        }
    except Exception:
        logger.exception("Failed to fetch school overview")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Unable to fetch schools"
        )


@adminRouter.put("/schools/{school_id}")
async def update_school(
    school_id: int,
    school_data: dict,
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    """
    ADMIN ONLY: Update school and chief supervisor information.
    """
    from app.models.chief_supervisor import ChiefSupervisor
    logger.info(f"[UPDATE SCHOOL] Admin updating school ID: {school_id}")
    
    try:
        # Get the president (school placeholder)
        result = await db.execute(
            select(President)
            .options(
                selectinload(President.user),
                selectinload(President.chief_supervisors).selectinload(ChiefSupervisor.user)
            )
            .where(President.id == school_id)
        )
        president = result.scalar_one_or_none()
        
        if not president:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="School not found"
            )
        
        # Update school name
        if 'school_name' in school_data:
            president.school_name = school_data['school_name']
        
        # Update phone number
        if 'phone_number' in school_data:
            president.phone_number = school_data['phone_number']
        
        # Target the chief supervisor's user (real account), not the placeholder president
        chief = president.chief_supervisors[0] if president.chief_supervisors else None
        target_user = chief.user if chief and chief.user else president.user
        
        # Update name fields (sent as chief_supervisor_firstname / chief_supervisor_lastname from frontend)
        if 'chief_supervisor_firstname' in school_data:
            target_user.firstname = school_data['chief_supervisor_firstname']
        elif 'president_firstname' in school_data:
            target_user.firstname = school_data['president_firstname']
        
        if 'chief_supervisor_lastname' in school_data:
            target_user.lastname = school_data['chief_supervisor_lastname']
        elif 'president_lastname' in school_data:
            target_user.lastname = school_data['president_lastname']
        
        if 'email' in school_data:
            # Check if new email already exists on a different user
            email_check = await db.execute(
                select(User).where(User.email == school_data['email']).where(User.id != target_user.id)
            )
            existing_user = email_check.scalar_one_or_none()
            
            if existing_user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Email already exists"
                )
            
            target_user.email = school_data['email']
        
        # Update password if provided
        if 'password' in school_data and school_data['password']:
            from app.core.security import get_password_hash
            target_user.hashed_password = get_password_hash(school_data['password'])
        
        await db.commit()
        await db.refresh(president)
        
        logger.info(f"[UPDATE SCHOOL] School updated successfully: {president.school_name}")
        
        return {
            "message": "School updated successfully",
            "school": {
                "id": president.id,
                "school_name": president.school_name,
                "president_name": f"{target_user.firstname} {target_user.lastname}",
                "email": target_user.email,
                "phone_number": president.phone_number
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[UPDATE SCHOOL] Error: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error updating school: {str(e)}"
        )


@adminRouter.delete("/schools/{school_id}")
async def delete_school(
    school_id: int,
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    """
    ADMIN ONLY: Delete a school and all associated data and users.
    """
    from sqlalchemy import delete
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.models.supervisor import Supervisor
    from app.models.guardian import Guardian
    from app.models.chief_supervisor import ChiefSupervisor

    logger.info(f"[DELETE SCHOOL] Admin deleting school ID: {school_id}")
    
    try:
        # Get the president
        result = await db.execute(
            select(President).where(President.id == school_id)
        )
        president = result.scalar_one_or_none()
        
        if not president:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="School not found"
            )
        
        school_name = president.school_name
        
        # Collect all user_ids associated with this school to clean up their user accounts
        user_ids_to_delete = set()
        if president.user_id:
            user_ids_to_delete.add(president.user_id)
            
        cs_res = await db.execute(select(ChiefSupervisor.user_id).where(ChiefSupervisor.president_id == school_id))
        for uid in cs_res.scalars():
            if uid:
                user_ids_to_delete.add(uid)
                
        sup_res = await db.execute(select(Supervisor.user_id).where(Supervisor.president_id == school_id))
        for uid in sup_res.scalars():
            if uid:
                user_ids_to_delete.add(uid)
                
        t_res = await db.execute(select(Teacher.user_id).where(Teacher.president_id == school_id))
        for uid in t_res.scalars():
            if uid:
                user_ids_to_delete.add(uid)
                
        st_res = await db.execute(select(Student.user_id).where(Student.president_id == school_id))
        for uid in st_res.scalars():
            if uid:
                user_ids_to_delete.add(uid)
                
        g_res = await db.execute(select(Guardian.user_id).where(Guardian.president_id == school_id))
        for uid in g_res.scalars():
            if uid:
                user_ids_to_delete.add(uid)
        
        # Nullify any created_by_id references to these users across tables
        if user_ids_to_delete:
            from sqlalchemy import update
            uids_list = list(user_ids_to_delete)
            await db.execute(update(Supervisor).where(Supervisor.created_by_id.in_(uids_list)).values(created_by_id=None))
            await db.execute(update(Teacher).where(Teacher.created_by_id.in_(uids_list)).values(created_by_id=None))
            await db.execute(update(Student).where(Student.created_by_id.in_(uids_list)).values(created_by_id=None))
            await db.execute(update(Guardian).where(Guardian.created_by_id.in_(uids_list)).values(created_by_id=None))
            await db.execute(update(ChiefSupervisor).where(ChiefSupervisor.created_by_id.in_(uids_list)).values(created_by_id=None))
            await db.flush()
        
        # Delete the president directly (foreign keys with ondelete="CASCADE" in PostgreSQL 
        # will cascade-delete all school entities)
        await db.delete(president)
        await db.flush()
        
        # Now delete the associated user accounts
        if user_ids_to_delete:
            await db.execute(delete(User).where(User.id.in_(list(user_ids_to_delete))))
            
        await db.commit()
        
        logger.info(f"[DELETE SCHOOL] School '{school_name}' (ID: {school_id}) and {len(user_ids_to_delete)} users deleted successfully")
        
        return {
            "message": f"School '{school_name}' has been deleted successfully"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[DELETE SCHOOL] Error: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error deleting school: {str(e)}"
        )


@adminRouter.post("/schools")
async def create_school(
    school_data: dict,
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    """
    ADMIN ONLY: Create a new school with a Chief Supervisor (المشرف العام) account.
    
    Required fields:
    - school_name: str
    - chief_supervisor_firstname: str
    - chief_supervisor_lastname: str
    - email: str (chief supervisor email)
    - password: str (chief supervisor password)
    - phone_number: str (optional)
    """
    from app.core.security import get_password_hash
    from app.models.chief_supervisor import ChiefSupervisor
    
    logger.info(f"[CREATE SCHOOL] Admin creating new school: {school_data.get('school_name')}")
    
    try:
        # Validate required fields
        required_fields = ['school_name', 'chief_supervisor_firstname', 'chief_supervisor_lastname', 'email', 'password']
        missing_fields = [field for field in required_fields if not school_data.get(field)]
        
        if missing_fields:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Missing required fields: {', '.join(missing_fields)}"
            )
        
        school_email = str(school_data['email']).strip().lower()
        if not school_email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email is required"
            )

        # Emails are treated case-insensitively and stored in a normalized form.
        result = await db.execute(
            select(User).where(func.lower(User.email) == school_email)
        )
        existing_user = result.scalar_one_or_none()
        
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already exists"
            )
        
        # First, we need to create a president entry (legacy requirement for database structure)
        # Create a placeholder president user
        president_user = User(
            firstname="System",
            lastname="Admin",
            email=f"system.{datetime.utcnow().timestamp()}@school.internal",
            hashed_password=get_password_hash("system_placeholder"),
            role=UserRoleEnum.PRESIDENT,
            is_active=True
        )
        
        db.add(president_user)
        await db.flush()
        
        # Create president profile (placeholder for school association)
        new_president = President(
            user_id=president_user.id,
            school_name=school_data['school_name'],
            phone_number=school_data.get('phone_number', ''),
            approval_date=datetime.utcnow(),
            created_at=datetime.utcnow()
        )
        
        db.add(new_president)
        await db.flush()
        
        # Create Chief Supervisor user account (the actual school head)
        chief_user = User(
            firstname=school_data['chief_supervisor_firstname'],
            lastname=school_data['chief_supervisor_lastname'],
            email=school_email,
            hashed_password=get_password_hash(school_data['password']),
            role=UserRoleEnum.CHIEF_SUPERVISOR,
            is_active=True
        )
        
        db.add(chief_user)
        await db.flush()
        
        # Create chief supervisor profile
        chief_supervisor = ChiefSupervisor(
            user_id=chief_user.id,
            president_id=new_president.id,
            created_by_id=president_user.id,
            created_at=datetime.utcnow()
        )
        
        db.add(chief_supervisor)
        await db.commit()
        await db.refresh(chief_user)
        await db.refresh(new_president)
        
        logger.info(f"[CREATE SCHOOL] School created successfully: {new_president.school_name}")
        logger.info(f"[CREATE SCHOOL] Chief Supervisor created: {chief_user.email}")
        
        return {
            "message": "School created successfully with Chief Supervisor account",
            "school": {
                "id": new_president.id,
                "school_name": new_president.school_name,
                "chief_supervisor_name": f"{chief_user.firstname} {chief_user.lastname}",
                "email": chief_user.email,
                "phone_number": new_president.phone_number,
                "is_active": chief_user.is_active
            }
        }
        
    except HTTPException:
        raise
    except IntegrityError as e:
        await db.rollback()
        logger.info("[CREATE SCHOOL] Duplicate email rejected during commit")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already exists"
        ) from e
    except Exception as e:
        logger.error(f"[CREATE SCHOOL] Error: {str(e)}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Error creating school: {str(e)}"
        )


## Statistics Endpoints

@adminRouter.get("/statistics/overview")
async def get_admin_statistics(
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    """
    ADMIN ONLY: Get overview statistics for admin dashboard.
    """
    from sqlalchemy import func as sql_func
    from app.models.student import Student
    
    # Total approved presidents
    result_approved = await db.execute(
        select(User)
        .where(User.role == UserRoleEnum.PRESIDENT)
        .where(User.is_active == True)
    )
    total_presidents = len(result_approved.scalars().all())
    
    # Pending approval requests
    result_pending = await db.execute(
        select(User)
        .where(User.role == UserRoleEnum.PRESIDENT)
        .where(User.is_active == False)
    )
    pending_requests = len(result_pending.scalars().all())
    
    # Total unique schools
    result_schools = await db.execute(
        select(sql_func.count(sql_func.distinct(President.school_name)))
        .join(User, President.user_id == User.id)
        .where(User.role == UserRoleEnum.PRESIDENT)
        .where(User.is_active == True)
    )
    total_schools = result_schools.scalar() or 0
    
    return {
        "total_schools": total_schools,
        "total_presidents": total_presidents,
        "pending_requests": pending_requests,
        "performance": None
    }


@adminRouter.get("/statistics/schools")
async def get_schools_statistics(
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin),
    limit: int = 3
):
    """
    ADMIN ONLY: Get schools with their student counts and percentages.
    """
    from sqlalchemy import func as sql_func
    from app.models.student import Student
    
    # Get total student count
    result_total = await db.execute(
        select(sql_func.count(Student.id))
    )
    total_students = result_total.scalar() or 0
    
    # Get schools with student counts
    result_schools = await db.execute(
        select(
            President.id.label('school_id'),
            President.school_name,
            User.firstname,
            User.lastname,
            sql_func.count(Student.id).label('student_count')
        )
        .join(User, President.user_id == User.id)
        .outerjoin(Student, Student.president_id == President.id)
        .where(User.is_active == True)
        .group_by(President.id, President.school_name, User.firstname, User.lastname)
        .order_by(sql_func.count(Student.id).desc())
        .limit(limit)
    )
    
    schools_list = []
    for row in result_schools:
        president_name = f"{row.firstname or ''} {row.lastname or ''}".strip()
        student_count = row.student_count
        percentage = (student_count / total_students * 100) if total_students > 0 else 0
        
        schools_list.append({
            "school_id": row.school_id,
            "school_name": row.school_name,
            "student_count": student_count,
            "president_name": president_name,
            "percentage": round(percentage, 1)
        })
    
    return {
        "total_students": total_students,
        "schools": schools_list
    }



@adminRouter.get("/school/{school_id}/president")
async def get_school_president(
    school_id: int,
    db: AsyncSession = Depends(get_db),
    admin = Depends(require_admin)
):
    """
    ADMIN ONLY: Get president information for a specific school.
    This allows admin to impersonate/view as that president.
    """
    result = await db.execute(
        select(President, User)
        .join(User, President.user_id == User.id)
        .where(President.id == school_id)
        .where(User.is_active == True)
    )
    
    row = result.first()
    
    if not row:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="School not found"
        )
    
    president, user = row
    
    return {
        "president_id": president.id,
        "user_id": user.id,
        "school_name": president.school_name,
        "president_name": f"{user.firstname or ''} {user.lastname or ''}".strip(),
        "email": user.email,
        "phone_number": president.phone_number
    }
