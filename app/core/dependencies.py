from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.core.security import decode_token

import logging
logger = logging.getLogger(__name__)



async def get_current_user(
        request: Request,  # ← Use Request instead of Cookie
        db: AsyncSession = Depends(get_db)
):
    # Try to get token from cookies first
    access_token = request.cookies.get("access_token")
    
    # If not in cookies, try Authorization header
    if not access_token:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            access_token = auth_header
        else:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Not authenticated",
                headers={"WWW-Authenticate": "Bearer"},
            )

    # Remove "Bearer " prefix if present
    token = access_token.removeprefix("Bearer ").strip()

    # Decode token
    payload = decode_token(token)
    
    # Check if token decode failed
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if payload.get("type") != "access":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check token type
    token_type = payload.get("role")

    # For admin tokens, check if type is "admin"
    if token_type == "admin":
        from app.models.admin import Admin
        admin_id = payload.get("admin_id")

        if admin_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid admin token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        result = await db.execute(
            select(Admin).where(Admin.id == admin_id)
        )
        admin = result.scalar_one_or_none()

        if admin is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Admin not found",
                headers={"WWW-Authenticate": "Bearer"},
            )

        if payload.get("ver", 0) != admin.auth_version:
            raise HTTPException(status_code=401, detail="Session expired; sign in again")

        return admin

    # For user tokens
    user_id = payload.get("user_id")
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if payload.get("ver", 0) != user.auth_version:
        raise HTTPException(status_code=401, detail="Session expired; sign in again")

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. Please wait for administrator approval."
        )

    return user

# ==================== ROLE-BASED DEPENDENCIES ====================

async def require_admin(
    current_user = Depends(get_current_user)
):
    from app.models.admin import Admin

    # If it's an Admin object, allow access
    if isinstance(current_user, Admin):
        return current_user

    # If it's a User with ADMIN role, allow access
    if hasattr(current_user, 'role') and current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires administrator privileges"
     )

    return current_user

async def require_president(
    current_user: User = Depends(get_current_user)
) -> User:
    if current_user.role != UserRoleEnum.PRESIDENT:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires president privileges"
        )
    return current_user


async def require_supervisor(
    current_user: User = Depends(get_current_user)
) -> User:
    allowed = [UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR]
    if current_user.role not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires supervisor privileges"
        )
    return current_user


async def require_president_or_supervisor(
    current_user: User = Depends(get_current_user)
):
    allowed = [UserRoleEnum.PRESIDENT, UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR]
    if current_user.role not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires president or supervisor privileges"
        )
    return current_user


async def require_president_or_chief_supervisor(
    current_user: User = Depends(get_current_user)
):
    """Chief Supervisor can manage supervisors"""
    allowed = [UserRoleEnum.PRESIDENT, UserRoleEnum.CHIEF_SUPERVISOR]
    if current_user.role not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires president or chief supervisor privileges"
        )
    return current_user


async def require_teacher(
    current_user: User = Depends(get_current_user)
) -> User:
    if current_user.role != UserRoleEnum.TEACHER:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires teacher privileges"
        )
    return current_user


async def require_teacher_or_above(
    current_user: User = Depends(get_current_user)
) -> User:
    allowed = [UserRoleEnum.TEACHER, UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR, UserRoleEnum.PRESIDENT]
    if current_user.role not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires teacher, supervisor, or president privileges"
        )
    return current_user


async def require_guardian(
    current_user: User = Depends(get_current_user)
) -> User:
    """
    Dependency that ensures the current user has GUARDIAN role.
    Raises 403 Forbidden if user is not a guardian.
    """
    if current_user.role != UserRoleEnum.GUARDIAN:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires guardian privileges"
        )
    return current_user


async def require_president_or_admin(
    current_user = Depends(get_current_user)
):
    """
    Dependency that allows both PRESIDENT and ADMIN access.
    Admins have full read/write access to all schools.
    """
    from app.models.admin import Admin
    
    # If it's an Admin object, allow access
    if isinstance(current_user, Admin):
        logger.info(f"Admin {current_user.id} accessing president endpoint")
        return current_user
    
    # If it's a User with PRESIDENT role, allow access
    if hasattr(current_user, 'role') and current_user.role == UserRoleEnum.PRESIDENT:
        logger.info(f"President {current_user.id} accessing endpoint")
        return current_user
    
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="This action requires president or administrator privileges"
    )
