"""
Property-based tests for guardian authorization

Feature: guardian-authentication-system
Property 7: Role-Based Authorization
Validates: Requirements 2.4, 2.5, 7.8
"""
import pytest
from fastapi import HTTPException
from app.core.dependencies import require_guardian
from app.models.user import User, UserRoleEnum
from app.core.security import get_password_hash


# Feature: guardian-authentication-system, Property 7: Role-Based Authorization
@pytest.mark.asyncio
async def test_non_guardian_roles_rejected(db_session):
    """
    Property: For any user without the GUARDIAN role (teacher, student, president, supervisor),
    attempting to access guardian-only endpoints should result in a 403 Forbidden error.
    
    Validates: Requirements 2.4, 2.5
    """
    # Use fixed test data
    firstname = "TestUser"
    lastname = "NonGuardian"
    email = "nonguardian@test.com"
    role = UserRoleEnum.TEACHER
    
    # Create user with non-guardian role
    user = User(
        firstname=firstname,
        lastname=lastname,
        email=email,
        hashed_password=get_password_hash("password123"),
        role=role,
        is_active=True
    )
    db_session.add(user)
    await db_session.flush()
    
    # Attempt to use require_guardian dependency
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=user)
    
    # Verify 403 Forbidden status
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_guardian_role_authorized(db_session):
    """
    Property: For any user with the GUARDIAN role, the require_guardian dependency
    should successfully authorize and return the user object.
    
    Validates: Requirements 2.4, 2.5, 7.8
    """
    # Use fixed test data
    firstname = "TestGuardian"
    lastname = "Authorized"
    email = "authorized_guardian@test.com"
    
    # Create user with guardian role
    user = User(
        firstname=firstname,
        lastname=lastname,
        email=email,
        hashed_password=get_password_hash("password123"),
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    db_session.add(user)
    await db_session.flush()
    
    # Use require_guardian dependency
    result = await require_guardian(current_user=user)
    
    # Verify user is returned
    assert result is not None
    assert result.id == user.id
    assert result.role == UserRoleEnum.GUARDIAN
    assert result.email == email


# Unit tests for specific edge cases
@pytest.mark.asyncio
async def test_guardian_user_passes_authorization(guardian_user):
    """
    Unit test: Guardian user should pass authorization check.
    """
    result = await require_guardian(current_user=guardian_user)
    assert result.id == guardian_user.id
    assert result.role == UserRoleEnum.GUARDIAN


@pytest.mark.asyncio
async def test_teacher_user_fails_authorization(teacher_user):
    """
    Unit test: Teacher user should fail authorization check with 403.
    """
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=teacher_user)
    
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_student_user_fails_authorization(student_user):
    """
    Unit test: Student user should fail authorization check with 403.
    """
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=student_user)
    
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()
