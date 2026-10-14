"""Provision and inspect administrator accounts."""

import asyncio
import getpass
import sys

from sqlalchemy import select

from app.core.security import get_password_hash
from app.db.session import SessionLocal, engine
from app.models.admin import Admin


async def create_admin(username: str, password: str) -> bool:
    try:
        async with SessionLocal() as session:
            result = await session.execute(select(Admin).where(Admin.user == username))
            if result.scalar_one_or_none():
                print(f"Administrator '{username}' already exists.")
                return False

            session.add(
                Admin(
                    user=username,
                    password_hash=get_password_hash(password),
                    role="admin",
                )
            )
            await session.commit()
            print(f"Administrator '{username}' created.")
            return True
    finally:
        await engine.dispose()


async def list_admins() -> None:
    try:
        async with SessionLocal() as session:
            result = await session.execute(select(Admin.id, Admin.user).order_by(Admin.id))
            admins = result.all()
            if not admins:
                print("No administrator accounts found.")
                return
            for admin_id, username in admins:
                print(f"{admin_id}\t{username}")
    finally:
        await engine.dispose()


def main() -> int:
    if len(sys.argv) != 2 or sys.argv[1] not in {"create", "list"}:
        print("Usage: python -m app.cli.admin {create|list}")
        return 2

    if sys.argv[1] == "list":
        asyncio.run(list_admins())
        return 0

    username = input("Administrator username: ").strip()
    password = getpass.getpass("Administrator password: ")
    confirmation = getpass.getpass("Confirm password: ")
    if (
        not username
        or len(password) < 12
        or len(password.encode("utf-8")) > 72
        or password != confirmation
    ):
        print("Use a non-empty username and matching password of 12 to 72 UTF-8 bytes.")
        return 2

    return 0 if asyncio.run(create_admin(username, password)) else 1


if __name__ == "__main__":
    raise SystemExit(main())
