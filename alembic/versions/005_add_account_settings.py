"""add account settings and token versioning

Revision ID: 005
Revises: 004
Create Date: 2026-10-14
"""
from alembic import op
import sqlalchemy as sa

revision = "005"
down_revision = "004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("users", sa.Column("auth_version", sa.Integer(), server_default="0", nullable=False))
    op.add_column("admins", sa.Column("auth_version", sa.Integer(), server_default="0", nullable=False))
    op.create_table(
        "account_preferences",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("user_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=True),
        sa.Column("admin_id", sa.Integer(), sa.ForeignKey("admins.id", ondelete="CASCADE"), nullable=True),
        sa.Column("timezone", sa.String(64), nullable=False, server_default="Africa/Algiers"),
        sa.Column("reduce_motion", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.CheckConstraint("(user_id IS NOT NULL) <> (admin_id IS NOT NULL)", name="ck_account_preferences_single_owner"),
        sa.UniqueConstraint("user_id", name="uq_account_preferences_user"),
        sa.UniqueConstraint("admin_id", name="uq_account_preferences_admin"),
    )


def downgrade() -> None:
    op.drop_table("account_preferences")
    op.drop_column("admins", "auth_version")
    op.drop_column("users", "auth_version")
