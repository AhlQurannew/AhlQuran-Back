"""
Property-based tests for guardian student context enrichment.

Feature: guardian-student-data-access
Property 9: Student Context Enrichment

For any valid achievement or attendance response, the response should include 
the student's id and name in a student context object, enabling guardians to 
identify which child's data they are viewing.

Validates: Requirements 4.1, 4.2
"""
import pytest
from hypothesis import given, strategies as st, settings
from hypothesis import HealthCheck
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession
from app.main import app
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.acheivements import Achievement, AchievementType
from app.models.attendance import Attendance, AttendanceStatus
from app.core.security import get_password_hash, create_access_token
from datetime import datetime, timezone


# ==================== PROPERTY TESTS ====================


# Feature: guardian-student-data-access, Property 9: Student Context Enrichment
@settings(
    max_examples=20,
    deadline=None,
    suppress_health_check=[HealthCheck.function_scoped_fixture, HealthCheck.too_slow]
)
@given(
    num_achievements=st.integers(min_value=1, max_value=3)
)
@pytest.mark.asyncio
async def test_achievement_response_includes_student_context(
    db_session: AsyncSession,
    num_achievements: int
):
    """
    Property 9: Student Context Enrichment (Achievements)
    
    For any valid achievement response, the response should include the student's 
    id and name in a student context object.
    
    Validates: Requirements 4.1, 4.2
    """
    import time
    unique_suffix = str(int(time.time() * 1000000))
    president_id = 1
    
    # Setup: Create guardian user
    guardian_user = User(
        firstname="Guardian",
        lastname="Test",
        email=f"guardian_{unique_suffix}@test.com",
        hashed_password=get_password_hash('password123'),
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    db_session.add(guardian_user)
    await db_session.flush()
    await db_session.refresh(guardian_user)
    
    # Setup: Create student user
    student_user = User(
        firstname="Student",
        lastname="Test",
        email=f"student_{unique_suffix}@test.com",
        hashed_password=get_password_hash('password123'),
        role=UserRoleEnum.STUDENT,
        is_active=True
    )
    db_session.add(student_user)
    await db_session.flush()
    await db_session.refresh(student_user)
    
    # Setup: Create student
    student = Student(
        user_id=student_user.id,
        president_id=president_id,
        enrollment_date=datetime.now(timezone.utc),
        parent_name="Parent Test",
        parent_phone="1234567890",
        guardian_email=f"guardian_{unique_suffix}@test.com",
        Golden=False,
        first_name_en="Student",
        last_name_en="Test",
        sex="male",
        date_of_birth="01-01-2010",
        place_of_birth="Test City",
        home_address="123 Test St",
        nationality="Test",
        father_status="alive",
        mother_status="alive",
        academic_level="Primary",
        grade="5",
        school_name="Test School"
    )
    db_session.add(student)
    await db_session.flush()
    await db_session.refresh(student)
    
    # Setup: Create guardian-student link
    guardian = Guardian(
        user_id=guardian_user.id,
        student_id=student.id,
        president_id=president_id
    )
    db_session.add(guardian)
    await db_session.flush()
    
    # Setup: Create achievements for the student
    for i in range(num_achievements):
        achievement = Achievement(
            student_id=student.id,
            president_id=president_id,
            from_surah=1,
            to_surah=1,
            from_verse=1,
            to_verse=10,
            note=f"Test achievement {i}",
            achievement_type=AchievementType.NORMAL,
            date=f"01-01-202{i}"
        )
        db_session.add(achievement)
    
    await db_session.commit()
    
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
        # Execute: Request achievements via HTTP endpoint
        async with AsyncClient(app=app, base_url="http://test") as client:
            response = await client.get(
                f"/api/v1/guardians/students/{student.id}/achievements",
                cookies={"access_token": access_token}
            )
        
        # Assert: Response is successful
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        
        # Assert: Response contains items
        assert len(data["items"]) > 0, "Response should contain achievement items"
        
        # Assert: Each achievement item includes student context
        for achievement_item in data["items"]:
            # Verify student context exists
            assert "student" in achievement_item, "Achievement should have student context"
            assert achievement_item["student"] is not None, "Student context should not be None"
            
            # Verify student context has id
            assert "id" in achievement_item["student"], "Student context should have id field"
            assert achievement_item["student"]["id"] == student.id, \
                f"Student context id should match student id: expected {student.id}, got {achievement_item['student']['id']}"
            
            # Verify student context has name
            assert "name" in achievement_item["student"], "Student context should have name field"
            assert achievement_item["student"]["name"] is not None, "Student context name should not be None"
            assert len(achievement_item["student"]["name"]) > 0, "Student context name should not be empty"
            
            # Verify name contains student's actual name
            expected_name = f"{student_user.firstname} {student_user.lastname}"
            assert achievement_item["student"]["name"] == expected_name, \
                f"Student context name should match: expected '{expected_name}', got '{achievement_item['student']['name']}'"
    
    finally:
        app.dependency_overrides.clear()


# Feature: guardian-student-data-access, Property 9: Student Context Enrichment
@settings(
    max_examples=20,
    deadline=None,
    suppress_health_check=[HealthCheck.function_scoped_fixture, HealthCheck.too_slow]
)
@given(
    num_attendance=st.integers(min_value=1, max_value=3)
)
@pytest.mark.asyncio
async def test_attendance_response_includes_student_context(
    db_session: AsyncSession,
    num_attendance: int
):
    """
    Property 9: Student Context Enrichment (Attendance)
    
    For any valid attendance response, the response should include the student's 
    id and name in a student context object.
    
    Validates: Requirements 4.1, 4.2
    """
    import time
    unique_suffix = str(int(time.time() * 1000000))
    president_id = 1
    
    # Setup: Create guardian user
    guardian_user = User(
        firstname="Guardian",
        lastname="Test",
        email=f"guardian_{unique_suffix}@test.com",
        hashed_password=get_password_hash('password123'),
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    db_session.add(guardian_user)
    await db_session.flush()
    await db_session.refresh(guardian_user)
    
    # Setup: Create student user
    student_user = User(
        firstname="Student",
        lastname="Test",
        email=f"student_{unique_suffix}@test.com",
        hashed_password=get_password_hash('password123'),
        role=UserRoleEnum.STUDENT,
        is_active=True
    )
    db_session.add(student_user)
    await db_session.flush()
    await db_session.refresh(student_user)
    
    # Setup: Create student
    student = Student(
        user_id=student_user.id,
        president_id=president_id,
        enrollment_date=datetime.now(timezone.utc),
        parent_name="Parent Test",
        parent_phone="1234567890",
        guardian_email=f"guardian_{unique_suffix}@test.com",
        Golden=False,
        first_name_en="Student",
        last_name_en="Test",
        sex="male",
        date_of_birth="01-01-2010",
        place_of_birth="Test City",
        home_address="123 Test St",
        nationality="Test",
        father_status="alive",
        mother_status="alive",
        academic_level="Primary",
        grade="5",
        school_name="Test School"
    )
    db_session.add(student)
    await db_session.flush()
    await db_session.refresh(student)
    
    # Setup: Create guardian-student link
    guardian = Guardian(
        user_id=guardian_user.id,
        student_id=student.id,
        president_id=president_id
    )
    db_session.add(guardian)
    await db_session.flush()
    
    # Setup: Create attendance records for the student
    for i in range(num_attendance):
        attendance = Attendance(
            student_id=student.id,
            president_id=president_id,
            date=f"0{i+1}-01-2024",
            status=AttendanceStatus.PRESENT,
            notes=f"Test attendance {i}"
        )
        db_session.add(attendance)
    
    await db_session.commit()
    
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
        # Execute: Request attendance via HTTP endpoint
        async with AsyncClient(app=app, base_url="http://test") as client:
            response = await client.get(
                f"/api/v1/guardians/students/{student.id}/attendance",
                cookies={"access_token": access_token}
            )
        
        # Assert: Response is successful
        assert response.status_code == 200, f"Expected 200, got {response.status_code}"
        data = response.json()
        
        # Assert: Response contains items
        assert len(data["items"]) > 0, "Response should contain attendance items"
        
        # Assert: Each attendance item includes student context
        for attendance_item in data["items"]:
            # Verify student context exists
            assert "student" in attendance_item, "Attendance should have student context"
            assert attendance_item["student"] is not None, "Student context should not be None"
            
            # Verify student context has id
            assert "id" in attendance_item["student"], "Student context should have id field"
            assert attendance_item["student"]["id"] == student.id, \
                f"Student context id should match student id: expected {student.id}, got {attendance_item['student']['id']}"
            
            # Verify student context has name
            assert "name" in attendance_item["student"], "Student context should have name field"
            assert attendance_item["student"]["name"] is not None, "Student context name should not be None"
            assert len(attendance_item["student"]["name"]) > 0, "Student context name should not be empty"
            
            # Verify name contains student's actual name
            expected_name = f"{student_user.firstname} {student_user.lastname}"
            assert attendance_item["student"]["name"] == expected_name, \
                f"Student context name should match: expected '{expected_name}', got '{attendance_item['student']['name']}'"
    
    finally:
        app.dependency_overrides.clear()
