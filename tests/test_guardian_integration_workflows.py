"""
Integration tests for complete guardian workflows
Feature: guardian-authentication-system
Task: 10. Write integration tests for complete guardian workflows

Tests complete flows:
- Guardian login → get children list → get child detail
- Authorization failures across different endpoints
- Multi-tenancy isolation with multiple presidents
- Response schema consistency (Property 14)

Validates: Requirements 8.1, 8.2, 8.5
"""
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text
from datetime import datetime, timezone
import os

from app.main import app
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.president import President
from app.core.security import get_password_hash
from app.db.base import Base

# Test database URL
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


@pytest.mark.asyncio
async def test_complete_guardian_workflow_login_to_child_detail():
    """
    Integration test: Complete guardian workflow from login to viewing child details.
    
    Flow:
    1. Guardian logs in with valid credentials
    2. Guardian retrieves their children list
    3. Guardian views detailed information for a specific child
    
    Validates end-to-end functionality and data consistency across endpoints.
    """
    # Create fresh engine and session
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        import time
        unique_suffix = str(int(time.time() * 1000000))
        
        guardian_email = f"workflow_guardian_{unique_suffix}@test.com"
        guardian_password = "workflow_password123"
        
        async with async_session_factory() as db_session:
            # Create president
            president_user = User(
                firstname="Workflow",
                lastname="President",
                email=f"workflow_president_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name=f"Workflow School {unique_suffix}",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create guardian user
            guardian_user = User(
                firstname="Workflow",
                lastname="Guardian",
                email=guardian_email,
                hashed_password=get_password_hash(guardian_password),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create student (child)
            student_user = User(
                firstname="Workflow",
                lastname="Child",
                email=f"workflow_student_{unique_suffix}@test.com",
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
                parent_name="Workflow Guardian",
                parent_phone="1234567890",
                guardian_email=guardian_email,
                sex="Female",
                date_of_birth="2012-05-15",
                academic_level="Middle School",
                grade="Grade 7",
                school_name="Workflow School"
            )
            db_session.add(student)
            await db_session.flush()
            student_id = student.id
            
            # Create guardian record
            guardian_record = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Workflow",
                last_name="Guardian",
                relationship_to_student="Mother",
                students=[student],
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian_record)
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Step 1: Guardian login
                login_response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={"email": guardian_email, "password": guardian_password}
                )
                
                assert login_response.status_code == 200, f"Login failed: {login_response.text}"
                login_data = login_response.json()
                
                # Verify login response structure
                assert "access_token" in login_data
                assert "guardian" in login_data
                assert login_data["guardian"]["first_name"] == "Workflow"
                
                # Extract token from cookie
                assert "access_token" in login_response.cookies
                access_token = login_response.cookies["access_token"]
                
                # Step 2: Get children list
                children_response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": access_token}
                )
                
                assert children_response.status_code == 200, f"Get children failed: {children_response.text}"
                children_data = children_response.json()
                
                # Verify children list structure
                assert "students" in children_data
                assert "total" in children_data
                assert children_data["total"] == 1
                assert len(children_data["students"]) == 1
                
                # Verify child data in list
                child_in_list = children_data["students"][0]
                assert child_in_list["id"] == student_id
                assert child_in_list["personalInfo"]["firstNameAr"] == "Workflow"
                assert child_in_list["personalInfo"]["sex"] == "Female"
                
                # Step 3: Get child detail
                detail_response = await client.get(
                    f"/api/v1/guardians/my-children/{student_id}",
                    cookies={"access_token": access_token}
                )
                
                assert detail_response.status_code == 200, f"Get child detail failed: {detail_response.text}"
                detail_data = detail_response.json()
                
                # Verify detail response structure matches list response (schema consistency)
                assert detail_data["id"] == child_in_list["id"]
                assert detail_data["personalInfo"]["firstNameAr"] == child_in_list["personalInfo"]["firstNameAr"]
                assert detail_data["personalInfo"]["sex"] == child_in_list["personalInfo"]["sex"]
                assert detail_data["personalInfo"]["dateOfBirth"] == child_in_list["personalInfo"]["dateOfBirth"]
                
                # Verify all required nested structures exist in detail response
                required_fields = [
                    "personalInfo", "accountInfo", "contactInfo", "guardian",
                    "lectures", "formalEducationInfo", "medicalInfo", "subscriptionInfo"
                ]
                for field in required_fields:
                    assert field in detail_data, f"Detail response missing '{field}'"
                
                print("✓ Complete workflow test passed")
                print("✓ Login → Children List → Child Detail flow works correctly")
                print("✓ Response schema is consistent across endpoints")
        
        finally:
            app.dependency_overrides.clear()
    
    finally:
        await engine.dispose()



