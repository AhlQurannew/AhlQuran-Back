"""
Property-based tests for guardian read-only access enforcement

Feature: guardian-authentication-system
Property 13: Read-Only Access Enforcement
Validates: Requirements 6.6
"""
import pytest
import os
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from app.main import app
from app.db.base import Base
from app.models.user import User, UserRoleEnum
from app.core.security import get_password_hash, create_access_token


# Test database URL
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


# Feature: guardian-authentication-system, Property 13: Read-Only Access Enforcement
@pytest.mark.asyncio
async def test_guardian_cannot_create_student():
    """
    Property: For any guardian attempting to access modification endpoints (POST)
    for student data, the system should reject the request with a 403 Forbidden error.
    
    Validates: Requirements 6.6
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_create@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create JWT token for guardian
            access_token = create_access_token(
                data={
                    "sub": guardian_user.email,
                    "user_id": guardian_user.id,
                    "role": guardian_user.role.value
                }
            )
            
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            # Attempt to create a student via POST endpoint
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/students/",
                    json={
                        "personalInfo": {
                            "firstNameAr": "Test",
                            "lastNameAr": "Student",
                            "sex": "Male"
                        },
                        "accountInfo": {
                            "username": "teststudent@test.com",
                            "passcode": "password123"
                        }
                    },
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Verify 403 Forbidden status
        assert response.status_code == 403
        assert "forbidden" in response.json().get("detail", "").lower() or \
               "president" in response.json().get("detail", "").lower() or \
               "supervisor" in response.json().get("detail", "").lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_cannot_update_student():
    """
    Property: For any guardian attempting to access modification endpoints (PUT)
    for student data, the system should reject the request with a 403 Forbidden error.
    
    Validates: Requirements 6.6
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_update@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create JWT token for guardian
            access_token = create_access_token(
                data={
                    "sub": guardian_user.email,
                    "user_id": guardian_user.id,
                    "role": guardian_user.role.value
                }
            )
            
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            # Attempt to update a student via PUT endpoint (using arbitrary student_id)
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.put(
                    "/api/v1/students/999",
                    json={
                        "parent_name": "Updated Parent Name"
                    },
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Verify 403 Forbidden status
        assert response.status_code == 403
        assert "forbidden" in response.json().get("detail", "").lower() or \
               "president" in response.json().get("detail", "").lower() or \
               "supervisor" in response.json().get("detail", "").lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_cannot_delete_student():
    """
    Property: For any guardian attempting to access modification endpoints (DELETE)
    for student data, the system should reject the request with a 403 Forbidden error.
    
    Validates: Requirements 6.6
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_delete@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create JWT token for guardian
            access_token = create_access_token(
                data={
                    "sub": guardian_user.email,
                    "user_id": guardian_user.id,
                    "role": guardian_user.role.value
                }
            )
            
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            # Attempt to delete a student via DELETE endpoint (using arbitrary student_id)
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.delete(
                    "/api/v1/students/999",
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Verify 403 Forbidden status
        assert response.status_code == 403
        assert "forbidden" in response.json().get("detail", "").lower() or \
               "president" in response.json().get("detail", "").lower() or \
               "supervisor" in response.json().get("detail", "").lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_cannot_modify_attendance():
    """
    Property: For any guardian attempting to access modification endpoints (POST, PUT, DELETE)
    for attendance records, the system should reject the request with a 403 Forbidden error.
    
    Validates: Requirements 6.6
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_attendance@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create JWT token for guardian
            access_token = create_access_token(
                data={
                    "sub": guardian_user.email,
                    "user_id": guardian_user.id,
                    "role": guardian_user.role.value
                }
            )
            
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            # Attempt to create attendance via POST endpoint (using arbitrary student_id)
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/students/999/attendance",
                    json={
                        "date": "2024-01-01",
                        "status": "Present"
                    },
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Verify 403 Forbidden status
        assert response.status_code == 403
        assert "forbidden" in response.json().get("detail", "").lower() or \
               "president" in response.json().get("detail", "").lower() or \
               "supervisor" in response.json().get("detail", "").lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_cannot_modify_achievements():
    """
    Property: For any guardian attempting to access modification endpoints (POST, PUT, DELETE)
    for achievement records, the system should reject the request with a 403 Forbidden error.
    
    Validates: Requirements 6.6
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_achievement@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create JWT token for guardian
            access_token = create_access_token(
                data={
                    "sub": guardian_user.email,
                    "user_id": guardian_user.id,
                    "role": guardian_user.role.value
                }
            )
            
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            # Attempt to create achievement via POST endpoint (using arbitrary student_id)
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/students/999/achievements",
                    json={
                        "title": "Test Achievement",
                        "description": "Test Description"
                    },
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Verify 403 Forbidden status
        assert response.status_code == 403
        assert "forbidden" in response.json().get("detail", "").lower() or \
               "president" in response.json().get("detail", "").lower() or \
               "supervisor" in response.json().get("detail", "").lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
