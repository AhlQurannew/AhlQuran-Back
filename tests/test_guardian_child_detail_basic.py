"""
Basic test for guardian child detail endpoint
Feature: guardian-authentication-system
Task: 7.1 Create get_my_child_detail function
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
from app.models.student import Student
from app.models.president import President
from app.core.security import get_password_hash, create_access_token
from app.db.base import Base

# Test database URL
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


@pytest.mark.asyncio
async def test_guardian_can_access_linked_child_detail():
    """
    Test that a guardian can successfully access details of their linked child.
    
    Expected: 200 OK with complete student details
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
                email="president_detail@test.com",
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
            
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_detail@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create student
            student_user = User(
                firstname="Test",
                lastname="Student",
                email="student_detail@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.STUDENT,
                is_active=True
            )
            db_session.add(student_user)
            await db_session.flush()
            
            student = Student(
                user_id=student_user.id,
                president_id=president.id,
                enrollment_date=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(student)
            await db_session.flush()
            
            # Create guardian record linking to student
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Test",
                last_name="Guardian",
                relationship_to_student="Father",
                student_id=student.id,
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
            
            student_id = student.id
        
        # Create JWT token for guardian
        token_data = {
            "sub": "guardian_detail@test.com",
            "user_id": guardian_user.id,
            "role": "GUARDIAN"
        }
        access_token = create_access_token(data=token_data)
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student_id}",
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        
        # Verify student details are returned
        assert "id" in response_data
        assert response_data["id"] == student_id
        assert "personalInfo" in response_data
        assert "accountInfo" in response_data
        assert "contactInfo" in response_data
        assert "guardian" in response_data
        assert "lectures" in response_data
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_cannot_access_unlinked_child():
    """
    Test that a guardian cannot access details of a student not linked to them.
    
    Expected: 403 Forbidden
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
                email="president_unlinked@test.com",
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
            
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_unlinked@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create two students
            student1_user = User(
                firstname="Student1",
                lastname="Test",
                email="student1_unlinked@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.STUDENT,
                is_active=True
            )
            db_session.add(student1_user)
            await db_session.flush()
            
            student1 = Student(
                user_id=student1_user.id,
                president_id=president.id,
                enrollment_date=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(student1)
            await db_session.flush()
            
            student2_user = User(
                firstname="Student2",
                lastname="Test",
                email="student2_unlinked@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.STUDENT,
                is_active=True
            )
            db_session.add(student2_user)
            await db_session.flush()
            
            student2 = Student(
                user_id=student2_user.id,
                president_id=president.id,
                enrollment_date=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(student2)
            await db_session.flush()
            
            # Link guardian only to student1
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Test",
                last_name="Guardian",
                relationship_to_student="Father",
                student_id=student1.id,
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
            
            student2_id = student2.id
        
        # Create JWT token for guardian
        token_data = {
            "sub": "guardian_unlinked@test.com",
            "user_id": guardian_user.id,
            "role": "GUARDIAN"
        }
        access_token = create_access_token(data=token_data)
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Try to access student2 (not linked to guardian)
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student2_id}",
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 403, f"Expected 403, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        assert "detail" in response_data
        assert "access" in response_data["detail"].lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_cannot_access_nonexistent_student():
    """
    Test that requesting a non-existent student returns 404.
    
    Expected: 404 Not Found
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
                email="president_nonexist@test.com",
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
            
            # Create guardian user
            guardian_user = User(
                firstname="Test",
                lastname="Guardian",
                email="guardian_nonexist@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create guardian record (without linking to any student)
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Test",
                last_name="Guardian",
                relationship_to_student="Father",
                student_id=None,
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
        
        # Create JWT token for guardian
        token_data = {
            "sub": "guardian_nonexist@test.com",
            "user_id": guardian_user.id,
            "role": "GUARDIAN"
        }
        access_token = create_access_token(data=token_data)
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Try to access non-existent student (ID 99999)
                response = await client.get(
                    "/api/v1/guardians/my-children/99999",
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 404, f"Expected 404, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        assert "detail" in response_data
        assert "not found" in response_data["detail"].lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