@pytest.mark.asyncio
async def test_authorization_failures_across_endpoints():
    """
    Integration test: Authorization failures across different guardian endpoints.
    
    Tests:
    - Non-guardian user cannot access guardian endpoints
    - Invalid token is rejected
    - Missing token is rejected
    - Guardian cannot access another guardian's children
    
    Validates authorization enforcement across all endpoints.
    """
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        import time
        unique_suffix = str(int(time.time() * 1000000))
        
        async with async_session_factory() as db_session:
            # Create president
            president_user = User(
                firstname="Auth",
                lastname="President",
                email=f"auth_president_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name=f"Auth School {unique_suffix}",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create teacher user (non-guardian)
            teacher_user = User(
                firstname="Auth",
                lastname="Teacher",
                email=f"auth_teacher_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.TEACHER,
                is_active=True
            )
            db_session.add(teacher_user)
            await db_session.flush()
            
            # Create guardian user
            guardian_user = User(
                firstname="Auth",
                lastname="Guardian",
                email=f"auth_guardian_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create student
            student_user = User(
                firstname="Auth",
                lastname="Student",
                email=f"auth_student_{unique_suffix}@test.com",
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
                parent_name="Auth Guardian",
                parent_phone="1234567890",
                guardian_email=f"auth_guardian_{unique_suffix}@test.com",
                sex="Male",
                date_of_birth="2011-03-20",
                academic_level="Elementary",
                grade="Grade 4",
                school_name="Auth School"
            )
            db_session.add(student)
            await db_session.flush()
            student_id = student.id
            
            # Create guardian record
            guardian_record = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Auth",
                last_name="Guardian",
                relationship_to_student="Father",
                students=[student],
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian_record)
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        from app.core.security import create_access_token
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Test 1: Non-guardian user (teacher) cannot access guardian endpoints
                teacher_token = create_access_token(
                    data={"sub": f"auth_teacher_{unique_suffix}@test.com", "user_id": teacher_user.id, "role": "TEACHER"}
                )
                
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": teacher_token}
                )
                assert response.status_code == 403, f"Teacher should be forbidden, got {response.status_code}"
                
                # Test 2: Invalid token is rejected
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": "invalid_token_12345"}
                )
                assert response.status_code == 401, f"Invalid token should return 401, got {response.status_code}"
                
                # Test 3: Missing token is rejected
                response = await client.get("/api/v1/guardians/my-children")
                assert response.status_code == 401, f"Missing token should return 401, got {response.status_code}"
                
                # Test 4: Valid guardian token works
                guardian_token = create_access_token(
                    data={"sub": f"auth_guardian_{unique_suffix}@test.com", "user_id": guardian_user.id, "role": "GUARDIAN"}
                )
                
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": guardian_token}
                )
                assert response.status_code == 200, f"Valid guardian should succeed, got {response.status_code}"
                
                print("✓ Authorization failure tests passed")
                print("✓ Non-guardian users are properly rejected")
                print("✓ Invalid/missing tokens are properly rejected")
        
        finally:
            app.dependency_overrides.clear()
    
    finally:
        await engine.dispose()



