"""Announcements (إعلانات) with attachments, and per-account "seen" times for the sidebar red dots.

Revision ID: 022
Revises: 021
"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision = "022"
down_revision = "021"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "announcements",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("body", sa.Text(), nullable=True),
        sa.Column("audience", postgresql.ARRAY(sa.String(length=30)), nullable=False),
        sa.Column("author_admin_id", sa.Integer(), sa.ForeignKey("admins.id", ondelete="SET NULL"), nullable=True),
        sa.Column("author_name", sa.String(length=200), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.text("now()")),
    )
    op.create_index("ix_announcements_created_at", "announcements", ["created_at"])
    op.create_index("ix_announcements_author_admin_id", "announcements", ["author_admin_id"])
    op.create_table(
        "announcement_attachments",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("announcement_id", sa.Integer(), sa.ForeignKey("announcements.id", ondelete="CASCADE"), nullable=False),
        sa.Column("storage_path", sa.String(length=512), nullable=False, unique=True),
        sa.Column("filename", sa.String(length=255), nullable=False),
        sa.Column("content_type", sa.String(length=127), nullable=False),
        sa.Column("size", sa.BigInteger(), nullable=False),
    )
    op.create_index("ix_announcement_attachments_announcement_id", "announcement_attachments", ["announcement_id"])
    op.add_column("account_preferences", sa.Column("announcements_seen_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("account_preferences", sa.Column("messages_seen_at", sa.DateTime(timezone=True), nullable=True))


def downgrade() -> None:
    op.drop_column("account_preferences", "messages_seen_at")
    op.drop_column("account_preferences", "announcements_seen_at")
    op.drop_index("ix_announcement_attachments_announcement_id", table_name="announcement_attachments")
    op.drop_table("announcement_attachments")
    op.drop_index("ix_announcements_author_admin_id", table_name="announcements")
    op.drop_index("ix_announcements_created_at", table_name="announcements")
    op.drop_table("announcements")
