from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.supervisor import Supervisor
from app.schemas.supervisor import SupervisorCreate, SupervisorUpdate, SupervisorResponse, SupervisorList
from app.core.dependencies import (
    require_president_chief_supervisor_or_admin,
)
from app.core.multi_tenancy import get_president_id_for_user, get_creator_user_id
from app.core.security import get_password_hash
import logging

logger = logging.getLogger(__name__)

supervisorRouter = APIRouter()


def _ensure_regular_supervisor_target(supervisor: Supervisor, current_user) -> None:
    if (
        getattr(current_user, "role", None) == UserRoleEnum.CHIEF_SUPERVISOR
        and supervisor.user.role != UserRoleEnum.SUPERVISOR
    ):
        raise HTTPException(status_code=404, detail="Supervisor not found")


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
    current_user=Depends(require_president_chief_supervisor_or_admin),
    school_id: int | None = None,
):
    """Create a regular supervisor within the selected school."""
    president_id = await get_president_id_for_user(current_user, db, school_id)
    existing_user = await db.execute(select(User).where(User.email == supervisor_data.email))
    if existing_user.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = User(
        firstname=supervisor_data.firstname,
        lastname=supervisor_data.lastname,
        email=supervisor_data.email,
        hashed_password=get_password_hash(supervisor_data.password),
        role=UserRoleEnum.SUPERVISOR,
        is_active=True,
    )
    db.add(new_user)
    await db.flush()
    new_supervisor = Supervisor(
        user_id=new_user.id,
        president_id=president_id,
        created_by_id=await get_creator_user_id(current_user, president_id, db),
    )
    db.add(new_supervisor)
    await db.commit()

    loaded = await db.execute(
        select(Supervisor)
        .options(selectinload(Supervisor.user))
        .where(Supervisor.id == new_supervisor.id, Supervisor.president_id == president_id)
    )
    return map_supervisor_to_response(loaded.scalar_one())


@supervisorRouter.get("/", response_model=SupervisorList)
async def list_supervisors(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_president_chief_supervisor_or_admin),
    school_id: int | None = None,
):
    """Get manageable supervisors for the current school."""

    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db, school_id)

    query = select(Supervisor).options(
        selectinload(Supervisor.user)
    ).where(Supervisor.president_id == president_id).offset(skip).limit(limit)
    count_query = select(Supervisor).where(Supervisor.president_id == president_id)
    if getattr(current_user, "role", None) == UserRoleEnum.CHIEF_SUPERVISOR:
        query = query.join(User, User.id == Supervisor.user_id).where(User.role == UserRoleEnum.SUPERVISOR)
        count_query = count_query.join(User, User.id == Supervisor.user_id).where(User.role == UserRoleEnum.SUPERVISOR)
    
    result = await db.execute(query)
    supervisors = result.scalars().unique().all()

    # Get total count with same filter
    count_result = await db.execute(
        count_query
    )
    total = len(count_result.scalars().all())

    supervisor_responses = [map_supervisor_to_response(supervisor) for supervisor in supervisors]

    return SupervisorList(supervisors=supervisor_responses, total=total)


@supervisorRouter.get("/{supervisor_id}", response_model=SupervisorResponse)
async def get_supervisor(
    supervisor_id: int,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_president_chief_supervisor_or_admin),
    school_id: int | None = None,
):
    """Get a supervisor in the current school."""

    # Get president ID for filtering
    # Get president ID for filtering
    president_id = await get_president_id_for_user(current_user, db, school_id)

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

    _ensure_regular_supervisor_target(supervisor, current_user)

    return map_supervisor_to_response(supervisor)


@supervisorRouter.put("/{supervisor_id}", response_model=SupervisorResponse)
async def update_supervisor(
    supervisor_id: int,
    supervisor_data: SupervisorUpdate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(require_president_chief_supervisor_or_admin),
    school_id: int | None = None,
):
    """Update a manageable supervisor in the current school."""

    president_id = await get_president_id_for_user(current_user, db, school_id)

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

    _ensure_regular_supervisor_target(supervisor, current_user)

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
    current_user=Depends(require_president_chief_supervisor_or_admin),
    school_id: int | None = None,
):
    """Delete a manageable supervisor in the current school."""

    president_id = await get_president_id_for_user(current_user, db, school_id)

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

    _ensure_regular_supervisor_target(supervisor, current_user)

    # Delete the supervisor (will cascade to user due to relationship)
    await db.delete(supervisor)
    await db.commit()

    logger.info(f"Supervisor {supervisor_id} deleted by user {current_user.id}")

    return None
