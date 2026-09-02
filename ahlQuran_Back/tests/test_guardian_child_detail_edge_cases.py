"""
Minimal edge case tests for guardian child detail endpoint

Feature: guardian-authentication-system
Task: 7.4 Write unit tests for edge cases
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

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "postgresql+asyncpg://test_user:test_password@test_db:5432/test_db"
)


@pytest.mark.asyncio
async def test_multi_tenancy_isolation():
    """Validates guardian cannot access student from different president"""
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            p1_user = User(firstname="P1", lastname="T", email="p1@t.com", hashed_password=get_password_hash("p"),
                         role=UserRoleEnum.PRESIDENT, is_active=True)
            db_session.add(p1_user)
            await db_session.flush()
            
            p1 = President(user_id=p1_user.id, school_name="S1", phone_number="1", is_verified=True)
            db_session.add(p1)
            await db_session.flush()
            
            p2_user = User(firstname="P2", lastname="T", email="p2@t.com", hashed_password=get_password_hash("p"),
                         role=UserRoleEnum.PRESIDENT, is_active=True)
            db_session.add(p2_user)
            await db_session.flush()
            
            p2 = President(user_id=p2_user.id, school_name="S2", phone_number="2", is_verified=True)
            db_session.add(p2)
            await db_session.flush()
            
            g_user = User(firstname="G", lastname="T", email="g@t.com", hashed_password=get_password_hash("p"),
                        role=UserRoleEnum.GUARDIAN, is_active=True)
            db_session.add(g_user)
            await db_session.flush()
            
            s1_user = User(firstname="S1", lastname="T", email="s1@t.com", hashed_password=get_password_hash("p"),
                         role=UserRoleEnum.STUDENT, is_active=True)
            db_session.add(s1_user)
            await db_session.flush()
            
            s1 = Student(user_id=s1_user.id, president_id=p1.id, enrollment_date=datetime.now(timezone.utc),
                       created_by_id=p1_user.id)
            db_session.add(s1)
            await db_session.flush()
            
            s2_user = User(firstname="S2", lastname="T", email="s2@t.com", hashed_password=get_password_hash("p"),
                         role=UserRoleEnum.STUDENT, is_active=True)
            db_session.add(s2_user)
            await db_session.flush()
            
            s2 = Student(user_id=s2_user.id, president_id=p2.id, enrollment_date=datetime.now(timezone.utc),
                       created_by_id=p2_user.id)
            db_session.add(s2)
            await db_session.flush()
            
            guardian = Guardian(user_id=g_user.id, president_id=p1.id, first_name="G", last_name="T",
                              relationship_to_student="F", student_id=s1.id, created_at=datetime.now(timezone.utc),
                              created_by_id=p1_user.id)
            db_session.add(guardian)
            await db_session.commit()
            
            s2_id = s2.id
        
        token = create_access_token({"sub": "g@t.com", "user_id": g_user.id, "role": "GUARDIAN"})
        
        from app.db.session import get_db
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.get(f"/api/v1/guardians/my-children/{s2_id}", cookies={"access_token": token})
        finally:
            app.dependency_overrides.clear()
        
        assert response.status_code in [403, 404]
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
