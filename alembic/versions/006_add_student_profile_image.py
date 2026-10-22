"""add student profile image storage key

Revision ID: 006
Revises: 005
Create Date: 2026-10-14
"""
from alembic import op
import sqlalchemy as sa

revision = "006"
down_revision = "005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("students", sa.Column("profile_image", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("students", "profile_image")
