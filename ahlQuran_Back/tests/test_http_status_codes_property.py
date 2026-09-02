"""
Property-based test for HTTP status code correctness
Feature: guardian-authentication-system, Property 15: HTTP Status Code Correctness
"""
import pytest
import os
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text
from app.db.base import Base
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.president import President
from app.core.security import get_password_hash, create_access_token
from app.main import app
from datetime import datetime, timezone
import time


# Test database URL - use PostgreSQL test database in Docker
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


# Feature: guardian-authentication-system, Property 15: HTTP Status Code Correctness
@pytest.mark.asyncio
async def test_http_status_code_correctness_property():
    """
    Property 15: HTTP Status Code Correctness
    
    For any guardian endpoint response, the HTTP status code should be appropriate:
    - 200 for successful requests
    - 401 for authentication failures
    - 403 for authorization failures
    - 404 for not found resources
    
    Validates: Requirements 8.7
    
    This test verifies that all guardian endpoints return correct HTTP status codes
    for various scenarios: successful operations, authentication failures, authorization
    failures, and resource not found errors.
    """
    # Create a fresh database engine and session for this test
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    async_session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    unique_suffix = str(int(time.time() * 1000000))
    test_guardian_email = f"status_test_{unique_suffix}@test.com"
    test_teacher_email = f"teacher_{unique_suffix}@test.com"
    
    try:
        # Ensure tables exist
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        # Setup test data
        guardian_user_id = None
        teacher_user_id = None
        student_id = None
        president_id = None
        
        async with async_session_factory() as db_session:
            # Create president for multi-tenancy
            president_user = User(
                firstname="President",
                lastname="Test",
                email=f"president_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name=f"Test School {unique_suffix}",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            president_id = president.id
            
            # Create guardian user
            guardian_user = User(
                firstname="StatusTest",
                lastname="Guardian",
                email=test_guardian_email,
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            guardian_user_id = guardian_user.id
            
            # Create teacher user (for authorization failure test)
            teacher_user = User(
                firstname="Teacher",
                lastname="Test",
                email=test_teacher_email,
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.TEACHER,
                is_active=True
            )
            db_session.add(teacher_user)
            await db_session.flush()
            teacher_user_id = teacher_user.id
            
            # Create student
            student_user = User(
                firstname="Student",
                lastname="Child",
                email=f"student_{unique_suffix}@test.com",
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
                created_by_id=president_user.id,
                parent_name="StatusTest Guardian",
                parent_phone="1234567890",
                guardian_email=test_guardian_email,
                sex="Male",
                date_of_birth="2010-01-01",
                academic_level="Elementary",
                grade="Grade 1",
                school_name="Test School"
            )
            db_session.add(student)
            await db_session.flush()
            student_id = student.id
            
            # Create guardian record
            guardian_record = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="StatusTest",
                last_name="Guardian",
                relationship_to_student="Parent",
                student_id=student.id,
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian_record)
            
            await db_session.commit()
        
        # Create JWT tokens
        guardian_token = create_access_token(
            data={
                "sub": test_guardian_email,
                "user_id": guardian_user_id,
                "role": "GUARDIAN"
            }
        )
        
        teacher_token = create_access_token(
            data={
                "sub": test_teacher_email,
                "user_id": teacher_user_id,
                "role": "TEACHER"
            }
        )
        
        # Setup database dependency override
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Test 1: 200 OK for successful guardian login
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={"email": test_guardian_email, "password": "password123"}
                )
                assert response.status_code == 200, \
                    f"Successful login should return 200, got {response.status_code}"
                
                # Test 2: 401 Unauthorized for invalid credentials
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={"email": test_guardian_email, "password": "wrongpassword"}
                )
                assert response.status_code == 401, \
                    f"Invalid credentials should return 401, got {response.status_code}"
                
                # Test 3: 401 Unauthorized for non-existent email
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={"email": "nonexistent@test.com", "password": "password123"}
                )
                assert response.status_code == 401, \
                    f"Non-existent email should return 401, got {response.status_code}"
                
                # Test 4: 200 OK for successful get_my_children request
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": guardian_token}
                )
                assert response.status_code == 200, \
                    f"Successful get_my_children should return 200, got {response.status_code}"
                
                # Test 5: 401 Unauthorized for missing token
                response = await client.get(
                    "/api/v1/guardians/my-children"
                )
                assert response.status_code == 401, \
                    f"Missing token should return 401, got {response.status_code}"
                
                # Test 6: 401 Unauthorized for invalid token
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": "invalid_token"}
                )
                assert response.status_code == 401, \
                    f"Invalid token should return 401, got {response.status_code}"
                
                # Test 7: 403 Forbidden for wrong role (teacher accessing guardian endpoint)
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": teacher_token}
                )
                assert response.status_code == 403, \
                    f"Wrong role should return 403, got {response.status_code}"
                
                # Test 8: 200 OK for successful get_my_child_detail request
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student_id}",
                    cookies={"access_token": guardian_token}
                )
                assert response.status_code == 200, \
                    f"Successful get_my_child_detail should return 200, got {response.status_code}"
                
                # Test 9: 404 Not Found for non-existent student
                non_existent_id = 999999
                response = await client.get(
                    f"/api/v1/guardians/my-children/{non_existent_id}",
                    cookies={"access_token": guardian_token}
                )
                assert response.status_code == 404, \
                    f"Non-existent student should return 404, got {response.status_code}"
                
                # Test 10: 401 Unauthorized for get_my_child_detail without token
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student_id}"
                )
                assert response.status_code == 401, \
                    f"Missing token on detail endpoint should return 401, got {response.status_code}"
                
                # Test 11: 403 Forbidden for teacher accessing child detail
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student_id}",
                    cookies={"access_token": teacher_token}
                )
                assert response.status_code == 403, \
                    f"Teacher accessing child detail should return 403, got {response.status_code}"
        
        finally:
            app.dependency_overrides.clear()
        
        # Cleanup
        async with async_session_factory() as cleanup_session:
            await cleanup_session.execute(text(f"DELETE FROM guardians WHERE user_id = {guardian_user_id}"))
            await cleanup_session.execute(text(f"DELETE FROM students WHERE id = {student_id}"))
            await cleanup_session.execute(text(f"DELETE FROM presidents WHERE id = {president_id}"))
            await cleanup_session.execute(text(f"DELETE FROM users WHERE email LIKE '%{unique_suffix}%'"))
            await cleanup_session.commit()
    
    finally:
        await engine.dispose()
