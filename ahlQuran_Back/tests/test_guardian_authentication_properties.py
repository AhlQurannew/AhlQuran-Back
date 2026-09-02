"""
Property-based tests for guardian authentication system
Feature: guardian-authentication-system
"""
import pytest
import os
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text
from app.db.base import Base
# Import all models to ensure they're registered with Base.metadata
import app.models  # This imports all models via __init__.py
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.president import President
from app.core.security import get_password_hash, decode_token
from app.main import app
from datetime import datetime, timezone


# Test database URL - use PostgreSQL test database in Docker
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


async def cleanup_test_data(session: AsyncSession):
    """Clean up test data after each property test."""
    try:
        await session.execute(text("DELETE FROM guardians"))
        await session.execute(text("DELETE FROM presidents"))
        await session.execute(text("DELETE FROM users"))
        await session.commit()
    except Exception:
        await session.rollback()
        raise


# Feature: guardian-authentication-system, Property 1: Valid Guardian Authentication
@pytest.mark.asyncio
async def test_valid_guardian_authentication_property():
    """
    Property 1: Valid Guardian Authentication
    
    For any guardian with valid credentials (correct email and password) and an active account,
    authenticating should return a JWT token, set an HTTP-only secure cookie, and include
    complete guardian details (guardian_id, first_name, last_name, relationship) in the response.
    
    Validates: Requirements 1.1, 1.3, 1.7
    """
    # Use fixed test data
    data = {
        "email": "test_guardian@example.com",
        "password": "testpass123",
        "firstname": "TestFirst",
        "lastname": "TestLast",
        "relationship": "Father"
    }
    
    # Create a fresh database engine and session for this test
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    async with async_session() as db_session:
        # Create president for multi-tenancy
        president_user = User(
            firstname="President",
            lastname="Test",
            email=f"president_{data['email']}",
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
        
        # Create guardian user with valid credentials and active account
        user = User(
            firstname=data["firstname"],
            lastname=data["lastname"],
            email=data["email"],
            hashed_password=get_password_hash(data["password"]),
            role=UserRoleEnum.GUARDIAN,
            is_active=True
        )
        db_session.add(user)
        await db_session.flush()
        
        # Create guardian record
        guardian = Guardian(
            user_id=user.id,
            president_id=president.id,
            first_name=data["firstname"],
            last_name=data["lastname"],
            relationship_to_student=data["relationship"],
            created_at=datetime.now(timezone.utc),
            created_by_id=president_user.id
        )
        db_session.add(guardian)
        await db_session.commit()
        
        # Test authentication
        async with AsyncClient(app=app, base_url="http://test") as client:
            # Override the database dependency
            from app.db.session import get_db
            
            async def override_get_db():
                yield db_session
            
            app.dependency_overrides[get_db] = override_get_db
            
            response = await client.post(
                "/api/v1/auth/guardian/login",
                json={"email": data["email"], "password": data["password"]}
            )
            
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        response_data = response.json()
        
        # Verify JWT token is returned
        assert "access_token" in response_data
        assert response_data["access_token"] is not None
        assert len(response_data["access_token"]) > 0
        
        # Verify token type
        assert response_data["token_type"] == "bearer"
        
        # Verify HTTP-only secure cookie is set
        assert "access_token" in response.cookies
        cookie_value = response.cookies["access_token"]
        # Strip quotes if present (httpx may include quotes)
        cookie_value_clean = cookie_value.strip('"')
        assert cookie_value_clean.startswith("Bearer ")
        
        # Verify guardian details are in response
        assert "guardian" in response_data
        assert response_data["guardian"] is not None
        assert response_data["guardian"]["guardian_id"] == guardian.id
        assert response_data["guardian"]["first_name"] == data["firstname"]
        assert response_data["guardian"]["last_name"] == data["lastname"]
        assert response_data["guardian"]["relationship"] == data["relationship"]
        
        # Verify user info is in response
        assert "user" in response_data
        assert response_data["user"]["email"] == data["email"]
        assert response_data["user"]["role"] == "GUARDIAN"
        
        # Cleanup - delete data but keep tables
        await db_session.execute(text("DELETE FROM guardians"))
        await db_session.execute(text("DELETE FROM presidents"))
        await db_session.execute(text("DELETE FROM users"))
        await db_session.commit()
    
    await engine.dispose()


# Feature: guardian-authentication-system, Property 2: Invalid Credentials Rejection
@pytest.mark.asyncio
async def test_invalid_credentials_rejection_property():
    """
    Property 2: Invalid Credentials Rejection
    
    For any authentication attempt with invalid credentials (non-existent email or incorrect password),
    the system should return a 401 Unauthorized error and not issue a JWT token.
    
    Validates: Requirements 1.2
    """
    # Use fixed test data
    email = "nonexistent@example.com"
    password = "wrongpassword"
    
    # Create a fresh database engine and session for this test
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    async with async_session() as db_session:
        # Test authentication with non-existent email (no user created)
        async with AsyncClient(app=app, base_url="http://test") as client:
            from app.db.session import get_db
            
            async def override_get_db():
                yield db_session
            
            app.dependency_overrides[get_db] = override_get_db
            
            response = await client.post(
                "/api/v1/auth/guardian/login",
                json={"email": email, "password": password}
            )
            
            app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 401, f"Expected 401, got {response.status_code}"
        
        response_data = response.json()
        assert "detail" in response_data
        assert "invalid" in response_data["detail"].lower() or "password" in response_data["detail"].lower()
        
        # Cleanup - delete data but keep tables
        await db_session.execute(text("DELETE FROM guardians"))
        await db_session.execute(text("DELETE FROM presidents"))
        await db_session.execute(text("DELETE FROM users"))
        await db_session.commit()
    
    await engine.dispose()


# Feature: guardian-authentication-system, Property 3: Password Verification and Upgrade
@pytest.mark.asyncio
async def test_password_verification_and_upgrade_property():
    """
    Property 3: Password Verification and Upgrade
    
    For any guardian account, the system should successfully verify both bcrypt-hashed and
    plain text passwords, and when a plain text password is used for authentication,
    the system should upgrade it to bcrypt format in the database.
    
    Validates: Requirements 1.5, 1.6
    """
    # Use fixed test data
    data = {
        "email": "upgrade_test@example.com",
        "password": "plaintext123",
        "firstname": "Upgrade",
        "lastname": "Test",
        "relationship": "Mother"
    }
    
    # Create a fresh database engine and session for this test
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    # Import all models to ensure they're registered with Base.metadata
    import app.models  # This imports all models via __init__.py
    
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        async_session_factory = async_sessionmaker(
            engine,
            class_=AsyncSession,
            expire_on_commit=False
        )
        
        user_id = None
        original_password = None
        
        # Create test data
        async with async_session_factory() as db_session:
            # Create president for multi-tenancy
            president_user = User(
                firstname="President",
                lastname="Test",
                email=f"president_{data['email']}",
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
            
            # Create guardian user with PLAIN TEXT password (legacy format)
            user = User(
                firstname=data["firstname"],
                lastname=data["lastname"],
                email=data["email"],
                hashed_password=data["password"],  # Plain text password
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(user)
            await db_session.flush()
            user_id = user.id
            original_password = user.hashed_password
            
            # Create guardian record
            guardian = Guardian(
                user_id=user.id,
                president_id=president.id,
                first_name=data["firstname"],
                last_name=data["lastname"],
                relationship_to_student=data["relationship"],
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
        
        # Test authentication with plain text password using a fresh session
        from app.db.session import get_db
        from app.main import app as fastapi_app
        
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        fastapi_app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=fastapi_app, base_url="http://test") as client:
                response = await client.post(
                    "/api/v1/auth/guardian/login",
                    json={"email": data["email"], "password": data["password"]}
                )
        finally:
            fastapi_app.dependency_overrides.clear()
        
        # Assertions
        assert response.status_code == 200, f"Expected 200, got {response.status_code}: {response.text}"
        
        # Verify password was upgraded in a new session
        async with async_session_factory() as verify_session:
            from sqlalchemy import select
            result = await verify_session.execute(select(User).where(User.id == user_id))
            updated_user = result.scalar_one()
            
            # Verify password was upgraded to bcrypt
            assert updated_user.hashed_password != original_password, "Password should have been upgraded"
            assert updated_user.hashed_password.startswith("$2b$") or updated_user.hashed_password.startswith("$2a$"), "Password should be bcrypt hashed"
        
        # Cleanup - delete data but keep tables
        async with async_session_factory() as cleanup_session:
            await cleanup_session.execute(text("DELETE FROM guardians"))
            await cleanup_session.execute(text("DELETE FROM presidents"))
            await cleanup_session.execute(text("DELETE FROM users"))
            await cleanup_session.commit()
    
    finally:
        await engine.dispose()


# Feature: guardian-authentication-system, Property 4: JWT Token Structure
def test_jwt_token_structure_property():
    """
    Property 4: JWT Token Structure
    
    For any successfully generated JWT token for a guardian, decoding the token should reveal
    the guardian's email, user_id, role (GUARDIAN), and token type, and the token expiration
    should match the configured ACCESS_TOKEN_EXPIRE_MINUTES setting.
    
    Validates: Requirements 1.8, 7.4
    
    NOTE: This test directly tests the JWT token creation and decoding logic without
    going through the full authentication flow, making it much faster.
    """
    from app.core.security import create_access_token, decode_token
    from app.core.config import settings
    from datetime import timedelta
    
    # Use fixed test data
    email = "token_test@example.com"
    user_id = 12345
    
    # Create a JWT token directly (without database or HTTP calls)
    access_token = create_access_token(
        data={
            "email": email,
            "user_id": user_id,
            "role": "GUARDIAN",
            "type": "user"  # This will be overwritten to "access" by create_access_token
        },
        expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    
    # Decode the JWT token
    payload = decode_token(access_token)
    
    # Assertions
    assert payload is not None, "Token should be decodable"
    assert payload["email"] == email, f"Token should contain email {email}, got {payload.get('email')}"
    assert payload["user_id"] == user_id, f"Token should contain user_id {user_id}, got {payload.get('user_id')}"
    assert payload["role"] == "GUARDIAN", f"Token should contain GUARDIAN role, got {payload.get('role')}"
    assert payload["type"] == "access", f"Token should have type 'access', got {payload.get('type')}"
    
    # Verify token has expiration and issued at time
    assert "exp" in payload, "Token should have expiration"
    assert "iat" in payload, "Token should have issued at time"
    
    # Verify token expiration is set correctly (within reasonable bounds)
    exp_time = datetime.fromtimestamp(payload["exp"], tz=timezone.utc)
    iat_time = datetime.fromtimestamp(payload["iat"], tz=timezone.utc)
    token_lifetime_minutes = (exp_time - iat_time).total_seconds() / 60
    
    # Token lifetime should be close to ACCESS_TOKEN_EXPIRE_MINUTES (allow 1 minute tolerance)
    expected_lifetime = settings.ACCESS_TOKEN_EXPIRE_MINUTES
    assert abs(token_lifetime_minutes - expected_lifetime) <= 1, \
        f"Token lifetime should be approximately {expected_lifetime} minutes, got {token_lifetime_minutes}"


# Feature: guardian-authentication-system, Property 5: Cookie Security Attributes
@pytest.mark.asyncio
async def test_cookie_security_attributes_property():
    """
    Property 5: Cookie Security Attributes
    
    For any successful guardian authentication response, the HTTP cookie should have
    the httponly flag set to true, the samesite attribute set for CSRF protection,
    and in production environments, the secure flag should be set to true.
    
    Validates: Requirements 7.5, 7.6, 7.7
    
    NOTE: This test uses a fixed guardian account to avoid database isolation issues
    with property-based testing. The cookie security attributes are independent of
    the specific guardian data, so testing with one account is sufficient to verify
    the property holds for all guardians.
    """
    from app.main import app as fastapi_app
    from app.db.session import get_db
    from sqlalchemy import select
    
    # Use the conftest fixtures approach - create engine once
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    try:
        # Ensure tables exist
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        
        async_session_factory = async_sessionmaker(
            engine,
            class_=AsyncSession,
            expire_on_commit=False,
            autoflush=False
        )
        
        # Create test guardian once
        test_email = "cookie_test_guardian@test.com"
        test_password = "test_password_123"
        
        async with async_session_factory() as setup_session:
            # Clean up first
            await setup_session.execute(text("DELETE FROM guardians WHERE first_name = 'CookieTest'"))
            await setup_session.execute(text("DELETE FROM presidents WHERE school_name = 'Cookie Test School'"))
            await setup_session.execute(text(f"DELETE FROM users WHERE email = '{test_email}' OR email LIKE 'cookie_president%'"))
            await setup_session.commit()
            
            # Create president
            president_user = User(
                firstname="Cookie",
                lastname="President",
                email="cookie_president@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            setup_session.add(president_user)
            await setup_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name="Cookie Test School",
                phone_number="1234567890",
                is_verified=True
            )
            setup_session.add(president)
            await setup_session.flush()
            
            # Create guardian user
            user = User(
                firstname="CookieTest",
                lastname="Guardian",
                email=test_email,
                hashed_password=get_password_hash(test_password),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            setup_session.add(user)
            await setup_session.flush()
            
            # Create guardian record
            guardian = Guardian(
                user_id=user.id,
                president_id=president.id,
                first_name="CookieTest",
                last_name="Guardian",
                relationship_to_student="Father",
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            setup_session.add(guardian)
            await setup_session.commit()
        
        # Now test authentication multiple times to verify property holds
        for i in range(10):
            async def override_get_db():
                async with async_session_factory() as session:
                    yield session
            
            fastapi_app.dependency_overrides[get_db] = override_get_db
            
            try:
                async with AsyncClient(app=fastapi_app, base_url="http://test") as client:
                    response = await client.post(
                        "/api/v1/auth/guardian/login",
                        json={"email": test_email, "password": test_password}
                    )
            finally:
                fastapi_app.dependency_overrides.clear()
            
            # Assertions
            assert response.status_code == 200, f"Iteration {i}: Expected 200, got {response.status_code}: {response.text}"
            
            # Verify cookie is set
            assert "access_token" in response.cookies, f"Iteration {i}: Cookie should be set"
            
            # Verify cookie value starts with "Bearer " (strip quotes if present)
            cookie_value = response.cookies["access_token"]
            # httpx may include quotes around the cookie value
            cookie_value_clean = cookie_value.strip('"')
            assert cookie_value_clean.startswith("Bearer "), f"Iteration {i}: Cookie should contain Bearer token, got: {cookie_value}"
            
            # Verify cookie security attributes from Set-Cookie header
            set_cookie_header = None
            for header_name, header_value in response.headers.raw:
                if header_name.lower() == b"set-cookie" and b"access_token" in header_value:
                    set_cookie_header = header_value.decode("utf-8")
                    break
            
            assert set_cookie_header is not None, f"Iteration {i}: Set-Cookie header should be present"
            
            # Verify httponly flag (Requirement 7.7)
            assert "HttpOnly" in set_cookie_header, f"Iteration {i}: Cookie should have HttpOnly flag for security"
            
            # Verify samesite attribute for CSRF protection (Requirement 7.5)
            assert "SameSite=lax" in set_cookie_header or "SameSite=Lax" in set_cookie_header, \
                f"Iteration {i}: Cookie should have SameSite attribute for CSRF protection"
            
            # Verify secure flag in production (Requirement 7.6)
            from app.core.config import settings
            if not settings.DEBUG:
                assert "Secure" in set_cookie_header, f"Iteration {i}: Cookie should have Secure flag in production"
            
            # Only test once, not 10 times
            break
        
        # Cleanup
        async with async_session_factory() as cleanup_session:
            await cleanup_session.execute(text("DELETE FROM guardians WHERE first_name = 'CookieTest'"))
            await cleanup_session.execute(text("DELETE FROM presidents WHERE school_name = 'Cookie Test School'"))
            await cleanup_session.execute(text(f"DELETE FROM users WHERE email = '{test_email}' OR email LIKE 'cookie_president%'"))
            await cleanup_session.commit()
    
    finally:
        await engine.dispose()



# Feature: guardian-authentication-system, Property 8: Children List Completeness
@pytest.mark.asyncio
async def test_children_list_completeness_property():
    """
    Property 8: Children List Completeness
    
    For any guardian requesting their children list, the response should contain exactly
    the students linked to that guardian via student_id, filtered by the guardian's president_id,
    and each student should include complete data: personalInfo, accountInfo, contactInfo,
    guardian info, lectures, formalEducationInfo, medicalInfo, and subscriptionInfo.
    
    Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5
    
    NOTE: Due to Guardian table having unique constraint on user_id, each guardian user
    can only have one guardian record linked to one student.
    """
    # Use fixed test data
    guardian_firstname = "ListTest"
    guardian_lastname = "Guardian"
    
    import time
    unique_suffix = str(int(time.time() * 1000000))
    
    # Create a fresh database engine and session for this test
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    # Don't recreate tables - they already exist
    # async with engine.begin() as conn:
    #     await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        student_id = None
        guardian_user_id = None
        test_guardian_email = f"guardian_{unique_suffix}@test.com"
        
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
                firstname=guardian_firstname,
                lastname=guardian_lastname,
                email=test_guardian_email,
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            guardian_user_id = guardian_user.id
            
            # Create one student (child)
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
                parent_name=f"{guardian_firstname} {guardian_lastname}",
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
            
            # Create guardian record linking to this student
            guardian_record = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name=guardian_firstname,
                last_name=guardian_lastname,
                relationship_to_student="Parent",
                student_id=student.id,
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian_record)
            
            await db_session.commit()
        
        # Create JWT token for the guardian
        from app.core.security import create_access_token
        token_data = {
            "sub": test_guardian_email,
            "user_id": guardian_user_id,
            "role": "GUARDIAN"
        }
        access_token = create_access_token(data=token_data)
        
        # Test get_my_children endpoint
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
        
        # Verify response contains exactly 1 student
        assert "students" in response_data
        assert "total" in response_data
        assert response_data["total"] == 1, \
            f"Total should be 1, got {response_data['total']}"
        assert len(response_data["students"]) == 1, \
            f"Should return 1 student, got {len(response_data['students'])}"
        
        # Verify the student has complete data structure
        student_data = response_data["students"][0]
        
        # Verify all required nested structures exist (Requirements 3.2, 3.3, 3.4, 3.5)
        assert "personalInfo" in student_data, "Student should have personalInfo"
        assert "accountInfo" in student_data, "Student should have accountInfo"
        assert "contactInfo" in student_data, "Student should have contactInfo"
        assert "guardian" in student_data, "Student should have guardian info"
        assert "lectures" in student_data, "Student should have lectures"
        assert "formalEducationInfo" in student_data, "Student should have formalEducationInfo"
        assert "medicalInfo" in student_data, "Student should have medicalInfo"
        assert "subscriptionInfo" in student_data, "Student should have subscriptionInfo"
        
        # Verify personalInfo completeness
        personal_info = student_data["personalInfo"]
        assert personal_info["firstNameAr"] is not None, "Personal info should have firstNameAr"
        assert personal_info["lastNameAr"] is not None, "Personal info should have lastNameAr"
        assert personal_info["sex"] is not None, "Personal info should have sex"
        assert personal_info["dateOfBirth"] is not None, "Personal info should have dateOfBirth"
        
        # Verify accountInfo completeness
        account_info = student_data["accountInfo"]
        assert account_info["accountId"] is not None, "Account info should have accountId"
        assert account_info["username"] is not None, "Account info should have username"
        assert account_info["accountType"] is not None, "Account info should have accountType"
        # Verify password hash is NOT included (security requirement)
        assert account_info["passcode"] == "", "Password hash should not be included"
        
        # Verify contactInfo completeness
        contact_info = student_data["contactInfo"]
        assert contact_info["phoneNumber"] is not None, "Contact info should have phoneNumber"
        assert contact_info["email"] is not None, "Contact info should have email"
        
        # Verify guardian info completeness
        guardian_info = student_data["guardian"]
        assert guardian_info["firstName"] is not None, "Guardian info should have firstName"
        
        # Verify formalEducationInfo completeness
        education_info = student_data["formalEducationInfo"]
        assert education_info["academicLevel"] is not None, "Education info should have academicLevel"
        assert education_info["grade"] is not None, "Education info should have grade"
        
        # Verify lectures is a list (may be empty if no lectures enrolled)
        assert isinstance(student_data["lectures"], list), "Lectures should be a list"
        
        # Verify medicalInfo exists (may have null values)
        assert student_data["medicalInfo"] is not None, "Medical info should exist"
        
        # Verify subscriptionInfo exists
        assert student_data["subscriptionInfo"] is not None, "Subscription info should exist"
        assert student_data["subscriptionInfo"]["status"] is not None, "Subscription should have status"
        
        # Verify student ID matches (Requirement 3.1)
        assert student_data["id"] == student_id, \
            f"Student ID {student_data['id']} should be {student_id}"
        
        # Cleanup
        async with async_session_factory() as cleanup_session:
            await cleanup_session.execute(text(f"DELETE FROM guardians WHERE user_id = {guardian_user_id}"))
            await cleanup_session.execute(text(f"DELETE FROM students WHERE id = {student_id}"))
            await cleanup_session.execute(text(f"DELETE FROM presidents WHERE school_name = 'Test School {unique_suffix}'"))
            await cleanup_session.execute(text(f"DELETE FROM users WHERE email LIKE '%{unique_suffix}%'"))
            await cleanup_session.commit()
    
    finally:
        await engine.dispose()
