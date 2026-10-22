"""Add local message attachments and explicit admin chat senders.

Revision ID: 011
Revises: 010
"""
from alembic import op
import sqlalchemy as sa


revision = "011"
down_revision = "010"
branch_labels = None
depends_on = None

def upgrade() -> None:
    bind = op.get_bind()
    if bind.dialect.name == "postgresql":
        op.execute("ALTER TYPE senderrole ADD VALUE IF NOT EXISTS 'chief_supervisor'")
        op.execute("ALTER TYPE senderrole ADD VALUE IF NOT EXISTS 'student'")
        op.execute("ALTER TYPE senderrole ADD VALUE IF NOT EXISTS 'guardian'")
        op.execute("ALTER TYPE senderrole ADD VALUE IF NOT EXISTS 'admin'")

    with op.batch_alter_table("messages") as batch:
        batch.alter_column(
            "sender_id",
            existing_type=sa.Integer(),
            nullable=True,
        )
        batch.add_column(sa.Column("admin_sender_id", sa.Integer(), nullable=True))
        batch.create_foreign_key(
            "fk_messages_admin_sender_id_admins",
            "admins",
            ["admin_sender_id"],
            ["id"],
            ondelete="CASCADE",
        )
        batch.create_check_constraint(
            "ck_messages_exactly_one_sender",
            "(sender_id IS NOT NULL AND admin_sender_id IS NULL) OR "
            "(sender_id IS NULL AND admin_sender_id IS NOT NULL)",
        )

    op.create_index("ix_messages_admin_sender_id", "messages", ["admin_sender_id"])

    op.create_table(
        "message_attachments",
        sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
        sa.Column(
            "message_id",
            sa.Integer(),
            sa.ForeignKey("messages.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("storage_path", sa.String(length=512), nullable=False, unique=True),
        sa.Column("filename", sa.String(length=255), nullable=False),
        sa.Column("content_type", sa.String(length=127), nullable=False),
        sa.Column("size", sa.BigInteger(), nullable=False),
    )
    op.create_index("ix_message_attachments_id", "message_attachments", ["id"])
    op.create_index("ix_message_attachments_message_id", "message_attachments", ["message_id"])


def downgrade() -> None:
    bind = op.get_bind()
    # Added-role messages cannot be represented by the previous sender enum / FK.
    op.execute("DELETE FROM messages WHERE sender_role IN ('chief_supervisor', 'student', 'guardian', 'admin')")
    op.drop_index("ix_message_attachments_message_id", table_name="message_attachments")
    op.drop_index("ix_message_attachments_id", table_name="message_attachments")
    op.drop_table("message_attachments")
    op.drop_index("ix_messages_admin_sender_id", table_name="messages")

    with op.batch_alter_table("messages") as batch:
        batch.drop_constraint("ck_messages_exactly_one_sender", type_="check")
        batch.drop_constraint("fk_messages_admin_sender_id_admins", type_="foreignkey")
        batch.drop_column("admin_sender_id")
        batch.alter_column("sender_id", existing_type=sa.Integer(), nullable=False)

    if bind.dialect.name == "postgresql":
        op.execute("CREATE TYPE senderrole_legacy AS ENUM ('teacher', 'supervisor', 'president')")
        op.execute(
            "ALTER TABLE messages ALTER COLUMN sender_role TYPE senderrole_legacy "
            "USING sender_role::text::senderrole_legacy"
        )
        op.execute("DROP TYPE senderrole")
        op.execute("ALTER TYPE senderrole_legacy RENAME TO senderrole")
