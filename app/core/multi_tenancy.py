"""
Multi-tenancy helper functions for president-based data isolation
"""
from fastapi import HTTPException, Depends
from sqlalchemy.orm import Session
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.president import President
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.user import User
from app.core.dependencies import get_current_user, get_db


async def get_president_id_for_user(
    current_user,
    db: AsyncSession,
    school_id: int = None
) -> int:
    """
    Get the president_id for any user (president, supervisor, teacher, or admin).
    
    - If user is a president: returns their president.id
    - If user is a supervisor: returns their supervisor.president_id
    - If user is a teacher: returns their teacher.president_id
    - If user is an admin: returns the president_id from school_id parameter
    
    Raises HTTPException if unable to determine president_id.
    """
    from app.models.user import UserRoleEnum
    from app.models.admin import Admin
    
    # Handle admin users
    if isinstance(current_user, Admin):
        if school_id is None:
            raise HTTPException(
                status_code=400,
                detail="Admin must provide school_id parameter"
            )
        # Validate that the school exists
        result = await db.execute(
            select(President).where(President.id == school_id)
        )
        president = result.scalar_one_or_none()
        if not president:
            raise HTTPException(
                status_code=404,
                detail="School not found"
            )
        return president.id
    
    if current_user.role == UserRoleEnum.PRESIDENT:
        result = await db.execute(
            select(President).where(President.user_id == current_user.id)
        )
        president = result.scalar_one_or_none()
        if not president:
            raise HTTPException(
                status_code=403,
                detail="President record not found"
            )
        return president.id
    
    elif current_user.role == UserRoleEnum.SUPERVISOR:
        result = await db.execute(
            select(Supervisor).where(Supervisor.user_id == current_user.id)
        )
        supervisor = result.scalar_one_or_none()
        if not supervisor or not supervisor.president_id:
            raise HTTPException(
                status_code=403,
                detail="Supervisor record not found or not linked to a president"
            )
        return supervisor.president_id
    
    elif current_user.role == UserRoleEnum.TEACHER:
        result = await db.execute(
            select(Teacher).where(Teacher.user_id == current_user.id)
        )
        teacher = result.scalar_one_or_none()
        if not teacher or not teacher.president_id:
            raise HTTPException(
                status_code=403,
                detail="Teacher record not found or not linked to a president"
            )
        return teacher.president_id
    
    else:
        raise HTTPException(
            status_code=403,
            detail="Unable to determine organization for this user role"
        )


def get_current_president(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> President:
    """
    Get the president associated with the current user.
    Raises 403 if user is not a president.
    
    Use this dependency in all endpoints that need president-scoped data.
    """
    president = db.query(President).filter(President.user_id == current_user.id).first()
    
    if not president:
        raise HTTPException(
            status_code=403,
            detail="Access denied. Only presidents can access this resource."
        )
    
    if not president.is_verified:
        raise HTTPException(
            status_code=403,
            detail="Your account is pending approval. Please wait for admin verification."
        )
    
    return president


def get_president_id(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> int:
    """
    Get the president ID for the current user.
    Convenience function that returns just the ID.
    """
    president = get_current_president(current_user, db)
    return president.id


def filter_by_president(query, model_class, president: President):
    """
    Helper function to filter a query by president_id.
    
    Usage:
        query = db.query(Student)
        query = filter_by_president(query, Student, president)
        students = query.all()
    """
    return query.filter(model_class.president_id == president.id)

