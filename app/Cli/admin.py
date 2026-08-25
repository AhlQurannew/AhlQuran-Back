import asyncio
import sys
from sqlalchemy import select

from app.db.session import SessionLocal, engine
# from app.models.user import User, UserRoleEnum
from app.models.admin import Admin


async def create_admin(user: str, password: str):
    """Create a new admin user via CLI"""
    async with SessionLocal() as session:
        # Check if user already exists
        result = await session.execute(
            select(Admin).where(Admin.user == user)
        )
        existing_admin = result.scalar_one_or_none()
        
        if existing_admin:
            print(f"❌ Admin with name {user} already exists!")
            return False
        
        # Create admin Admin
        admin = Admin(
            user=user,
            password=password,
        )
        
        session.add(admin) 
        await session.commit() 
        await session.refresh(admin)
        
        print(f"✅ Admin Admin created successfully!\n")
        print(f"   ID: {admin.id}")
        print(f"   User: {admin.user}")
        return True


async def list_admins():
    """List all admin Admins"""
    async with SessionLocal() as session:
        result = await session.execute(
            select(Admin) 
        )
        admins = result.scalars().all()
        
        if not admins:
            print("❌ No admin users found!")
            return
        
        print(f"\n✅ Found {len(admins)} admin user(s):\n")
        for admin in admins:
            print(f"  ID: {admin.id}")
            print(f"  User: {admin.user}")
            print("-" * 50)


async def deactivate_admin(email: str):
    """Deactivate an admin user"""
    async with SessionLocal() as session:
        result = await session.execute(
            select(Admin).where(
                Admin.email == email,
            )
        )
        admin = result.scalar_one_or_none()
        
        if not admin:
            print(f"❌ Admin user with email {email} not found!")
            return False
        
        admin.is_active = False
        await session.commit()
        
        print(f"✅ Admin user {email} deactivated successfully!")
        return True


def main():
    """CLI entry point"""
    if len(sys.argv) < 2: 
        print("Usage:")
        print("  python -m app.cli.admin create <user> <password>")
        print("  python -m app.cli.admin list")
        print("  python -m app.cli.admin deactivate <user>")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "create":
        if len(sys.argv) != 4:
            print("Usage: python -m app.cli.admin create <user> <password>") 
            sys.exit(1)
        
        user = sys.argv[2]
        password = sys.argv[3]
        
        asyncio.run(create_admin(user, password))
    
    elif command == "list":
        asyncio.run(list_admins())
    
    elif command == "deactivate":
        if len(sys.argv) != 3:
            print("Usage: python -m app.cli.admin deactivate <user>")
            sys.exit(1)
        
        user = sys.argv[2]
        asyncio.run(deactivate_admin(user))
    
    else:
        print(f"❌ Unknown command: {command}")
        sys.exit(1)


if __name__ == "__main__":
    main()