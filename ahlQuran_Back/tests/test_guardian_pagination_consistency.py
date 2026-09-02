"""
Property-based test for guardian children list pagination consistency
Feature: guardian-authentication-system
Task: 6.4 Write property test for pagination consistency

Property 9: Pagination Consistency
Validates: Requirements 3.7, 3.8
"""
import pytest
from httpx import AsyncClient
from datetime import datetime, timezone

from app.main import app
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.president import President
from app.core.security import get_password_hash, create_access_token


# Feature: guardian-authentication-system, Property 9: Pagination Consistency
@pytest.mark.asyncio
async def test_pagination_consistency_property(db_session):
    """
    Property test for pagination consistency.
    
    This test validates Property 9: Pagination Consistency
    - Paginating with different skip/limit returns correct subsets (Requirement 3.7)
    - Total count equals actual number of children regardless of pagination (Requirement 3.8)
    
    Note: Due to Guardian model having unique user_id constraint and single student_id,
    we test pagination by creating one guardian with one child and testing various pagination parameters.
    """
    import time
    unique_suffix = str(int(time.time() * 1000000))
    
    # Create president
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
    
    # Create guardian user
    guardian_user = User(
        firstname="TestGuardian",
        lastname="Parent",
        email=f"guardian_{unique_suffix}@test.com",
        hashed_password=get_password_hash("password123"),
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    db_session.add(guardian_user)
    await db_session.flush()
    
    # Create 1 student
    student_user = User(
        firstname=f"Student",
        lastname=f"Child",
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
        parent_name=f"TestGuardian Parent",
        parent_phone="1234567890",
        guardian_email=f"guardian_{unique_suffix}@test.com",
        sex="Male",
        date_of_birth=f"2010-01-01",
        academic_level="Elementary",
        grade=f"Grade 1",
        school_name="Test School"
    )
    db_session.add(student)
    await db_session.flush()
    
    # Link guardian to student
    guardian_record = Guardian(
        user_id=guardian_user.id,
        president_id=president.id,
        first_name="TestGuardian",
        last_name="Parent",
        relationship_to_student="Parent",
        student_id=student.id,
        created_at=datetime.now(timezone.utc),
        created_by_id=president_user.id
    )
    db_session.add(guardian_record)
    await db_session.flush()
    
    # Create JWT token
    token_data = {
        "sub": f"guardian_{unique_suffix}@test.com",
        "user_id": guardian_user.id,
        "role": "GUARDIAN"
    }
    access_token = create_access_token(data=token_data)
    
    # Override database dependency
    from app.db.session import get_db
    
    async def override_get_db():
        yield db_session
    
    app.dependency_overrides[get_db] = override_get_db
    
    try:
        # Test cases: (skip, limit, expected_count, description)
        test_cases = [
            (0, 10, 1, "Default pagination returns all children"),
            (0, 1, 1, "Limit of 1 returns 1 child"),
            (1, 10, 0, "Skip beyond total returns empty"),
            (0, 100, 1, "Large limit still returns correct count"),
            (10, 10, 0, "Large skip returns empty"),
        ]
        
        for skip, limit, expected_count, description in test_cases:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.get(
                    f"/api/v1/guardians/my-children?skip={skip}&limit={limit}",
                    cookies={"access_token": access_token}
                )
            
            assert response.status_code == 200, f"{description}: Expected 200, got {response.status_code}"
            data = response.json()
            
            # Total count should always be 1 (Requirement 3.8)
            assert data["total"] == 1, \
                f"{description}: Total should be 1, got {data['total']}"
            
            # Returned count should match expected (Requirement 3.7)
            assert len(data["students"]) == expected_count, \
                f"{description}: Expected {expected_count} students, got {len(data['students'])}"
            
            # No duplicates
            if len(data["students"]) > 0:
                returned_ids = [s["id"] for s in data["students"]]
                assert len(returned_ids) == len(set(returned_ids)), f"{description}: No duplicates"
        
        print(f"✓ Pagination consistency verified with 5 test cases")
    
    finally:
        app.dependency_overrides.clear()

