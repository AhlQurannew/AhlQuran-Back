"""Add an avatar image to account preferences (users and admins).

Revision ID: 012
Revises: 011
"""
from alembic import op
import sqlalchemy as sa


revision = "012"
down_revision = "011"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("account_preferences", sa.Column("profile_image", sa.String(length=255), nullable=True))


def downgrade() -> None:
    op.drop_column("account_preferences", "profile_image")
