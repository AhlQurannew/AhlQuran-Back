"""
API endpoints for managing supervisors (المشرفين)
Only accessible by Chief Supervisors (المشرف العام) and Presidents
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.core.dependencies import require_president_or_chief_supervisor
from app.core.multi_tenancy import get_president_id_for_user
from app.core.security import get_password_hash
from app.models.user import User, UserRoleEnum
from app.models.supervisor import Supervisor
from app.schemas.supervisor import (
    SupervisorCreate,
    SupervisorUpdate,
    SupervisorResponse,
    SupervisorList
)

import logging
logger = logging.getLogger(__name__)

supervisorRouter = APIRouter()


@supervisorRouter.post("/", response_model=SupervisorResponse, status_code=status.HTTP_201_CREATED)
async def create_supervisor(
    supervisor_data: SupervisorCreate,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_chief_supervisor)
):
    """Create a new supervisor. Only presidents and chief supervisors can create supervisors."""
    logger.debug(f"supervisor data: {supervisor_data} \n current user: {current_user}")

    # Get president ID
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)

    # Check if email already exists
    result = await db.execute(
        select(User).where(User.email == supervisor_data.email)
    )
    existing_user = result.scalar_one_or_none()

    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )

    # Create user record with SUPERVISOR role
    new_user = User(
        firstname=supervisor_data.firstname,
        lastname=supervisor_data.lastname,
        email=supervisor_data.email,
        hashed_password=get_password_hash(supervisor_data.password),
        role=UserRoleEnum.SUPERVISOR,
        is_active=True
    )

    db.add(new_user)
    await db.flush()

    # Create supervisor record
    new_supervisor = Supervisor(
        user_id=new_user.id,
        president_id=president_id,
        created_by_id=current_user.id
    )

    db.add(new_supervisor)
    await db.commit()
    await db.refresh(new_supervisor)
    await db.refresh(new_user)

    logger.info(f"Supervisor created: {new_supervisor.id} by user {current_user.id}")

    return SupervisorResponse(
        id=new_supervisor.id,
        user_id=new_user.id,
        firstname=new_user.firstname,
        lastname=new_user.lastname,
        email=new_user.email,
        created_at=new_supervisor.created_at,
        is_active=new_user.is_active
    )


@supervisorRouter.get("/", response_model=SupervisorList)
async def list_supervisors(
    skip: int = 0,
    limit: int = 100,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_chief_supervisor)
):
    """Get all supervisors. Only presidents and chief supervisors can view supervisors.
    Admin users must pass school_id to specify which school's supervisors to list.
    """

    # Get president ID for filtering (admin must pass school_id)
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)

    result = await db.execute(
        select(Supervisor)
        .options(selectinload(Supervisor.user))
        .where(Supervisor.president_id == president_id)
        .offset(skip)
        .limit(limit)
    )
    supervisors = result.scalars().all()

    # Get total count
    count_result = await db.execute(
        select(func.count()).select_from(Supervisor).where(Supervisor.president_id == president_id)
    )
    total = count_result.scalar() or 0

    supervisor_responses = [
        SupervisorResponse(
            id=supervisor.id,
            user_id=supervisor.user.id,
            firstname=supervisor.user.firstname,
            lastname=supervisor.user.lastname,
            email=supervisor.user.email,
            created_at=supervisor.created_at,
            is_active=supervisor.user.is_active
        )
        for supervisor in supervisors
    ]

    return SupervisorList(supervisors=supervisor_responses, total=total)


@supervisorRouter.get("/{supervisor_id}", response_model=SupervisorResponse)
async def get_supervisor(
    supervisor_id: int,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_chief_supervisor)
):
    """Get supervisor by ID"""
    
    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)

    result = await db.execute(
        select(Supervisor)
        .options(selectinload(Supervisor.user))
        .where(Supervisor.id == supervisor_id, Supervisor.president_id == president_id)
    )
    supervisor = result.scalar_one_or_none()

    if not supervisor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supervisor with ID {supervisor_id} not found"
        )

    return SupervisorResponse(
        id=supervisor.id,
        user_id=supervisor.user.id,
        firstname=supervisor.user.firstname,
        lastname=supervisor.user.lastname,
        email=supervisor.user.email,
        created_at=supervisor.created_at,
        is_active=supervisor.user.is_active
    )


@supervisorRouter.put("/{supervisor_id}", response_model=SupervisorResponse)
async def update_supervisor(
    supervisor_id: int,
    supervisor_data: SupervisorUpdate,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_chief_supervisor)
):
    """Update supervisor information"""

    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)

    result = await db.execute(
        select(Supervisor)
        .options(selectinload(Supervisor.user))
        .where(Supervisor.id == supervisor_id, Supervisor.president_id == president_id)
    )
    supervisor = result.scalar_one_or_none()

    if not supervisor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supervisor with ID {supervisor_id} not found"
        )

    # Update user fields
    update_data = supervisor_data.model_dump(exclude_unset=True)

    if "firstname" in update_data:
        supervisor.user.firstname = update_data["firstname"]
    if "lastname" in update_data:
        supervisor.user.lastname = update_data["lastname"]
    if "email" in update_data:
        # Check if new email is already taken
        email_result = await db.execute(
            select(User).where(User.email == update_data["email"], User.id != supervisor.user.id)
        )
        if email_result.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        supervisor.user.email = update_data["email"]

    # Handle password reset if provided
    if "password" in update_data and update_data["password"]:
        supervisor.user.hashed_password = get_password_hash(update_data["password"])
        logger.info(f"Password reset for supervisor {supervisor_id} by user {current_user.id}")

    await db.commit()
    await db.refresh(supervisor)
    await db.refresh(supervisor.user)

    logger.info(f"Supervisor {supervisor_id} updated by user {current_user.id}")

    return SupervisorResponse(
        id=supervisor.id,
        user_id=supervisor.user.id,
        firstname=supervisor.user.firstname,
        lastname=supervisor.user.lastname,
        email=supervisor.user.email,
        created_at=supervisor.created_at,
        is_active=supervisor.user.is_active
    )


@supervisorRouter.delete("/{supervisor_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_supervisor(
    supervisor_id: int,
    school_id: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president_or_chief_supervisor)
):
    """Delete a supervisor"""

    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db, school_id=school_id)

    result = await db.execute(
        select(Supervisor).where(Supervisor.id == supervisor_id, Supervisor.president_id == president_id)
    )
    supervisor = result.scalar_one_or_none()

    if not supervisor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supervisor with ID {supervisor_id} not found"
        )

    await db.delete(supervisor)
    await db.commit()

    logger.info(f"Supervisor {supervisor_id} deleted by user {current_user.id}")
    
    return None
