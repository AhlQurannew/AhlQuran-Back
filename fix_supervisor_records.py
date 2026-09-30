#!/usr/bin/env python3
"""
Fix missing supervisor records for users with SUPERVISOR role.
This script creates supervisor table entries for SUPERVISOR users who don't have one.
"""
import asyncio
from sqlalchemy import select, text
from app.db.session import SessionLocal
from app.models.user import User
from app.models.supervisor import Supervisor
from app.models.president import President


async def fix_supervisor_records():
    """Create missing supervisor records."""
    async with SessionLocal() as db:
        print("=" * 60)
        print("Checking for missing supervisor records...")
        print("=" * 60)
        
        # Find SUPERVISOR users without supervisor records
        result = await db.execute(text("""
            SELECT u.id, u.firstname, u.lastname, u.email
            FROM users u
            LEFT JOIN supervisors s ON s.user_id = u.id
            WHERE u.role = 'SUPERVISOR'
            AND s.id IS NULL
        """))
        missing = result.fetchall()
        
        if not missing:
            print("✓ No missing supervisor records found.")
            print("  All SUPERVISOR users have their supervisor table entries.")
            return
            
        print(f"✗ Found {len(missing)} users with SUPERVISOR role but no supervisor record:")
        for user_id, firstname, lastname, email in missing:
            print(f"  - User ID {user_id}: {firstname} {lastname} ({email})")
        
        print("\nLooking for a president to assign them to...")
        
        # Get first president
        pres_result = await db.execute(select(President).limit(1))
        president = pres_result.scalar_one_or_none()
        
        if not president:
            print("\n✗ ERROR: No president found in the system!")
            print("  Cannot create supervisor records without a president.")
            print("  Please create a president first.")
            return
        
        print(f"✓ Found president ID {president.id}")
        print(f"\nCreating supervisor records...")
        
        # Create supervisor records
        created_count = 0
        for user_id, firstname, lastname, email in missing:
            await db.execute(text("""
                INSERT INTO supervisors (user_id, president_id, created_by_id, created_at)
                VALUES (:user_id, :president_id, :created_by_id, NOW())
            """), {
                "user_id": user_id,
                "president_id": president.id,
                "created_by_id": president.user_id
            })
            print(f"  ✓ Created supervisor record for {firstname} {lastname} (user ID {user_id})")
            created_count += 1
        
        await db.commit()
        print("\n" + "=" * 60)
        print(f"SUCCESS: Created {created_count} supervisor records.")
        print("=" * 60)


if __name__ == "__main__":
    asyncio.run(fix_supervisor_records())
