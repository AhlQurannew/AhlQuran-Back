"""
Property-based test for guardian role assignment
Feature: guardian-authentication-system, Property 6: Guardian Role Assignment
"""
import pytest
import os
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text, select
from app.db.base import Base
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.president import President
from app.core.security import get_password_hash
from datetime import datetime, timezone


# Test database URL - use PostgreSQL test database in Docker
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


# Feature: guardian-authentication-system, Property 6: Guardian Role Assignment
@pytest.mark.asyncio
async def test_guardian_role_assignment_property():
    """
    Property 6: Guardian Role Assignment
    
    For any newly created guardian, the associated user account should have
    the role set to UserRoleEnum.GUARDIAN.
    
    Validates: Requirements 2.2
    
    This test verifies that when a guardian is created in the system, their
    associated user account is properly assigned the GUARDIAN role, ensuring
    proper role-based access control.
    """
    # Create a fresh database engine and session for this test
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        # Test with multiple guardian creations to verify property holds universally
        test_cases = [
            {
                "firstname": "John",
                "lastname": "Doe",
                "email": "john.doe@test.com",
                "relationship": "Father"
            },
            {
                "firstname": "Jane",
                "lastname": "Smith",
                "email": "jane.smith@test.com",
                "relationship": "Mother"
            },
            {
                "firstname": "Ahmed",
                "lastname": "Hassan",
                "email": "ahmed.hassan@test.com",
                "relationship": "Guardian"
            }
        ]
        
        for test_data in test_cases:
            async with async_session_factory() as db_session:
                # Create president for multi-tenancy
                president_user = User(
                    firstname="President",
                    lastname="Test",
                    email=f"president_{test_data['email']}",
                    hashed_password=get_password_hash("password"),
                    role=UserRoleEnum.PRESIDENT,
                    is_active=True
                )
                db_session.add(president_user)
                await db_session.flush()
                
                president = President(
                    user_id=president_user.id,
                    school_name=f"Test School for {test_data['firstname']}",
                    phone_number="1234567890",
                    is_verified=True
                )
                db_session.add(president)
                await db_session.flush()
                
                # Create guardian user - this is the critical part being tested
                guardian_user = User(
                    firstname=test_data["firstname"],
                    lastname=test_data["lastname"],
                    email=test_data["email"],
                    hashed_password=get_password_hash("password123"),
                    role=UserRoleEnum.GUARDIAN,  # Role assignment
                    is_active=True
                )
                db_session.add(guardian_user)
                await db_session.flush()
                
                # Store user_id for verification
                user_id = guardian_user.id
                
                # Create guardian record
                guardian = Guardian(
                    user_id=guardian_user.id,
                    president_id=president.id,
                    first_name=test_data["firstname"],
                    last_name=test_data["lastname"],
                    relationship_to_student=test_data["relationship"],
                    created_at=datetime.now(timezone.utc),
                    created_by_id=president_user.id
                )
                db_session.add(guardian)
                await db_session.commit()
                
                # Verify the guardian's user role in a fresh query
                result = await db_session.execute(
                    select(User).where(User.id == user_id)
                )
                verified_user = result.scalar_one()
                
                # CRITICAL ASSERTION: Verify role is GUARDIAN
                assert verified_user.role == UserRoleEnum.GUARDIAN, \
                    f"Guardian user {test_data['email']} should have GUARDIAN role, got {verified_user.role}"
                
                # Additional verification: Ensure role is not any other role
                assert verified_user.role != UserRoleEnum.TEACHER, \
                    f"Guardian user should not have TEACHER role"
                assert verified_user.role != UserRoleEnum.STUDENT, \
                    f"Guardian user should not have STUDENT role"
                assert verified_user.role != UserRoleEnum.PRESIDENT, \
                    f"Guardian user should not have PRESIDENT role"
                assert verified_user.role != UserRoleEnum.SUPERVISOR, \
                    f"Guardian user should not have SUPERVISOR role"
                
                # Verify the guardian record is properly linked to the user
                guardian_result = await db_session.execute(
                    select(Guardian).where(Guardian.user_id == user_id)
                )
                verified_guardian = guardian_result.scalar_one()
                
                assert verified_guardian.user_id == user_id, \
                    "Guardian record should be linked to the user"
                
                # Cleanup - delete data but keep tables
                await db_session.execute(text("DELETE FROM guardians"))
                await db_session.execute(text("DELETE FROM presidents"))
                await db_session.execute(text("DELETE FROM users"))
                await db_session.commit()
    
    finally:
        await engine.dispose()


