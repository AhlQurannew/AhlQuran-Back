"""Add verified contact email and one-time admin email verification tokens.

Revision ID: 010
Revises: 009
"""
from alembic import op
import sqlalchemy as sa


revision = "010"
down_revision = "009"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("admins", sa.Column("email", sa.String(length=255), nullable=True))
    op.add_column("admins", sa.Column("email_verified_at", sa.DateTime(timezone=True), nullable=True))
    op.create_index(
        "uq_admins_email_lower",
        "admins",
        [sa.text("lower(email)")],
        unique=True,
    )
    op.create_table(
        "admin_email_verifications",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column(
            "admin_id",
            sa.Integer(),
            sa.ForeignKey("admins.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("new_email", sa.String(length=255), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False, unique=True),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index(
        "ix_admin_email_verifications_admin_id",
        "admin_email_verifications",
        ["admin_id"],
    )


def downgrade() -> None:
    op.drop_index("ix_admin_email_verifications_admin_id", table_name="admin_email_verifications")
    op.drop_table("admin_email_verifications")
    op.drop_index("uq_admins_email_lower", table_name="admins")
    op.drop_column("admins", "email_verified_at")
    op.drop_column("admins", "email")
