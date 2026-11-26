"""Provision and inspect administrator accounts."""

import asyncio
import getpass
import os
import sys

from sqlalchemy import select

from app.core.config import settings
from app.core.security import get_password_hash, verify_password
from app.db.session import SessionLocal, engine
from app.models.admin import Admin


async def create_admin(username: str, password: str, *, idempotent: bool = False) -> bool:
    try:
        async with SessionLocal() as session:
            result = await session.execute(select(Admin).where(Admin.user == username))
            if result.scalar_one_or_none():
                print(f"Administrator '{username}' already exists.")
                return idempotent

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


def seed_admin() -> int:
    # Recovery first: it must work even when the bootstrap variables are missing or rejected.
    reset_main_admin_from_env()

    username = os.getenv("INITIAL_ADMIN_USERNAME", "").strip()
    password = os.getenv("INITIAL_ADMIN_PASSWORD", "")
    if not username or not password or len(password.encode("utf-8")) > 72:
        print("Set INITIAL_ADMIN_USERNAME and a password no longer than 72 UTF-8 bytes.")
        return 2
    if settings.APP_ENV == "production" and (
        len(password) < 12 or password == username or password.lower() == "admin123"
    ):
        print("Production bootstrap passwords must be unique and at least 12 characters.")
        return 2

    return 0 if asyncio.run(create_admin(username, password, idempotent=True)) else 1


def _reset_password_problem(password: str) -> str | None:
    if len(password.encode("utf-8")) > 72:
        return "must be at most 72 UTF-8 bytes"
    if len(password) < 12:
        return "must be at least 12 characters"
    if password.lower() in {"admin123", "password123", "123456789012"}:
        return "is too common"
    return None


async def reset_main_admin_password(password: str, preferred_username: str = "") -> str:
    """Set the main administrator's password; returns what happened (never the password)."""
    try:
        async with SessionLocal() as session:
            main_admins = (await session.execute(
                select(Admin).where(Admin.created_by_id.is_(None), Admin.role == "admin").order_by(Admin.id)
            )).scalars().all()
            if not main_admins:
                return "no main administrator account exists"
            # The bootstrap username identifies the account; otherwise the only (or first) main account.
            target = next((a for a in main_admins if a.user.lower() == preferred_username.lower()), None) if preferred_username else None
            if target is None and len(main_admins) > 1:
                names = ", ".join(a.user for a in main_admins)
                return f"several main administrator accounts exist ({names}); set INITIAL_ADMIN_USERNAME to the one to reset"
            target = target or main_admins[0]
            if verify_password(password, target.password_hash) and target.is_active:
                return f"password of '{target.user}' already matches; nothing to do (remove RESET_MAIN_ADMIN_PASSWORD)"
            target.password_hash = get_password_hash(password)
            target.is_active = True
            target.auth_version += 1  # signs out every session opened with the old password
            await session.commit()
            return f"password of '{target.user}' was reset; remove RESET_MAIN_ADMIN_PASSWORD now"
    finally:
        await engine.dispose()


def reset_main_admin_from_env() -> None:
    """Break-glass recovery for hosts without a shell (Render free tier).

    Set RESET_MAIN_ADMIN_PASSWORD on the host, let it restart, sign in, then delete the variable.
    It never stops the server from starting: problems are only printed to the logs.
    """
    password = os.getenv("RESET_MAIN_ADMIN_PASSWORD", "")
    if not password:
        return
    problem = _reset_password_problem(password)
    if problem:
        print(f"RESET_MAIN_ADMIN_PASSWORD ignored: the password {problem}.")
        return
    try:
        outcome = asyncio.run(reset_main_admin_password(password, os.getenv("INITIAL_ADMIN_USERNAME", "").strip()))
    except Exception as exc:  # a failed reset must not keep the API down
        outcome = f"failed ({type(exc).__name__})"
    print(f"Main administrator recovery: {outcome}.")


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
    if len(sys.argv) != 2 or sys.argv[1] not in {"create", "list", "seed"}:
        print("Usage: python -m app.cli.admin {create|list|seed}")
        return 2

    if sys.argv[1] == "seed":
        return seed_admin()

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
