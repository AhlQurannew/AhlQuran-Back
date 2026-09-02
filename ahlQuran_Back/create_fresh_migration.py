#!/usr/bin/env python3
"""
Script to create a fresh comprehensive migration for all tables using Docker.
This ensures Docker deployments have all tables properly defined.
"""
import subprocess
import sys
import os

def main():
    print("🔍 Checking current migration status...")
    result = subprocess.run(
        ["docker-compose", "exec", "-T", "web", "alembic", "current"],
        capture_output=True,
        text=True
    )
    print(result.stdout)
    
    if result.returncode != 0:
        print("⚠️  Web container not running. Starting services...")
        subprocess.run(["docker-compose", "up", "-d"])
        print("⏳ Waiting for services to start...")
        import time
        time.sleep(5)
    
    print("\n📋 Creating new comprehensive migration...")
    result = subprocess.run(
        ["docker-compose", "exec", "-T", "web", "alembic", "revision", 
         "--autogenerate", "-m", "comprehensive_schema_all_tables"],
        capture_output=True,
        text=True
    )
    
    if result.returncode == 0:
        print("✅ Migration created successfully!")
        print(result.stdout)
    else:
        print("❌ Error creating migration:")
        print(result.stderr)
        sys.exit(1)
    
    print("\n💡 To apply this migration, run:")
    print("   docker-compose exec web alembic upgrade head")

if __name__ == "__main__":
    main()