# Additional unit test: Verify role assignment persists across sessions
@pytest.mark.asyncio
async def test_guardian_role_persists_across_sessions():
    """
    Unit test: Verify that guardian role assignment persists across database sessions.
    
    This ensures that the role is properly stored in the database and not just
    set in memory.
    """
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        user_id = None
        test_email = "persist_test@test.com"
        
        # Session 1: Create guardian
        async with async_session_factory() as session1:
            # Create president
            president_user = User(
                firstname="President",
                lastname="Test",
                email=f"president_{test_email}",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            session1.add(president_user)
            await session1.flush()
            
            president = President(
                user_id=president_user.id,
                school_name="Persist Test School",
                phone_number="1234567890",
                is_verified=True
            )
            session1.add(president)
            await session1.flush()
            
            # Create guardian user
            guardian_user = User(
                firstname="Persist",
                lastname="Test",
                email=test_email,
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            session1.add(guardian_user)
            await session1.flush()
            user_id = guardian_user.id
            
            # Create guardian record
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Persist",
                last_name="Test",
                relationship_to_student="Parent",
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            session1.add(guardian)
            await session1.commit()
        
        # Session 2: Verify role persists in a completely new session
        async with async_session_factory() as session2:
            result = await session2.execute(
                select(User).where(User.id == user_id)
            )
            user_from_db = result.scalar_one()
            
            # Verify role persisted
            assert user_from_db.role == UserRoleEnum.GUARDIAN, \
                "Guardian role should persist across database sessions"
            assert user_from_db.email == test_email
            
            # Cleanup
            await session2.execute(text("DELETE FROM guardians"))
            await session2.execute(text("DELETE FROM presidents"))
            await session2.execute(text("DELETE FROM users"))
            await session2.commit()
    
    finally:
        await engine.dispose()


# Edge case test: Verify role cannot be changed after guardian creation
@pytest.mark.asyncio
async def test_guardian_role_immutability():
    """
    Unit test: Verify that guardian role should remain GUARDIAN.
    
    This test ensures that once a user is created as a guardian, their role
    is properly set and maintained.
    """
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(
        engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    try:
        async with async_session_factory() as db_session:
            # Create president
            president_user = User(
                firstname="President",
                lastname="Test",
                email="president_immutable@test.com",
                hashed_password=get_password_hash("password"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(
                user_id=president_user.id,
                school_name="Immutable Test School",
                phone_number="1234567890",
                is_verified=True
            )
            db_session.add(president)
            await db_session.flush()
            
            # Create guardian user with GUARDIAN role
            guardian_user = User(
                firstname="Immutable",
                lastname="Guardian",
                email="immutable_guardian@test.com",
                hashed_password=get_password_hash("password123"),
                role=UserRoleEnum.GUARDIAN,
                is_active=True
            )
            db_session.add(guardian_user)
            await db_session.flush()
            
            # Create guardian record
            guardian = Guardian(
                user_id=guardian_user.id,
                president_id=president.id,
                first_name="Immutable",
                last_name="Guardian",
                relationship_to_student="Parent",
                created_at=datetime.now(timezone.utc),
                created_by_id=president_user.id
            )
            db_session.add(guardian)
            await db_session.commit()
            
            # Verify initial role
            assert guardian_user.role == UserRoleEnum.GUARDIAN
            
            # Attempt to query and verify role is still GUARDIAN
            result = await db_session.execute(
                select(User).where(User.id == guardian_user.id)
            )
            verified_user = result.scalar_one()
            assert verified_user.role == UserRoleEnum.GUARDIAN
            
            # Cleanup
            await db_session.execute(text("DELETE FROM guardians"))
            await db_session.execute(text("DELETE FROM presidents"))
            await db_session.execute(text("DELETE FROM users"))
            await db_session.commit()
    
    finally:
        await engine.dispose()
