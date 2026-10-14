from fastapi import APIRouter, Depends, HTTPException, status, Response
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from datetime import timedelta
import logging

from app.db.session import get_db
from app.models.admin import Admin
from app.models.user import User, UserRoleEnum
from app.models.president import President
from app.models.teacher import Teacher
from app.models.guardian import Guardian
from app.models.supervisor import Supervisor
from app.models.student import Student
from app.models.account_preference import AccountPreference
from app.core.security import create_access_token, create_refresh_token, verify_password, upgrade_password_if_needed, get_password_hash, is_password_hashed, decode_token
from app.core.config import settings
from app.schemas.auth import (
    AdminLoginReq,
    RegisterRequest, 
    RegisterResponse,
    LoginRequest,
    Token,
    RefreshTokenRequest,
    RefreshTokenResponse
)
from app.core.dependencies import get_current_user, require_admin
from pydantic import BaseModel, ConfigDict, Field
from zoneinfo import available_timezones


class SettingsProfilePatch(BaseModel):
    model_config = ConfigDict(extra="forbid")
    firstname: str | None = Field(default=None, min_length=1, max_length=50)
    lastname: str | None = Field(default=None, min_length=1, max_length=50)
    school_name: str | None = Field(default=None, min_length=1, max_length=100)
    phone_number: str | None = Field(default=None, max_length=20)
    contact_email: str | None = Field(default=None, max_length=255)
    job: str | None = Field(default=None, max_length=100)
    address: str | None = Field(default=None, max_length=255)
    username: str | None = Field(default=None, min_length=3, max_length=100)


class SettingsPreferencesPatch(BaseModel):
    model_config = ConfigDict(extra="forbid")
    timezone: str | None = Field(default=None, max_length=64)
    reduce_motion: bool | None = None


class PasswordChangeRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=8, max_length=128)

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

    logger.info("President login succeeded for user_id=%s", user.id)

    # Create access token and refresh token
    token_data = {
        "email": user.email,
        "user_id": user.id,
        "role": user.role.value,
        "type": "user",
        "ver": user.auth_version
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
    logger.info("Supervisor login attempt")

    # Find user by email AND role
    result = await db.execute(
        select(User).where(
            User.email == form_data.email,
            User.role.in_((UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR)),
        )
    )
    user = result.scalar_one_or_none()

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
            "type": "user",
            "ver": user.auth_version
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    refresh_token = create_refresh_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user",
            "ver": user.auth_version
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
    logger.info("Teacher login attempt")

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
            "type": "user",
            "ver": user.auth_version
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    refresh_token = create_refresh_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user",
            "ver": user.auth_version
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


# ========== STUDENT LOGIN ==========
@authRouter.post("/student/login", response_model=Token)
async def student_login(
    form_data: LoginRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.email == form_data.email, User.role == UserRoleEnum.STUDENT))
    user = result.scalar_one_or_none()
    if user is None or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid email or password", headers={"WWW-Authenticate": "Bearer"})
    await upgrade_password_if_needed(db, user, form_data.password)
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account is inactive. Please contact your school administrator.")

    token_data = {"email": user.email, "user_id": user.id, "role": user.role.value, "type": "user", "ver": user.auth_version}
    access_token = create_access_token(token_data, expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    refresh_token = create_refresh_token(data=token_data)
    response.set_cookie(key="access_token", value=f"Bearer {access_token}", httponly=True, secure=not settings.DEBUG, samesite="lax", max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "message": "student logged in",
        "user": {"id": user.id, "email": user.email, "firstname": user.firstname, "lastname": user.lastname, "role": user.role.value, "is_active": user.is_active},
    }


# ========== GUARDIAN LOGIN ==========
@authRouter.post("/guardian/login", response_model=Token)
async def guardian_login(
    form_data: LoginRequest,
    response: Response,
    db: AsyncSession = Depends(get_db),
):
    logger.info("Guardian login attempt")

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
            "type": "user",
            "ver": user.auth_version
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    refresh_token = create_refresh_token(
        data={
            "email": user.email,
            "user_id": user.id,
            "role": user.role.value,
            "type": "user",
            "ver": user.auth_version
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
    logger.info("Admin login attempt")
    
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
    
    # Verify password
    if not verify_password(form_data.password, admin.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not is_password_hashed(admin.password_hash):
        admin.password_hash = get_password_hash(form_data.password)
        await db.commit()
    
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
        "type": "admin",
        "ver": admin.auth_version
    }
    
    access_token = create_access_token(
        data=token_data,
        expires_delta=access_token_expires
    )
    
    refresh_token = create_refresh_token(data=token_data)

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
            "isVerified": current_user.president.is_verified
        } if current_user.president else None
    }


# ========== GET CURRENT ADMIN INFO ==========
@authRouter.get("/admin/me")
async def get_current_admin_info(
    current_admin = Depends(require_admin)
):
    logger.info("Current administrator requested")

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

        if payload.get("ver", 0) != admin.auth_version:
            raise HTTPException(status_code=401, detail="Session expired; sign in again")
        
        # Create new access token
        new_access_token = create_access_token(
            data={
                "sub": admin.user,
                "admin_id": admin.id,
                "role": "admin",
                "type": "admin",
                "ver": admin.auth_version,
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

    if payload.get("ver", 0) != user.auth_version:
        raise HTTPException(status_code=401, detail="Session expired; sign in again")
    
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
            "type": "user",
            "ver": user.auth_version,
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    return {
        "access_token": new_access_token,
        "token_type": "bearer"
    }


def _account_preference_query(account):
    return AccountPreference.user_id == account.id if isinstance(account, User) else AccountPreference.admin_id == account.id


async def _get_account_preferences(db: AsyncSession, account: User | Admin) -> AccountPreference | None:
    result = await db.execute(select(AccountPreference).where(_account_preference_query(account)))
    return result.scalar_one_or_none()


def _profile_payload(account: User | Admin) -> dict:
    if isinstance(account, Admin):
        return {"username": account.user}

    profile = {
        "firstname": account.firstname,
        "lastname": account.lastname,
        "login_email": account.email,
        "is_active": account.is_active,
    }
    if account.role == UserRoleEnum.PRESIDENT:
        president = account.president
        profile.update({
            "school_name": president.school_name if president else None,
            "phone_number": president.phone_number if president else None,
            "is_verified": president.is_verified if president else False,
        })
    elif account.role in (UserRoleEnum.SUPERVISOR, UserRoleEnum.CHIEF_SUPERVISOR):
        profile["school_name"] = account.supervisor.president.school_name if account.supervisor and account.supervisor.president else None
    elif account.role == UserRoleEnum.TEACHER:
        teacher = account.teacher
        profile.update({
            "riwaya": teacher.riwaya if teacher else None,
            "hire_date": teacher.hire_date.isoformat() if teacher and teacher.hire_date else None,
            "school_name": teacher.president.school_name if teacher and teacher.president else None,
        })
    elif account.role == UserRoleEnum.GUARDIAN:
        guardian = account.guardian
        profile.update({
            "phone_number": guardian.phone_number if guardian else None,
            "contact_email": guardian.email if guardian else None,
            "job": guardian.job if guardian else None,
            "address": guardian.address if guardian else None,
            "relationship": guardian.relationship_to_student if guardian else None,
            "date_of_birth": guardian.date_of_birth if guardian else None,
            "linked_student": ({"id": guardian.student.id, "name": f"{guardian.student.user.firstname} {guardian.student.user.lastname}"} if guardian and guardian.student and guardian.student.user else None),
        })
    elif account.role == UserRoleEnum.STUDENT:
        student = account.student
        profile.update({
            "school_name": student.school_name if student else None,
            "academic_level": student.academic_level if student else None,
            "grade": student.grade if student else None,
            "enrollment_date": student.enrollment_date.isoformat() if student and student.enrollment_date else None,
        })
    return profile


@authRouter.get("/settings")
async def get_account_settings(
    account=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if isinstance(account, User):
        result = await db.execute(
            select(User).options(
                selectinload(User.president),
                selectinload(User.supervisor).selectinload(Supervisor.president),
                selectinload(User.teacher).selectinload(Teacher.president),
                selectinload(User.guardian).selectinload(Guardian.student).selectinload(Student.user),
                selectinload(User.student),
            ).where(User.id == account.id)
        )
        account = result.scalar_one()
    preference = await _get_account_preferences(db, account)
    return {
        "role": "ADMIN" if isinstance(account, Admin) else account.role.value,
        "profile": _profile_payload(account),
        "preferences": {
            "timezone": preference.timezone if preference else "Africa/Algiers",
            "reduce_motion": preference.reduce_motion if preference else False,
        },
    }


@authRouter.patch("/settings/profile")
async def update_account_profile(
    changes: SettingsProfilePatch,
    account=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    values = changes.model_dump(exclude_unset=True)
    for field in ("firstname", "lastname", "school_name", "username"):
        if field in values and values[field] is not None:
            values[field] = values[field].strip()
            if not values[field]:
                raise HTTPException(status_code=422, detail=f"{field} cannot be blank")
    if isinstance(account, Admin):
        if set(values) - {"username"}:
            raise HTTPException(status_code=403, detail="Only the administrator username can be changed here")
        if "username" in values:
            duplicate = await db.execute(select(Admin.id).where(Admin.user == values["username"], Admin.id != account.id))
            if duplicate.scalar_one_or_none() is not None:
                raise HTTPException(status_code=409, detail="Username is already in use")
            account.user = values["username"].strip()
    else:
        role = account.role
        fields = {"firstname", "lastname"}
        if role == UserRoleEnum.PRESIDENT:
            fields |= {"school_name", "phone_number"}
        elif role == UserRoleEnum.GUARDIAN:
            fields |= {"phone_number", "contact_email", "job", "address"}
        if set(values) - fields:
            raise HTTPException(status_code=403, detail="One or more profile fields are read-only for this role")
        for field in ("firstname", "lastname"):
            if field in values:
                setattr(account, field, values[field].strip())
                if role == UserRoleEnum.GUARDIAN and account.guardian:
                    setattr(account.guardian, "first_name" if field == "firstname" else "last_name", values[field].strip())
        if role == UserRoleEnum.PRESIDENT and account.president:
            for field in ("school_name", "phone_number"):
                if field in values:
                    setattr(account.president, field, values[field].strip() or None)
        if role == UserRoleEnum.GUARDIAN and account.guardian:
            for field, target in (("phone_number", "phone_number"), ("contact_email", "email"), ("job", "job"), ("address", "address")):
                if field in values:
                    setattr(account.guardian, target, values[field].strip() or None)
    await db.commit()
    refreshed = await db.execute(
        select(User).options(
            selectinload(User.president),
            selectinload(User.supervisor).selectinload(Supervisor.president),
            selectinload(User.teacher).selectinload(Teacher.president),
            selectinload(User.guardian).selectinload(Guardian.student).selectinload(Student.user),
            selectinload(User.student),
        ).where(User.id == account.id)
    ) if isinstance(account, User) else None
    if refreshed is not None:
        account = refreshed.scalar_one()
    return {"profile": _profile_payload(account)}


@authRouter.patch("/settings/preferences")
async def update_account_preferences(
    changes: SettingsPreferencesPatch,
    account=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    values = changes.model_dump(exclude_unset=True)
    if not values:
        raise HTTPException(status_code=422, detail="At least one preference is required")
    if "timezone" in values and values["timezone"] not in available_timezones():
        raise HTTPException(status_code=422, detail="Unknown timezone")
    preference = await _get_account_preferences(db, account)
    if preference is None:
        preference = AccountPreference(user_id=account.id) if isinstance(account, User) else AccountPreference(admin_id=account.id)
        db.add(preference)
    for field, value in values.items():
        setattr(preference, field, value)
    await db.commit()
    return {"timezone": preference.timezone, "reduce_motion": preference.reduce_motion}


@authRouter.post("/settings/password")
async def change_account_password(
    request: PasswordChangeRequest,
    response: Response,
    account=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    password_field = "password_hash" if isinstance(account, Admin) else "hashed_password"
    if not verify_password(request.current_password, getattr(account, password_field)):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    if verify_password(request.new_password, getattr(account, password_field)):
        raise HTTPException(status_code=400, detail="New password must differ from the current password")
    setattr(account, password_field, get_password_hash(request.new_password))
    account.auth_version += 1
    await db.commit()

    if isinstance(account, Admin):
        token_data = {"sub": account.user, "admin_id": account.id, "role": "admin", "type": "admin", "ver": account.auth_version}
    else:
        token_data = {"email": account.email, "user_id": account.id, "role": account.role.value, "type": "user", "ver": account.auth_version}
    access_token = create_access_token(token_data, expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES))
    refresh_token_value = create_refresh_token(token_data)
    response.set_cookie(key="access_token", value=f"Bearer {access_token}", httponly=True, secure=not settings.DEBUG, samesite="lax", max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60)
    return {"access_token": access_token, "refresh_token": refresh_token_value, "token_type": "bearer"}
