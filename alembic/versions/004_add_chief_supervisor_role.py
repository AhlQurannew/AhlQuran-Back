"""add chief supervisor role

Revision ID: 004
Revises: 003
Create Date: 2026-10-14
"""
from alembic import op


revision = "004"
down_revision = "003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TYPE userroleenum ADD VALUE IF NOT EXISTS 'CHIEF_SUPERVISOR'")


def downgrade() -> None:
    # PostgreSQL does not support removing an enum value safely.
    pass
