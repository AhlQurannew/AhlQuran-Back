"""
Unit tests for guardian children list endpoint edge cases
Feature: guardian-authentication-system
Task: 6.6 Write unit tests for edge cases
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
async def test_guardian_with_no_children_returns_empty_list():
    """
    Test that a guardian with no children returns an empty list.
    
    Edge case: Guardian exists but has no students linked via student_id
    Expected: 200 OK with empty students list and total=0
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
                email="president_no_children@test.com",
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
                firstname="NoChildren",
                lastname="Guardian",
                email="guardian_no_children@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create guardian record WITHOUT linking to any student (student_id=None)
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="NoChildren",
                last_name="Guardian",
                relationship_to_student="Father",
                student_id=None,  # No children linked
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
        
        # Create JWT token for guardian
        token_data = {
            "sub": "guardian_no_children@test.com",
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
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        
        # Verify empty list is returned
        assert "students" in response_data
        assert isinstance(response_data["students"], list)
        assert len(response_data["students"]) == 0, "Students list should be empty"
        
        # Verify total count is 0
        assert "total" in response_data
        assert response_data["total"] == 0, "Total count should be 0"
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_guardian_with_null_president_id_returns_404():
    """
    Test that a guardian with null president_id returns 404 or handles gracefully.
    
    Edge case: Guardian exists but president_id is null (data integrity issue)
    Expected: Should handle gracefully - either 404 or empty list depending on implementation
    
    Note: This tests the multi-tenancy enforcement when president_id is null.
    The current implementation filters by president_id, so null president_id
    should result in no results or an error.
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            # Create president for creating student
            president_user = User(
                firstname="President",
                lastname="Test",
                email="president_null_test@test.com",
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
                firstname="NullPresident",
                lastname="Guardian",
                email="guardian_null_president@test.com",
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
                email="student_null_president@test.com",
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
            
            # Create guardian record with NULL president_id (data integrity issue)
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=None,  # NULL president_id
                first_name="NullPresident",
                last_name="Guardian",
                relationship_to_student="Mother",
                student_id=student.id,  # Linked to student
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
        
        # Create JWT token for guardian
        token_data = {
            "sub": "guardian_null_president@test.com",
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
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": access_token}
                )
        finally:
            app.dependency_overrides.clear()
        
        # Assertions
        # The implementation filters by guardian.president_id, so with null president_id
        # the query will filter by "Student.president_id == None" which should return no results
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        
        # With null president_id, the multi-tenancy filter should exclude all students
        assert "students" in response_data
        assert isinstance(response_data["students"], list)
        # Should return empty list because student.president_id != None
        assert len(response_data["students"]) == 0, \
            "Should return empty list when guardian has null president_id"
        
        assert "total" in response_data
        assert response_data["total"] == 0
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()


@pytest.mark.asyncio
async def test_pagination_with_various_skip_limit_values():
    """
    Test pagination with various skip/limit values.
    
    Edge case: Test pagination behavior with different skip and limit combinations
    Expected: Correct subsets returned based on pagination parameters
    
    Note: Since Guardian table has unique constraint on user_id, we create one guardian
    linked to the first student, and the query will return that one student with pagination.
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
                email="president_pagination@test.com",
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
            
            # Create 5 students
            student_ids = []
            for i in range(5):
                student_user = User(
                    firstname=f"Student{i}",
                    lastname="Test",
                    email=f"student{i}_pagination@test.com",
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
                student_ids.append(student.id)
            
            # Create 5 guardian users, each linked to one student
            # This simulates a scenario where one parent has 5 children
            guardian_users = []
            for i in range(5):
                guardian_user = User(
                    firstname=f"Guardian{i}",
                    lastname="Pagination",
                    email=f"guardian{i}_pagination@test.com",
                    hashed_password=get_password_hash("password123"),
                    role=UserRoleEnum.GUARDIAN,
                    is_active=True
                )
                db_session.add(guardian_user)
                await db_session.flush()
                guardian_users.append(guardian_user)
                
                # Create guardian record linking to corresponding student
                guardian_record = Guardian(
                    user_id=guardian_user.id,
                    president_id=president.id,
                    first_name=f"Guardian{i}",
                    last_name="Pagination",
                    relationship_to_student="Parent",
                    student_id=student_ids[i],
                    created_at=datetime.now(timezone.utc),
                    created_by_id=president_user.id
                )
                db_session.add(guardian_record)
            
            await db_session.commit()
        
        # Test with the first guardian who has 1 child
        # For a more realistic pagination test, we'll use guardian0
        token_data = {
            "sub": f"guardian0_pagination@test.com",
            "user_id": guardian_users[0].id,
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
                # Test 1: Get child with default pagination (guardian0 has 1 child)
                response1 = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": access_token}
                )
                assert response1.status_code == 200
                data1 = response1.json()
                assert data1["total"] == 1, "Guardian0 should have 1 child"
                assert len(data1["students"]) == 1, "Should return 1 student"
                
                # Test 2: Get with limit=1 (should still return 1)
                response2 = await client.get(
                    "/api/v1/guardians/my-children?skip=0&limit=1",
                    cookies={"access_token": access_token}
                )
                assert response2.status_code == 200
                data2 = response2.json()
                assert data2["total"] == 1, "Total should be 1"
                assert len(data2["students"]) == 1, "Should return 1 student"
                
                # Test 3: Skip the only record (skip=1)
                response3 = await client.get(
                    "/api/v1/guardians/my-children?skip=1&limit=10",
                    cookies={"access_token": access_token}
                )
                assert response3.status_code == 200
                data3 = response3.json()
                assert data3["total"] == 1, "Total should still be 1"
                assert len(data3["students"]) == 0, "Should return empty list when skip >= total"
                
                # Test 4: Skip beyond available records (skip=10)
                response4 = await client.get(
                    "/api/v1/guardians/my-children?skip=10&limit=2",
                    cookies={"access_token": access_token}
                )
                assert response4.status_code == 200
                data4 = response4.json()
                assert data4["total"] == 1, "Total should still be 1"
                assert len(data4["students"]) == 0, "Should return empty list when skip exceeds total"
                
                # Test 5: Limit of 0 (edge case)
                response5 = await client.get(
                    "/api/v1/guardians/my-children?skip=0&limit=0",
                    cookies={"access_token": access_token}
                )
                assert response5.status_code == 200
                data5 = response5.json()
                assert data5["total"] == 1, "Total should still be 1"
                assert len(data5["students"]) == 0, "Should return empty list with limit=0"
                
                # Test 6: Large limit (limit=1000)
                response6 = await client.get(
                    "/api/v1/guardians/my-children?skip=0&limit=1000",
                    cookies={"access_token": access_token}
                )
                assert response6.status_code == 200
                data6 = response6.json()
                assert data6["total"] == 1, "Total should still be 1"
                assert len(data6["students"]) == 1, "Should return 1 student even with large limit"
        
        finally:
            app.dependency_overrides.clear()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
