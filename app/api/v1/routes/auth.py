from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import timedelta
import logging

from app.db.session import get_db
from app.models.admin import Admin
from app.models.user import User, UserRoleEnum
from app.models.president import President
from app.models.teacher import Teacher
from app.models.guardian import Guardian
from app.core.security import create_access_token, create_refresh_token, verify_password, upgrade_password_if_needed, get_password_hash, decode_token
from app.core.config import settings
from app.schemas.auth import (
    AdminLoginReq,
    RegisterRequest, 
    RegisterResponse,
    LoginRequest,
    Token,
    RefreshTokenRequest,
    RefreshTokenResponse,
    ChangePasswordRequest,
    ChangePasswordResponse
)
from app.core.dependencies import get_current_user, require_admin

authRouter = APIRouter()
logger = logging.getLogger(__name__)


# ========== PRESIDENT REGISTRATION ==========
@authRouter.post("/president/register", response_model=RegisterResponse)
async def president_register(
    data: RegisterRequest, 
    response : Response,
    db: AsyncSession = Depends(get_db),
):

    result = await db.execute(
        select(User).where(User.email == data.email)
    )
    existing_user = result.scalar_one_or_none()
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is already registered"
        )

    new_user = User(
        firstname=data.firstname,
        lastname=data.lastname,
        email=data.email,
        hashed_password=get_password_hash(data.password), 
        role=UserRoleEnum.PRESIDENT, 
        is_active=False
    )
    
    db.add(new_user)
    await db.flush()  # get the user.id without committing using the flush function
    
    # ========== STEP 3: Create President record ==========

    new_president = President(
        user_id=new_user.id,  # ← Link to the user we just created
        school_name=data.school_name,
        phone_number=data.phone_number,
        is_verified=False  # ← Not verified until admin approves
    )


    
    db.add(new_president)
    await db.commit()  # ← Commit both User and President
    await db.refresh(new_user)  # ← Refresh to get relationships loaded

    # ========== STEP 4: Return success message ==========

    return {
        "message": "Registration successful. Your account is pending administrator approval."
    }

# ========== PRESIDENT LOGIN ==========
@authRouter.post("/president/login", response_model=Token)
async def president_login(
    form_data: LoginRequest,
    response : Response,
    db: AsyncSession = Depends(get_db),
):

    # Find user by email AND role
    result = await db.execute(
        select(User).where(
            User.email == form_data.email,
            User.role == UserRoleEnum.PRESIDENT
        )
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password (with backward compatibility for plain text)
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Upgrade password to bcrypt if it's still plain text
    await upgrade_password_if_needed(db, user, form_data.password)
    
    # Check if user is active (admin approved)
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is pending admin approval. Please wait for administrator to activate your account."
        )

    logger.info(f"president login: {user}")

    # Create access token and refresh token
    token_data = {
        "email": user.email,
        "user_id": user.id,
        "role": user.role.value,
        "type": "user"
    }
    
    access_token = create_access_token(
        data=token_data,
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES) 
    )
    
    refresh_token = create_refresh_token(data=token_data)

    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,
        secure=not settings.DEBUG,
        samesite="lax",
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,  
    )
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "message": "president logged in!",
        "user": {
            "id": user.id,
            "email": user.email,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "role": user.role.value,
            "is_active": user.is_active
        }
    }

# ========== SUPERVISOR LOGIN ==========
@authRouter.post("/supervisor/login", response_model=Token)
async def supervisor_login(
    form_data: LoginRequest,
    response : Response,
    db: AsyncSession = Depends(get_db),
):
    logger.info(f"supervisor data form: {form_data}")

    # Find user by email AND role (allow both SUPERVISOR and CHIEF_SUPERVISOR)
    result = await db.execute(
        select(User).where(
            User.email == form_data.email,
            User.role.in_([UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR])
        )
    )
    user = result.scalar_one_or_none()

    logger.info(f"found supervisor: {user}")

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="there is no supervisor by this credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify password using bcrypt (with backward compatibility for plain text)
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='wrong email or password',
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Upgrade password to bcrypt if it's still plain text
    await upgrade_password_if_needed(db, user, form_data.password)

    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. Please contact the administrator."
        )

    access_token = create_access_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    refresh_token = create_refresh_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        }
    )

    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,  # Prevents JavaScript access
        secure=not settings.DEBUG,  # HTTPS only in production
        samesite="lax",  # CSRF protection
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "message": "supervisor has logged in!",
        "user": {
            "id": user.id,
            "email": user.email,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "role": user.role.value,
            "is_active": user.is_active
        }
    }


