"""
@file dependencies.py
@description Dependency injection functions for FastAPI endpoints

This module provides authentication and authorization dependencies used across all API routes.
Key features:
- JWT token validation and user extraction
- Role-based access control (RBAC)
- Admin role override system (allows admin to act as CHIEF_SUPERVISOR)
- Multi-tenant user context (president, supervisor, teacher)

@author Ahl El Quran Team
@version 1.0.0
"""

from fastapi import Depends, HTTPException, status, Request
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.core.security import decode_token

import logging
logger = logging.getLogger(__name__)


async def get_current_user(
        request: Request,  # Request object to access headers and cookies
        db: AsyncSession = Depends(get_db)
):
    """
    Extract and validate the current authenticated user from JWT token.
    
    This is the core authentication dependency used by all protected endpoints.
    It supports both cookie-based and header-based authentication.
    
    Token Sources (in order of priority):
    1. Cookie: access_token
    2. Header: Authorization: Bearer <token>
    
    Token Types:
    - "admin": Returns Admin object (or AdminAsUser if role override header present)
    - "access": Returns User object (president, supervisor, teacher, student, guardian)
    
    Admin Role Override:
    If token type is "admin" and X-Role-Override header is present:
    - Creates AdminAsUser object with specified role (e.g., CHIEF_SUPERVISOR)
    - Adds is_admin=True flag for special handling in permission checks
    - Requires school_id parameter in endpoints to scope operations
    
    Args:
        request (Request): FastAPI request object
        db (AsyncSession): Database session from dependency
        
    Returns:
        User | Admin | AdminAsUser: Authenticated user object
        
    Raises:
        HTTPException 401: If token is missing, invalid, or expired
        HTTPException 401: If user/admin not found in database
        
    Example:
        @router.get("/students")
        async def get_students(current_user: User = Depends(get_current_user)):
            # current_user is now authenticated and validated
            return await fetch_students(current_user.id)
    """
    
    # Try to get token from cookies first (web browsers)
    access_token = request.cookies.get("access_token")
    
    # If not in cookies, try Authorization header (mobile apps, Postman, etc.)
    if not access_token:
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            access_token = auth_header
        else:
            logger.error("No access token found in cookies or Authorization header")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Not authenticated",
                headers={"WWW-Authenticate": "Bearer"},
            )

    logger.info(f"Received credentials: {access_token[:50]}...")
    
    # Remove "Bearer " prefix if present (from Authorization header)
    token = access_token.replace("Bearer ", "")
    logger.info(f"Token after removing Bearer: {token[:50]}...")
    
    # Decode JWT token and extract payload
    payload = decode_token(token)
    logger.info(f"Decoded payload: {payload}")
    
    # Check if token decode failed (invalid signature, expired, etc.)
    if payload is None:
        logger.error("Token decode failed - payload is None")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Extract token type (admin or access) and role
    token_type = payload.get("role")
    logger.info(f"Token role: {token_type}")
    
    # Log all request headers for debugging (useful for troubleshooting role override)
    logger.info(f"Request headers: {dict(request.headers)}")

    # ============================================================
    # ADMIN TOKEN HANDLING (token_type == "admin")
    # ============================================================
    if token_type == "admin":
        from app.models.admin import Admin
        admin_id = payload.get("admin_id")

        if admin_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid admin token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Fetch admin from database
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

        # ============================================================
        # ADMIN ROLE OVERRIDE SYSTEM
        # ============================================================
        # Check for X-Role-Override header (sent by frontend when admin views a school)
        # This allows admin to act as CHIEF_SUPERVISOR for a specific school
        role_override = request.headers.get("X-Role-Override")
        logger.info(f"Role override header: {role_override}")
        
        if role_override:
            logger.info(f"Admin role override detected: {role_override}")
            
            # Create a User-like object with admin's info but CHIEF_SUPERVISOR role
            # This object will pass role checks like require_president_or_supervisor()
            class AdminAsUser:
                """
                Special user object for admin role override.
                Behaves like a User but has is_admin=True flag.
                """
                def __init__(self, admin, role):
                    self.id = admin.id                          # Admin's ID
                    self.role = UserRoleEnum(role)              # Override role (CHIEF_SUPERVISOR)
                    self.is_active = True                       # Always active
                    self.is_admin = True                        # Special flag for permission checks
                    self._admin_obj = admin                     # Reference to original admin object
            
            return AdminAsUser(admin, role_override)
        
        # No role override - return admin as-is
        return admin

    # ============================================================
    # USER TOKEN HANDLING (token_type == "access")
    # ============================================================
    # For user tokens (president, supervisor, teacher, student, guardian)
    user_id = payload.get("user_id")
    if user_id is None:
        logger.error("No user_id in token payload")
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
        logger.error(f"User not found for user_id: {user_id}")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        logger.error(f"User {user_id} is inactive")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. Please wait for administrator approval."
        )

    logger.info(f"User authenticated: id={user.id}, role={user.role}")
    return user

# ==================== ROLE-BASED DEPENDENCIES ====================

async def require_admin(
    current_user = Depends(get_current_user)
):
    from app.models.admin import Admin
    logger.info(f"the current admin : {current_user}")

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
    current_user = Depends(get_current_user)
):
    from app.models.admin import Admin
    
    # If it's an Admin object, allow access (admin can view as chief supervisor)
    if isinstance(current_user, Admin):
        return current_user
    
    # Check if it's AdminAsUser (role override)
    if hasattr(current_user, 'is_admin') and current_user.is_admin:
        return current_user
    
    allowed = [UserRoleEnum.PRESIDENT, UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR]
    if current_user.role not in allowed:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This action requires president or supervisor privileges"
        )
    return current_user


async def require_president_or_chief_supervisor(
    current_user = Depends(get_current_user)
):
    """Chief Supervisor can manage supervisors. Admin can also access."""
    from app.models.admin import Admin
    
    # If it's an Admin object, allow access
    if isinstance(current_user, Admin):
        return current_user
    
    # Check if it's AdminAsUser (role override)
    if hasattr(current_user, 'is_admin') and current_user.is_admin:
        return current_user
    
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
    logger.info(f"require_teacher check: user_id={current_user.id}, role={current_user.role}, role_type={type(current_user.role)}")
    logger.info(f"UserRoleEnum.TEACHER={UserRoleEnum.TEACHER}, type={type(UserRoleEnum.TEACHER)}")
    if current_user.role != UserRoleEnum.TEACHER:
        logger.error(f"Role mismatch: {current_user.role} != {UserRoleEnum.TEACHER}")
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"TEACHER_CHECK_FAILED: This action requires teacher privileges. Your role: {current_user.role}"
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
    
    # If it's a User with PRESIDENT or CHIEF_SUPERVISOR role, allow access
    if hasattr(current_user, 'role') and current_user.role in [UserRoleEnum.PRESIDENT, UserRoleEnum.CHIEF_SUPERVISOR]:
        logger.info(f"President/ChiefSupervisor {current_user.id} accessing endpoint")
        return current_user
    
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="This action requires president or administrator privileges"
    )