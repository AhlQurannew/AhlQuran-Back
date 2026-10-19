from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.supervisor import Supervisor
from app.schemas.supervisor import SupervisorCreate, SupervisorUpdate, SupervisorResponse, SupervisorList
from app.core.dependencies import get_current_user, require_president
from app.core.multi_tenancy import get_president_id_for_user, get_created_by_user_id
from app.core.security import get_password_hash
import logging

logger = logging.getLogger(__name__)

supervisorRouter = APIRouter()


def map_supervisor_to_response(supervisor: Supervisor) -> SupervisorResponse:
    """Helper to map DB Supervisor model to SupervisorResponse"""
    return SupervisorResponse(
        id=supervisor.id,
        user_id=supervisor.user.id,
        firstname=supervisor.user.firstname,
        lastname=supervisor.user.lastname,
        email=supervisor.user.email,
        is_active=supervisor.user.is_active,
        created_at=supervisor.created_at
    )


@supervisorRouter.post("/", response_model=SupervisorResponse, status_code=status.HTTP_201_CREATED)
async def create_supervisor(
    supervisor_data: SupervisorCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president)
):
    """Create a new supervisor. Only presidents can create supervisors."""
    
    # Get president ID
    president_id = await get_president_id_for_user(current_user, db)
    
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

    # Create user record
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

    # Create supervisor record with president_id
    new_supervisor = Supervisor(
        user_id=new_user.id,
        president_id=president_id,
        created_by_id=get_created_by_user_id(current_user)
    )

    db.add(new_supervisor)
    await db.commit()
    
    # Reload with relationships
    result = await db.execute(
        select(Supervisor)
        .options(selectinload(Supervisor.user))
        .where(Supervisor.id == new_supervisor.id)
    )
    loaded_supervisor = result.scalar_one()

    logger.info(f"Supervisor created: {new_supervisor.id} by user {current_user.id}")

    return map_supervisor_to_response(loaded_supervisor)


@supervisorRouter.get("/", response_model=SupervisorList)
async def list_supervisors(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president)
):
    """Get all supervisors. Only presidents can view supervisors."""

    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db)

    query = select(Supervisor).options(
        selectinload(Supervisor.user)
    ).where(Supervisor.president_id == president_id).offset(skip).limit(limit)
    
    result = await db.execute(query)
    supervisors = result.scalars().unique().all()

    # Get total count with same filter
    count_result = await db.execute(
        select(Supervisor).where(Supervisor.president_id == president_id)
    )
    total = len(count_result.scalars().all())

    supervisor_responses = [map_supervisor_to_response(supervisor) for supervisor in supervisors]

    return SupervisorList(supervisors=supervisor_responses, total=total)


@supervisorRouter.get("/{supervisor_id}", response_model=SupervisorResponse)
async def get_supervisor(
    supervisor_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president)
):
    """Get a specific supervisor by ID. Only presidents can view supervisors."""

    # Get president ID for filtering
    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db)

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

    return map_supervisor_to_response(supervisor)


@supervisorRouter.put("/{supervisor_id}", response_model=SupervisorResponse)
async def update_supervisor(
    supervisor_id: int,
    supervisor_data: SupervisorUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president)
):
    """Update supervisor information. Only presidents can update supervisors."""

    result = await db.execute(
        select(Supervisor)
        .options(selectinload(Supervisor.user))
        .where(Supervisor.id == supervisor_id)
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
    
    # Update password if provided
    if "password" in update_data and update_data["password"]:
        supervisor.user.hashed_password = get_password_hash(update_data["password"])

    await db.commit()
    await db.refresh(supervisor)
    await db.refresh(supervisor.user)

    logger.info(f"Supervisor {supervisor_id} updated by user {current_user.id}")

    return map_supervisor_to_response(supervisor)


@supervisorRouter.delete("/{supervisor_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_supervisor(
    supervisor_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_president)
):
    """Delete a supervisor. Only presidents can delete supervisors."""

    result = await db.execute(
        select(Supervisor).where(Supervisor.id == supervisor_id)
    )
    supervisor = result.scalar_one_or_none()

    if not supervisor:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Supervisor with ID {supervisor_id} not found"
        )

    # Delete the supervisor (will cascade to user due to relationship)
    await db.delete(supervisor)
    await db.commit()

    logger.info(f"Supervisor {supervisor_id} deleted by user {current_user.id}")

    return None