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
    logger.info(f"Admin __ : {admin}")

    result = await db.execute(
        select(User).options(selectinload(User.president)).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()

    logger.info(f"the president {result}")

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