"""Inspectors (مفتش): admin accounts with role "inspector", created and managed by an admin.

Revision ID: 019
Revises: 018
"""
from alembic import op
import sqlalchemy as sa


revision = "019"
down_revision = "018"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("admins", sa.Column("full_name", sa.String(length=150), nullable=True))
    op.add_column("admins", sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()))
    # An inspector depends on the admin who created it: removing that admin removes its inspectors.
    op.execute("UPDATE admins SET created_by_id = NULL WHERE created_by_id IS NOT NULL AND created_by_id NOT IN (SELECT id FROM admins)")
    op.create_foreign_key("fk_admins_created_by", "admins", "admins", ["created_by_id"], ["id"], ondelete="CASCADE")
    op.execute("UPDATE admins SET role = 'admin' WHERE role IS NULL OR role = ''")


def downgrade() -> None:
    op.drop_constraint("fk_admins_created_by", "admins", type_="foreignkey")
    op.drop_column("admins", "is_active")
    op.drop_column("admins", "full_name")
