"""Create chief supervisor profiles required by school management.

Revision ID: 009
Revises: 008
"""
from alembic import op
import sqlalchemy as sa


revision = "009"
down_revision = "008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    if not inspector.has_table("chief_supervisors"):
        op.create_table(
            "chief_supervisors",
            sa.Column("id", sa.Integer(), primary_key=True, nullable=False),
            sa.Column(
                "user_id",
                sa.Integer(),
                sa.ForeignKey("users.id", ondelete="CASCADE"),
                nullable=False,
                unique=True,
            ),
            sa.Column(
                "president_id",
                sa.Integer(),
                sa.ForeignKey("presidents.id", ondelete="CASCADE"),
                nullable=False,
            ),
            sa.Column(
                "created_by_id",
                sa.Integer(),
                sa.ForeignKey("users.id", ondelete="SET NULL"),
                nullable=True,
            ),
            sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        )
        op.create_index("ix_chief_supervisors_id", "chief_supervisors", ["id"])
        op.create_index("ix_chief_supervisors_president_id", "chief_supervisors", ["president_id"])


def downgrade() -> None:
    bind = op.get_bind()
    if sa.inspect(bind).has_table("chief_supervisors"):
        op.drop_index("ix_chief_supervisors_president_id", table_name="chief_supervisors")
        op.drop_index("ix_chief_supervisors_id", table_name="chief_supervisors")
        op.drop_table("chief_supervisors")
