from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
import logging

# Import from session instead of base
from app.db.session import engine, SessionLocal
from app.db.base import Base
from app.models.user import User, UserRoleEnum
from app.models.admin import Admin
from app.core.security import get_password_hash

logger = logging.getLogger(__name__)

async def create_tables():
    async with engine.begin() as conn:
        # Create all tables
        await conn.run_sync(Base.metadata.create_all)
    
    logger.info("✅ Database tables created successfully")

async def create_initial_admin():
    async with SessionLocal() as session:
        # Check if admin exists
        result = await session.execute(
            select(Admin).where(Admin.user == "admin")
        )
        existing_admin = result.scalar_one_or_none()
        
        if existing_admin:
            logger.info("😉 Admin user already exists, skipping creation")
            return
        
        # Create admin user
        admin_user = Admin(
            user="admin",
            password="admin123",
        )
        
        session.add(admin_user)
        await session.commit()
        await session.refresh(admin_user)

        logger.info("✅ Initial admin created")

async def init_db():
    try:
        logger.info("🔄 Initializing database...")
        
        # Import all models to register them with Base
        import app.models
        
        # Ensure all registered tables (including attendances & teacher_attendances) exist
        await create_tables()
        
        logger.info("✅ Database initialization complete!")
        
    except Exception as e:
        logger.error(f"❌ Database initialization failed: {str(e)}")
        raise