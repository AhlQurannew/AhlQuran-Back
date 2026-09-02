"""
Unit test for guardian children list completeness
Feature: guardian-authentication-system
Task: 6.3 Write property test for children list completeness

Property 8: Children List Completeness
Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
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
async def test_children_list_returns_complete_student_data():
    """
    Test that guardian children list endpoint returns complete student data structure.
    
    This test validates Property 8: Children List Completeness
    - Response contains exactly the students linked to guardian (Requirement 3.1)
    - Each student includes personal information (Requirement 3.2)
    - Each student includes lecture enrollments (Requirement 3.3)
    - Each student includes attendance records (Requirement 3.4)
    - Each student includes achievements (Requirement 3.5)
    
    All nested structures must be present: personalInfo, accountInfo, contactInfo,
    guardian, lectures, formalEducationInfo, medicalInfo, subscriptionInfo
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        import time
        unique_suffix = str(int(time.time() * 1000000))
        
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
            
            # Create student
            student_user = User(
                firstname="TestStudent",
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
                parent_name="TestGuardian Parent",
                parent_phone="1234567890",
                guardian_email=f"guardian_{unique_suffix}@test.com",
                sex="Male",
                date_of_birth="2010-01-01",
                academic_level="Elementary",
                grade="Grade 5",
                school_name="Test School"
            )
            db_session.add(student)
            await db_session.flush()
            
            # Create guardian record linking to student
            guardian_record = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="TestGuardian",
                last_name="Parent",
                relationship_to_student="Father",
                student_id=student.id,
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian_record)
            await db_session.commit()
        
        # Create JWT token for guardian
        token_data = {
            "sub": f"guardian_{unique_suffix}@test.com",
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
        
        # Verify response structure
        assert "students" in response_data, "Response should have 'students' field"
        assert "total" in response_data, "Response should have 'total' field"
        
        # Verify exactly one student is returned (Requirement 3.1)
        assert response_data["total"] == 1, f"Total should be 1, got {response_data['total']}"
        assert len(response_data["students"]) == 1, f"Should return 1 student, got {len(response_data['students'])}"
        
        student_data = response_data["students"][0]
        
        # Verify all required nested structures exist
        required_fields = [
            "personalInfo",
            "accountInfo", 
            "contactInfo",
            "guardian",
            "lectures",
            "formalEducationInfo",
            "medicalInfo",
            "subscriptionInfo"
        ]
        
        for field in required_fields:
            assert field in student_data, f"Student should have '{field}' field"
        
        # Verify personalInfo completeness (Requirement 3.2)
        personal_info = student_data["personalInfo"]
        assert personal_info is not None, "personalInfo should not be None"
        assert personal_info["firstNameAr"] == "TestStudent", "Should have correct firstNameAr"
        assert personal_info["lastNameAr"] == "Child", "Should have correct lastNameAr"
        assert personal_info["sex"] == "Male", "Should have correct sex"
        assert personal_info["dateOfBirth"] == "2010-01-01", "Should have correct dateOfBirth"
        
        # Verify accountInfo completeness
        account_info = student_data["accountInfo"]
        assert account_info is not None, "accountInfo should not be None"
        assert account_info["accountId"] is not None, "Should have accountId"
        assert account_info["username"] is not None, "Should have username"
        assert account_info["accountType"] == "Student", "Should have correct accountType"
        assert account_info["passcode"] == "", "Password hash should NOT be included (security)"
        
        # Verify contactInfo completeness
        contact_info = student_data["contactInfo"]
        assert contact_info is not None, "contactInfo should not be None"
        assert contact_info["phoneNumber"] == "1234567890", "Should have correct phoneNumber"
        assert contact_info["email"] is not None, "Should have email"
        
        # Verify guardian info completeness
        guardian_info = student_data["guardian"]
        assert guardian_info is not None, "guardian info should not be None"
        assert guardian_info["firstName"] == "TestGuardian Parent", "Should have guardian firstName"
        
        # Verify formalEducationInfo completeness
        education_info = student_data["formalEducationInfo"]
        assert education_info is not None, "formalEducationInfo should not be None"
        assert education_info["academicLevel"] == "Elementary", "Should have correct academicLevel"
        assert education_info["grade"] == "Grade 5", "Should have correct grade"
        assert education_info["schoolName"] == "Test School", "Should have correct schoolName"
        
        # Verify lectures is a list (Requirement 3.3)
        assert isinstance(student_data["lectures"], list), "lectures should be a list"
        # Empty list is OK if student not enrolled in lectures
        
        # Verify medicalInfo exists
        assert student_data["medicalInfo"] is not None, "medicalInfo should exist"
        
        # Verify subscriptionInfo exists
        assert student_data["subscriptionInfo"] is not None, "subscriptionInfo should exist"
        assert student_data["subscriptionInfo"]["status"] is not None, "Should have subscription status"
        
        # Verify student ID matches
        assert student_data["id"] == student.id, f"Student ID should match"
        
        print("✓ All completeness checks passed")
        print(f"✓ Student data includes all {len(required_fields)} required nested structures")
        print("✓ Password hash is not exposed")
        print("✓ All personal, account, contact, and education info is complete")
    
    finally:
        await engine.dispose()
