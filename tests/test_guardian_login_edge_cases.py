"""
Unit tests for guardian login edge cases
Feature: guardian-authentication-system
Task: 3.7 Write unit tests for edge cases
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from datetime import datetime, timezone
import os

from app.main import app
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.president import President
from app.core.security import get_password_hash
from app.db.base import Base

# Test database URL
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


@pytest.mark.asyncio
async def test_inactive_guardian_account_returns_403():
    """
    Test that an inactive guardian account returns 403 Forbidden.
    
    Edge case: Guardian user exists with correct credentials but is_active=False
    Expected: 403 Forbidden with appropriate error message
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create president for multi-tenancy
            president_user = User(
                firstname="President",
                lastname="Test",
                email="president_inactive@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name="Test School",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create INACTIVE guardian user
            inactive_user = User(
                firstname="Inactive",
                lastname="Guardian",
                email="inactive_guardian@test.com",
                hashed_password=get_password_hash("correct_password"),
                role=UserRoleEnum.GUARDIAN,
                is_active=False  # Account is inactive
            )
            db_session.add(inactive_user)
            await db_session.flush()
            
            # Create guardian record
            guardian = Guardian(
                user_id=inactive_user.id,
                president_id=president.id,
                first_name="Inactive",
                last_name="Guardian",
                relationship_to_student="Father",
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={
                        "email": "inactive_guardian@test.com",
                        "password": "correct_password"
                    }
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 403, f"Expected 403, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        assert "detail" in response_data
        assert "inactive" in response_data["detail"].lower(), \
            f"Error message should mention inactive account, got: {response_data['detail']}"
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_nonexistent_email_returns_401():
    """
    Test that a non-existent email returns 401 Unauthorized.
    
    Edge case: Email doesn't exist in the database
    Expected: 401 Unauthorized with generic error message (security best practice)
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={
                        "email": "nonexistent_guardian@test.com",
                        "password": "any_password"
                    }
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 401, f"Expected 401, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        assert "detail" in response_data
        # Should return generic error message for security
        assert "invalid" in response_data["detail"].lower() or "password" in response_data["detail"].lower(), \
            f"Error message should be generic, got: {response_data['detail']}"
        
        # Should NOT reveal that email doesn't exist (security best practice)
        assert "not found" not in response_data["detail"].lower()
        assert "exist" not in response_data["detail"].lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_wrong_password_returns_401():
    """
    Test that a wrong password returns 401 Unauthorized.
    
    Edge case: Guardian user exists but password is incorrect
    Expected: 401 Unauthorized with generic error message
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create president for multi-tenancy
            president_user = User(
                firstname="President",
                lastname="Test",
                email="president_wrong_pwd@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name="Test School",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create guardian user with known password
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_wrong_pwd@test.com",
                hashed_password=get_password_hash("correct_password"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create guardian record
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Test",
                last_name="Guardian",
                relationship_to_student="Mother",
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={
                        "email": "guardian_wrong_pwd@test.com",
                        "password": "wrong_password"  # Incorrect password
                    }
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 401, f"Expected 401, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        assert "detail" in response_data
        # Should return generic error message for security
        assert "invalid" in response_data["detail"].lower() or "password" in response_data["detail"].lower(), \
            f"Error message should mention invalid credentials, got: {response_data['detail']}"
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_missing_guardian_record_returns_none():
    """
    Test that a missing guardian record returns None in the guardian field.
    
    Edge case: User has GUARDIAN role but no Guardian record in database
    Expected: 200 OK with guardian=None (data inconsistency handled gracefully)
    
    Note: This is a data integrity issue that should be prevented at creation time,
    but the login endpoint handles it gracefully by returning None for guardian details.
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create president for multi-tenancy
            president_user = User(
                firstname="President",
                lastname="Test",
                email="president_no_guardian@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name="Test School",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create guardian user WITHOUT creating Guardian record (data inconsistency)
            guardian_user = User(
                firstname="NoRecord",
                lastname="Guardian",
                email="guardian_no_record@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.commit()
            
            # Note: No Guardian record created - this is the edge case
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={
                        "email": "guardian_no_record@test.com",
                        "password": "password123"
                    }
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        
        # Verify JWT token is still returned (authentication succeeded)
        assert "access_token" in response_data
        assert response_data["access_token"] is not None
        
        # Verify user info is present
        assert "user" in response_data
        assert response_data["user"]["email"] == "guardian_no_record@test.com"
        assert response_data["user"]["role"] == "GUARDIAN"
        
        # Verify guardian field is not present or is None (graceful handling of missing record)
        # The implementation returns the guardian key only if guardian exists
        if "guardian" in response_data:
            assert response_data["guardian"] is None, \
                "Guardian field should be None when Guardian record doesn't exist"
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