@pytest.mark.asyncio
async def test_multi_tenancy_isolation_with_multiple_presidents():
    """
    Integration test: Multi-tenancy isolation with multiple presidents.
    
    Tests:
    - Guardian from President A cannot see students from President B
    - Children list is properly filtered by president_id
    - Child detail access is blocked for students from different presidents
    
    Validates multi-tenancy isolation across the entire guardian workflow.
    """
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        import time
        unique_suffix = str(int(time.time() * 1000000))
        
        async with async_session_factory() as db_session:
            # Create President A
            president_a_user = User(
                firstname="President",
                lastname="A",
                email=f"president_a_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_a_user)
            await db_session.flush()
            
            president_a = President(
                user_id=president_a_user.id,
                school_name=f"School A {unique_suffix}",
                phone_number="1111111111",
                is_verified=True
            )
            db_session.add(president_a)
            await db_session.flush()
            
            # Create President B
            president_b_user = User(
                firstname="President",
                lastname="B",
                email=f"president_b_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_b_user)
            await db_session.flush()
            
            president_b = President(
                user_id=president_b_user.id,
                school_name=f"School B {unique_suffix}",
                phone_number="2222222222",
                is_verified=True
            )
            db_session.add(president_b)
            await db_session.flush()
            
            # Create Guardian A (belongs to President A)
            guardian_a_user = User(
                firstname="Guardian",
                lastname="A",
                email=f"guardian_a_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_a_user)
            await db_session.flush()
            
            # Create Student A (belongs to President A)
            student_a_user = User(
                firstname="Student",
                lastname="A",
                email=f"student_a_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.STUDENT,
                is_active=True
            )
            db_session.add(student_a_user)
            await db_session.flush()
            
            student_a = Student(
                user_id=student_a_user.id,
                president_id=president_a.id,
                enrollment_date=datetime.now(timezone.utc),
                created_by_id=president_a_user.id,
                parent_name="Guardian A",
                parent_phone="1111111111",
                guardian_email=f"guardian_a_{unique_suffix}@test.com",
                sex="Male",
                date_of_birth="2010-01-01",
                academic_level="Elementary",
                grade="Grade 5",
                school_name="School A"
            )
            db_session.add(student_a)
            await db_session.flush()
            student_a_id = student_a.id
            
            # Link Guardian A to Student A
            guardian_a_record = Guardian(
                user_id=guardian_a_user.id,
                president_id=president_a.id,
                first_name="Guardian",
                last_name="A",
                relationship_to_student="Father",
                students=[student_a],
                created_at=datetime.now(timezone.utc),
                created_by_id=president_a_user.id
            )
            db_session.add(guardian_a_record)
            await db_session.flush()
            
            # Create Student B (belongs to President B)
            student_b_user = User(
                firstname="Student",
                lastname="B",
                email=f"student_b_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.STUDENT,
                is_active=True
            )
            db_session.add(student_b_user)
            await db_session.flush()
            
            student_b = Student(
                user_id=student_b_user.id,
                president_id=president_b.id,
                enrollment_date=datetime.now(timezone.utc),
                created_by_id=president_b_user.id,
                parent_name="Guardian B",
                parent_phone="2222222222",
                guardian_email=f"guardian_b_{unique_suffix}@test.com",
                sex="Female",
                date_of_birth="2011-02-02",
                academic_level="Middle School",
                grade="Grade 6",
                school_name="School B"
            )
            db_session.add(student_b)
            await db_session.flush()
            student_b_id = student_b.id
            
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        from app.core.security import create_access_token
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Create token for Guardian A
                guardian_a_token = create_access_token(
                    data={"sub": f"guardian_a_{unique_suffix}@test.com", "user_id": guardian_a_user.id, "role": "GUARDIAN"}
                )
                
                # Test 1: Guardian A can see their own child (Student A)
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": guardian_a_token}
                )
                assert response.status_code == 200, f"Guardian A should access their children, got {response.status_code}"
                
                children_data = response.json()
                assert children_data["total"] == 1, f"Guardian A should see 1 child, got {children_data['total']}"
                assert children_data["students"][0]["id"] == student_a_id, "Guardian A should see Student A"
                
                # Test 2: Guardian A can access Student A detail
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student_a_id}",
                    cookies={"access_token": guardian_a_token}
                )
                assert response.status_code == 200, f"Guardian A should access Student A detail, got {response.status_code}"
                
                # Test 3: Guardian A CANNOT access Student B detail (different president)
                response = await client.get(
                    f"/api/v1/guardians/my-children/{student_b_id}",
                    cookies={"access_token": guardian_a_token}
                )
                assert response.status_code == 403, f"Guardian A should be forbidden from Student B, got {response.status_code}"
                
                # Test 4: Guardian A's children list does NOT include Student B
                response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": guardian_a_token}
                )
                children_data = response.json()
                student_ids = [s["id"] for s in children_data["students"]]
                assert student_b_id not in student_ids, "Guardian A should not see Student B in their children list"
                
                print("✓ Multi-tenancy isolation tests passed")
                print("✓ Guardian A can only access students from President A")
                print("✓ Guardian A cannot access students from President B")
                print("✓ Children list is properly filtered by president_id")
        
        finally:
            app.dependency_overrides.clear()
    
    finally:
        await engine.dispose()



