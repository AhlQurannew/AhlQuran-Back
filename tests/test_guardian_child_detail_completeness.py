"""
Minimal test for guardian child detail completeness

Feature: guardian-authentication-system
Property 11: Child Detail Completeness
Validates: Requirements 4.4, 4.5, 4.6, 4.7, 4.8
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
async def test_child_detail_response_completeness():
    """Validates response contains all required fields (Requirements 4.4-4.8)"""
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            p_user = User(firstname="P", lastname="C", email="pc@t.com", hashed_password=get_password_hash("p"),
                        role=UserRoleEnum.PRESIDENT, is_active=True)
            db_session.add(p_user)
            await db_session.flush()
            
            president = President(user_id=p_user.id, school_name="S", phone_number="1", is_verified=True)
            db_session.add(president)
            await db_session.flush()
            
            g_user = User(firstname="G", lastname="C", email="gc@t.com", hashed_password=get_password_hash("p"),
                        role=UserRoleEnum.GUARDIAN, is_active=True)
            db_session.add(g_user)
            await db_session.flush()
            
            s_user = User(firstname="S", lastname="C", email="sc@t.com", hashed_password=get_password_hash("p"),
                        role=UserRoleEnum.STUDENT, is_active=True)
            db_session.add(s_user)
            await db_session.flush()
            
            student = Student(user_id=s_user.id, president_id=president.id, enrollment_date=datetime.now(timezone.utc),
                            created_by_id=p_user.id)
            db_session.add(student)
            await db_session.flush()
            
            guardian = Guardian(user_id=g_user.id, president_id=president.id, first_name="G", last_name="C",
                              relationship_to_student="F", student_id=student.id, created_at=datetime.now(timezone.utc),
                              created_by_id=p_user.id)
            db_session.add(guardian)
            await db_session.commit()
            
            student_id = student.id
        
        token = create_access_token({"sub": "gc@t.com", "user_id": g_user.id, "role": "GUARDIAN"})
        
        from app.db.session import get_db
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                response = await client.get(f"/api/v1/guardians/my-children/{student_id}", cookies={"access_token": token})
        finally:
            app.dependency_overrides.clear()
        
        assert response.status_code == 200
        data = response.json()
        
        required = ["id", "personalInfo", "accountInfo", "contactInfo", "guardian", "lectures",
                   "formalEducationInfo", "medicalInfo", "subscriptionInfo"]
        for field in required:
            assert field in data
        
        assert data["personalInfo"]["firstNameAr"] == "S"
        assert data["accountInfo"]["username"] == "sc@t.com"
        assert isinstance(data["lectures"], list)
        assert "password" not in str(data).lower()
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
