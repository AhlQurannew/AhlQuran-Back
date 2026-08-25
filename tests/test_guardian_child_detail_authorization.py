"""
Minimal test for guardian child detail authorization

Feature: guardian-authentication-system
Property 10: Child Detail Authorization
Validates: Requirements 4.1, 4.2
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
async def test_guardian_authorization_boundary():
    """Validates guardians can only access linked children (Requirements 4.1, 4.2)"""
    engine = create_async_engine(TEST_DATABASE_URL, poolclass=NullPool, echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    
    async_session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    try:
        async with async_session_factory() as db_session:
            president_user = User(firstname="P", lastname="T", email="p@t.com",
                                hashed_password=get_password_hash("p"), role=UserRoleEnum.PRESIDENT, is_active=True)
            db_session.add(president_user)
            await db_session.flush()
            
            president = President(user_id=president_user.id, school_name="S", phone_number="1", is_verified=True)
            db_session.add(president)
            await db_session.flush()
            
            guardian_user = User(firstname="G", lastname="T", email="g@t.com",
                               hashed_password=get_password_hash("p"), role=UserRoleEnum.GUARDIAN, is_active=True)
            db_session.add(guardian_user)
            await db_session.flush()
            
            linked_user = User(firstname="L", lastname="S", email="l@t.com",
                             hashed_password=get_password_hash("p"), role=UserRoleEnum.STUDENT, is_active=True)
            db_session.add(linked_user)
            await db_session.flush()
            
            linked_student = Student(user_id=linked_user.id, president_id=president.id,
                                   enrollment_date=datetime.now(timezone.utc), created_by_id=president_user.id)
            db_session.add(linked_student)
            await db_session.flush()
            
            unlinked_user = User(firstname="U", lastname="S", email="u@t.com",
                               hashed_password=get_password_hash("p"), role=UserRoleEnum.STUDENT, is_active=True)
            db_session.add(unlinked_user)
            await db_session.flush()
            
            unlinked_student = Student(user_id=unlinked_user.id, president_id=president.id,
                                     enrollment_date=datetime.now(timezone.utc), created_by_id=president_user.id)
            db_session.add(unlinked_student)
            await db_session.flush()
            
            guardian = Guardian(user_id=guardian_user.id, president_id=president.id, first_name="G", last_name="T",
                              relationship_to_student="F", student_id=linked_student.id,
                              created_at=datetime.now(timezone.utc), created_by_id=president_user.id)
            db_session.add(guardian)
            await db_session.commit()
            
            linked_id, unlinked_id = linked_student.id, unlinked_student.id
        
        token = create_access_token({"sub": "g@t.com", "user_id": guardian_user.id, "role": "GUARDIAN"})
        
        from app.db.session import get_db
        async def override_get_db():
            async with async_session_factory() as session:
                yield session
        
        app.dependency_overrides[get_db] = override_get_db
        
        try:
            async with AsyncClient(app=app, base_url="http://test") as client:
                linked_resp = await client.get(f"/api/v1/guardians/my-children/{linked_id}", cookies={"access_token": token})
                unlinked_resp = await client.get(f"/api/v1/guardians/my-children/{unlinked_id}", cookies={"access_token": token})
        finally:
            app.dependency_overrides.clear()
        
        assert linked_resp.status_code == 200 and linked_resp.json()["id"] == linked_id
        assert unlinked_resp.status_code == 403
    
    finally:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.drop_all)
        await engine.dispose()
