"""Lock the internal school accounts that were created with a shared password.

Every school created from the admin panel got a placeholder PRESIDENT user
(system.<timestamp>@school.internal) whose password was the same fixed string for all schools.
Give them a random, discarded password and end any session they may have.

Revision ID: 023
Revises: 022
"""
import secrets

import bcrypt

from alembic import op
import sqlalchemy as sa


revision = "023"
down_revision = "022"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.get_bind().execute(
        sa.text(
            "UPDATE users SET hashed_password = :hash, auth_version = auth_version + 1 "
            "WHERE role = 'PRESIDENT' AND lower(email) LIKE '%@school.internal'"
        ),
        {"hash": bcrypt.hashpw(secrets.token_urlsafe(32).encode(), bcrypt.gensalt()).decode()},
    )


def downgrade() -> None:
    # The old shared password must never come back.
    pass