# ========== TEACHER LOGIN ==========
@authRouter.post("/teacher/login", response_model=Token)
async def teacher_login(
    form_data: LoginRequest,
    response : Response,
    db: AsyncSession = Depends(get_db),
):
    logger.info(f"teacher login attempt: {form_data.email}")

    # Find user by email AND role
    result = await db.execute(
        select(User).where(
            User.email == form_data.email,
            User.role == UserRoleEnum.TEACHER
        )
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify password using bcrypt (with backward compatibility for plain text)
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Upgrade password to bcrypt if it's still plain text
    await upgrade_password_if_needed(db, user, form_data.password)

    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. Please contact the administrator."
        )

    # Get teacher details
    teacher_result = await db.execute(
        select(Teacher).where(Teacher.user_id == user.id)
    )
    teacher = teacher_result.scalar_one_or_none()

    access_token = create_access_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    refresh_token = create_refresh_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        }
    )

    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,
        secure=not settings.DEBUG,
        samesite="lax",
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "message": "teacher logged in successfully!",
        "user": {
            "id": user.id,
            "email": user.email,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "role": user.role.value,
            "is_active": user.is_active
        },
        "teacher": {
            "teacher_id": teacher.id if teacher else None,
            "first_name": user.firstname,
            "last_name": user.lastname,
            "riwaya": teacher.riwaya if teacher else None
        }
    }


# ========== GUARDIAN LOGIN ==========
@authRouter.post("/guardian/login", response_model=Token)
async def guardian_login(
    form_data: LoginRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    logger.info(f"guardian login attempt: {form_data.email}")

    # Find user by email AND role
    result = await db.execute(
        select(User).where(
            User.email == form_data.email,
            User.role == UserRoleEnum.GUARDIAN
        )
    )
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Verify password using bcrypt (with backward compatibility for plain text)
    if not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    # Upgrade password to bcrypt if it's still plain text
    await upgrade_password_if_needed(db, user, form_data.password)

    # Check if user is active
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive. Please contact the administrator."
        )

    # Get guardian details
    guardian_result = await db.execute(
        select(Guardian).where(Guardian.user_id == user.id)
    )
    guardian = guardian_result.scalar_one_or_none()

    access_token = create_access_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    refresh_token = create_refresh_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        }
    )

    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,
        secure=not settings.DEBUG,
        samesite="lax",
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "message": "guardian logged in successfully!",
        "user": {
            "id": user.id,
            "email": user.email,
            "firstname": user.firstname,
            "lastname": user.lastname,
            "role": user.role.value,
            "is_active": user.is_active
        },
        "guardian": {
            "guardian_id": guardian.id if guardian else None,
            "first_name": guardian.first_name if guardian else None,
            "last_name": guardian.last_name if guardian else None,
            "relationship": guardian.relationship_to_student if guardian else None
        } if guardian else None
    }


# ========== ADMIN LOGIN ==========
@authRouter.post("/admin/login", response_model=Token)
async def admin_login(
    form_data: AdminLoginReq,
    response : Response,
    db: AsyncSession = Depends(get_db)
):
    logger.info(f"admin login: {form_data}")
    
    result = await db.execute(
        select(Admin).where(Admin.user == form_data.user)  
    )
    admin = result.scalar_one_or_none()
    
    if not admin:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password - support both plain text (old) and hashed (new)
    is_valid_password = False
    
    # Check if password is hashed (starts with $2b$ for bcrypt)
    if admin.password.startswith('$2b$'):
        # Use bcrypt verification for hashed passwords
        is_valid_password = verify_password(form_data.password, admin.password)
    else:
        # Plain text comparison for legacy admins
        is_valid_password = (form_data.password == admin.password)
    
    if not is_valid_password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
        #  if not admin.is_active:
        #   raise HTTPException(
        #   status_code=status.HTTP_403_FORBIDDEN,
        #   detail="Admin account is inactive. your request is under review."
        # )
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    token_data = {
        "sub": admin.user,
        "admin_id": admin.id,
        "role": "admin",
        "type": "admin"
    }
    
    access_token = create_access_token(
        data=token_data,
        expires_delta=access_token_expires
    )
    
    refresh_token = create_refresh_token(data=token_data)

    logger.info(f"admin access token: {access_token}")

    response.set_cookie(
        key="access_token",
        value=f"Bearer {access_token}",
        httponly=True,  # Prevents JavaScript access
        secure=not settings.DEBUG,  # HTTPS only in production
        samesite="lax",  # CSRF protection
        max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "message" : "you are logged in as an admin !"
    }



