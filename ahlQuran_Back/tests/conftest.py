"""
Pytest configuration and fixtures for guardian authentication tests
"""
import pytest
import asyncio
import os
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool
from sqlalchemy import text
from app.db.base import Base
from app.models.user import User, UserRoleEnum
from app.models.guardian import Guardian
from app.models.student import Student
from app.models.teacher import Teacher
from app.models.president import President
from app.models.supervisor import Supervisor
from app.core.security import get_password_hash

# Test database URL - use persistent PostgreSQL test database
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)

# Configure pytest-asyncio
pytest_plugins = ('pytest_asyncio',)


@pytest.fixture(scope="session")
def event_loop():
    """Create an event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture(scope="session")
async def db_engine():
    """Create a test database engine that persists for the entire test session."""
    engine = create_async_engine(
        TEST_DATABASE_URL,
        poolclass=NullPool,
        echo=False
    )
    
    # Create all tables once at the start
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    yield engine
    
    # Drop all tables at the end
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    
    await engine.dispose()


@pytest.fixture(scope="function")
async def db_session(db_engine) -> AsyncGenerator[AsyncSession, None]:
    """Create a test database session with automatic cleanup after each test."""
    async_session = async_sessionmaker(
        db_engine,
        class_=AsyncSession,
        expire_on_commit=False
    )
    
    async with async_session() as session:
        yield session
        
        # Clean up all tables after each test
        try:
            # Delete in order to respect foreign key constraints
            await session.execute(text("DELETE FROM session_participations"))
            await session.execute(text("DELETE FROM achievements"))
            await session.execute(text("DELETE FROM attendance"))
            await session.execute(text("DELETE FROM teacher_attendances"))
            await session.execute(text("DELETE FROM messages"))
            await session.execute(text("DELETE FROM sessions"))
            await session.execute(text("DELETE FROM lectures"))
            await session.execute(text("DELETE FROM guardians"))
            await session.execute(text("DELETE FROM students"))
            await session.execute(text("DELETE FROM teachers"))
            await session.execute(text("DELETE FROM supervisors"))
            await session.execute(text("DELETE FROM presidents"))
            await session.execute(text("DELETE FROM users"))
            await session.commit()
        except Exception:
            await session.rollback()
            raise


@pytest.fixture(scope="function")
async def guardian_user(db_session: AsyncSession) -> User:
    """Create a test guardian user."""
    user = User(
        firstname="Test",
        lastname="Guardian",
        email="guardian@test.com",
        hashed_password=get_password_hash("password123"),
        role=UserRoleEnum.GUARDIAN,
        is_active=True
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user


@pytest.fixture(scope="function")
async def teacher_user(db_session: AsyncSession) -> User:
    """Create a test teacher user."""
    user = User(
        firstname="Test",
        lastname="Teacher",
        email="teacher@test.com",
        hashed_password=get_password_hash("password123"),
        role=UserRoleEnum.TEACHER,
        is_active=True
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user


@pytest.fixture(scope="function")
async def student_user(db_session: AsyncSession) -> User:
    """Create a test student user."""
    user = User(
        firstname="Test",
        lastname="Student",
        email="student@test.com",
        hashed_password=get_password_hash("password123"),
        role=UserRoleEnum.STUDENT,
        is_active=True
    )
    db_session.add(user)
    await db_session.flush()
    await db_session.refresh(user)
    return user