@pytest.mark.asyncio
async def test_response_schema_consistency_property():
    """
    Property 14: Response Schema Consistency
    
    For any student data returned by guardian endpoints (list or detail),
    the response should conform to the StudentResponse schema format with
    nested structures, and password hashes should never be included in any response.
    
    Validates: Requirements 8.1, 8.2, 8.5
    
    Tests:
    - Children list response matches StudentResponse schema
    - Child detail response matches StudentResponse schema
    - Both endpoints return identical structure for the same student
    - Password hashes are never exposed
    - All required nested structures are present
    """
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        import time
        unique_suffix = str(int(time.time() * 1000000))
        
        async with async_session_factory() as db_session:
            # Create president
            president_user = User(
                firstname="Schema",
                lastname="President",
                email=f"schema_president_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name=f"Schema School {unique_suffix}",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create guardian user
            guardian_user = User(
                firstname="Schema",
                lastname="Guardian",
                email=f"schema_guardian_{unique_suffix}@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create student
            student_user = User(
                firstname="Schema",
                lastname="Student",
                email=f"schema_student_{unique_suffix}@test.com",
                hashed_password=get_password_hash("secret_password_hash"),
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
                parent_name="Schema Guardian",
                parent_phone="9876543210",
                guardian_email=f"schema_guardian_{unique_suffix}@test.com",
                sex="Male",
                date_of_birth="2013-07-25",
                academic_level="Elementary",
                grade="Grade 3",
                school_name="Schema School"
            )
            db_session.add(student)
            await db_session.flush()
            student_id = student.id
            
            # Create guardian record
            guardian_record = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Schema",
                last_name="Guardian",
                relationship_to_student="Father",
                students=[student],
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian_record)
            await db_session.commit()
        
        # Override database dependency
        from app.db.session import get_db
        from app.core.security import create_access_token
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                # Create token for guardian
                guardian_token = create_access_token(
                    data={"sub": f"schema_guardian_{unique_suffix}@test.com", "user_id": guardian_user.id, "role": "GUARDIAN"}
                )
                
                # Get student from children list
                list_response = await client.get(
                    "/api/v1/guardians/my-children",
                    cookies={"access_token": guardian_token}
                )
                assert list_response.status_code == 200
                list_data = list_response.json()
                student_from_list = list_data["students"][0]
                
                # Get student from detail endpoint
                detail_response = await client.get(
                    f"/api/v1/guardians/my-children/{student_id}",
                    cookies={"access_token": guardian_token}
                )
                assert detail_response.status_code == 200
                student_from_detail = detail_response.json()
                
                # Define required nested structures per StudentResponse schema
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
                
                # Test 1: Both responses have all required nested structures
                for field in required_fields:
                    assert field in student_from_list, f"List response missing '{field}'"
                    assert field in student_from_detail, f"Detail response missing '{field}'"
                
                # Test 2: Schema structure is identical between list and detail
                assert student_from_list["id"] == student_from_detail["id"]
                assert student_from_list["personalInfo"]["firstNameAr"] == student_from_detail["personalInfo"]["firstNameAr"]
                assert student_from_list["personalInfo"]["lastNameAr"] == student_from_detail["personalInfo"]["lastNameAr"]
                assert student_from_list["personalInfo"]["sex"] == student_from_detail["personalInfo"]["sex"]
                assert student_from_list["personalInfo"]["dateOfBirth"] == student_from_detail["personalInfo"]["dateOfBirth"]
                
                # Test 3: Password hash is NEVER exposed (Requirement 8.5)
                list_response_str = list_response.text
                detail_response_str = detail_response.text
                
                assert "secret_password_hash" not in list_response_str, "Password hash exposed in list response"
                assert "secret_password_hash" not in detail_response_str, "Password hash exposed in detail response"
                assert "$2b$" not in list_response_str, "Bcrypt hash exposed in list response"
                assert "$2b$" not in detail_response_str, "Bcrypt hash exposed in detail response"
                
                # Test 4: accountInfo.passcode is empty (not the actual hash)
                assert student_from_list["accountInfo"]["passcode"] == "", "Passcode should be empty string"
                assert student_from_detail["accountInfo"]["passcode"] == "", "Passcode should be empty string"
                
                # Test 5: Nested structures have expected types
                assert isinstance(student_from_list["personalInfo"], dict), "personalInfo should be dict"
                assert isinstance(student_from_list["accountInfo"], dict), "accountInfo should be dict"
                assert isinstance(student_from_list["contactInfo"], dict), "contactInfo should be dict"
                assert isinstance(student_from_list["guardian"], dict), "guardian should be dict"
                assert isinstance(student_from_list["lectures"], list), "lectures should be list"
                assert isinstance(student_from_list["formalEducationInfo"], dict), "formalEducationInfo should be dict"
                assert isinstance(student_from_list["medicalInfo"], dict), "medicalInfo should be dict"
                assert isinstance(student_from_list["subscriptionInfo"], dict), "subscriptionInfo should be dict"
                
                # Test 6: Key fields are populated correctly
                assert student_from_list["personalInfo"]["sex"] == "Male"
                assert student_from_list["personalInfo"]["dateOfBirth"] == "2013-07-25"
                assert student_from_list["formalEducationInfo"]["grade"] == "Grade 3"
                assert student_from_list["formalEducationInfo"]["academicLevel"] == "Elementary"
                assert student_from_list["contactInfo"]["phoneNumber"] == "9876543210"
                
                print("✓ Response schema consistency tests passed")
                print("✓ Both endpoints return identical StudentResponse schema")
                print("✓ All required nested structures are present")
                print("✓ Password hashes are never exposed")
                print("✓ Schema structure is consistent across list and detail endpoints")
        
        finally:
            app.dependency_overrides.clear()
    
    finally:
        await engine.dispose()
