## this file contains admin-only routes for managing users and presidents

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
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
    ADMIN ONLY: Get all schools with detailed president information and role counts.
    """
    from sqlalchemy import func as sql_func
    from app.models.student import Student
    from app.models.teacher import Teacher
    from app.models.supervisor import Supervisor
    from app.models.guardian import Guardian
    
    logger.info(f"[SCHOOLS] Admin requesting all schools")
    
    try:
        # Get all approved presidents with their schools
        result = await db.execute(
            select(User)
            .join(President, President.user_id == User.id)
            .options(selectinload(User.president))
            .where(User.role == UserRoleEnum.PRESIDENT)
            .where(User.is_active == True)
            .order_by(President.school_name)
        )
        presidents = result.scalars().all()
        
        logger.info(f"[SCHOOLS] Found {len(presidents)} approved presidents")
        
        schools_list = []
        
        for user in presidents:
            # Get student count for this president
            student_result = await db.execute(
                select(sql_func.count(Student.id))
                .where(Student.president_id == user.president.id)
            )
            student_count = student_result.scalar() or 0
            
            # Get teacher count for this president
            teacher_result = await db.execute(
                select(sql_func.count(Teacher.id))
                .where(Teacher.president_id == user.president.id)
            )
            teacher_count = teacher_result.scalar() or 0
            
            # Get supervisor count for this president
            supervisor_result = await db.execute(
                select(sql_func.count(Supervisor.id))
                .where(Supervisor.president_id == user.president.id)
            )
            supervisor_count = supervisor_result.scalar() or 0
            
            # Get guardian count for this president
            guardian_result = await db.execute(
                select(sql_func.count(Guardian.id))
                .where(Guardian.president_id == user.president.id)
            )
            guardian_count = guardian_result.scalar() or 0
            
            president_name = f"{user.firstname or ''} {user.lastname or ''}".strip() or "غير محدد"
            
            schools_list.append({
                "id": user.president.id,
                "user_id": user.id,
                "school_name": user.president.school_name,
                "president_name": president_name,
                "email": user.email,
                "phone_number": user.president.phone_number or "غير محدد",
                "student_count": student_count,
                "teacher_count": teacher_count,
                "supervisor_count": supervisor_count,
                "guardian_count": guardian_count,
                "president_count": 1,  # Always 1 president per school
                "approval_date": user.president.approval_date.isoformat() if user.president.approval_date else None,
                "created_at": user.president.created_at.isoformat() if user.president.created_at else None,
                "is_active": user.is_active
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
