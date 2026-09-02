"""
Simple tests for guardian authorization without database

Feature: guardian-authentication-system
Property 7: Role-Based Authorization
Validates: Requirements 2.4, 2.5, 7.8
"""
import pytest
from fastapi import HTTPException
from app.core.dependencies import require_guardian
from app.models.user import User, UserRoleEnum


# Unit tests for require_guardian function
@pytest.mark.asyncio
async def test_guardian_role_passes():
    """Guardian user should pass authorization."""
    user = User(
        id=1,
        firstname="Test",
        lastname="Guardian",
        email="guardian@test.com",
        hashed_password="hashed",
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    
    result = await require_guardian(current_user=user)
    assert result.id == user.id
    assert result.role == UserRoleEnum.GUARDIAN


@pytest.mark.asyncio
async def test_teacher_role_fails():
    """Teacher user should fail authorization with 403."""
    user = User(
        id=2,
        firstname="Test",
        lastname="Teacher",
        email="teacher@test.com",
        hashed_password="hashed",
        role=UserRoleEnum.TEACHER,
        is_active=True
    )
    
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=user)
    
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_student_role_fails():
    """Student user should fail authorization with 403."""
    user = User(
        id=3,
        firstname="Test",
        lastname="Student",
        email="student@test.com",
        hashed_password="hashed",
        role=UserRoleEnum.STUDENT,
        is_active=True
    )
    
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=user)
    
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_president_role_fails():
    """President user should fail authorization with 403."""
    user = User(
        id=4,
        firstname="Test",
        lastname="President",
        email="president@test.com",
        hashed_password="hashed",
        role=UserRoleEnum.PRESIDENT,
        is_active=True
    )
    
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=user)
    
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()


@pytest.mark.asyncio
async def test_supervisor_role_fails():
    """Supervisor user should fail authorization with 403."""
    user = User(
        id=5,
        firstname="Test",
        lastname="Supervisor",
        email="supervisor@test.com",
        hashed_password="hashed",
        role=UserRoleEnum.SUPERVISOR,
        is_active=True
    )
    
    with pytest.raises(HTTPException) as exc_info:
        await require_guardian(current_user=user)
    
    assert exc_info.value.status_code == 403
    assert "guardian privileges" in exc_info.value.detail.lower()
