"""How the app addresses an account: سيدي (male / unset) or سيدتي (female).

Revision ID: 020
Revises: 019
"""
from alembic import op
import sqlalchemy as sa


revision = "020"
down_revision = "019"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("account_preferences", sa.Column("honorific", sa.String(length=10), nullable=True))


def downgrade() -> None:
    op.drop_column("account_preferences", "honorific")