# ========== GET CURRENT USER INFO ==========
@authRouter.get("/me")
async def get_current_user_info(
    current_user: User = Depends(get_current_user)
):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "firstname": current_user.firstname,
        "lastname": current_user.lastname,
        "role": current_user.role.value,
        "is_active": current_user.is_active,
        # Include president info if available
        "president": {
            "school_name": current_user.president.school_name,
            "phone_number": current_user.president.phone_number,
            "isVerified": current_user.president.isVerified
        } if current_user.president else None
    }


# ========== GET CURRENT ADMIN INFO ==========
@authRouter.get("/admin/me")
async def get_current_admin_info(
    current_admin = Depends(require_admin)
):
    logger.info(f"current admin: {current_admin}")

    return {
        "id": current_admin.id,
        "username": current_admin.user,
        "type": "admin"
    }



# ========== REFRESH TOKEN ==========
@authRouter.post("/token/refresh", response_model=RefreshTokenResponse)
async def refresh_token(
    refresh_request: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Refresh access token using a valid refresh token.
    Returns a new access token without requiring re-login.
    """
    # Decode and validate refresh token
    payload = decode_token(refresh_request.refresh_token)
    
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify token type
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Check if it's an admin token
    if payload.get("type") == "refresh" and payload.get("role") == "admin":
        # Admin token refresh
        admin_id = payload.get("admin_id")
        if not admin_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token payload",
            )
        
        # Verify admin still exists
        result = await db.execute(
            select(Admin).where(Admin.id == admin_id)
        )
        admin = result.scalar_one_or_none()
        
        if not admin:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Admin not found",
            )
        
        # Create new access token
        new_access_token = create_access_token(
            data={
                "sub": admin.user,
                "admin_id": admin.id,
                "role": "admin",
                "type": "admin"
            },
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        )
        
        return {
            "access_token": new_access_token,
            "token_type": "bearer"
        }
    
    # Regular user token refresh
    user_id = payload.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
        )
    
    # Verify user still exists and is active
    result = await db.execute(
        select(User).where(User.id == user_id)
    )
    user = result.scalar_one_or_none()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Account is inactive",
        )
    
    # Create new access token with same data as original
    new_access_token = create_access_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user"
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    return {
        "access_token": new_access_token,
        "token_type": "bearer"
    }


# ========== CHANGE PASSWORD ==========
@authRouter.post("/change-password", response_model=ChangePasswordResponse)
async def change_password(
    data: ChangePasswordRequest,
    current_user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Change password for the current authenticated user of any role:
    Admin, President, Supervisor, Teacher, Guardian, Student.
    """
    if data.confirm_password and data.new_password != data.confirm_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="كلمة المرور الجديدة وتأكيد كلمة المرور غير متطابقين"
        )

    if len(data.new_password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="كلمة المرور يجب أن لا تقل عن 6 أحرف"
        )

    # 1. Admin account
    if isinstance(current_user, Admin):
        is_correct = (data.current_password == current_user.password)
        if not is_correct:
            try:
                is_correct = verify_password(data.current_password, current_user.password)
            except Exception:
                pass
        if not is_correct:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="كلمة المرور الحالية غير صحيحة"
            )
        current_user.password = data.new_password
        await db.commit()
        await db.refresh(current_user)
        return {"message": "تم تغيير كلمة المرور بنجاح"}

    # 2. Standard User account (President, Supervisor, Teacher, Guardian, Student)
    if isinstance(current_user, User):
        if not verify_password(data.current_password, current_user.hashed_password):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="كلمة المرور الحالية غير صحيحة"
            )
        current_user.hashed_password = get_password_hash(data.new_password)
        await db.commit()
        await db.refresh(current_user)
        return {"message": "تم تغيير كلمة المرور بنجاح"}

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="مستخدم غير مصرح له"
    )
