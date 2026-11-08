"""School images, and the default login photo as a built-in (removable, restorable) slide.

Revision ID: 018
Revises: 017
"""
from alembic import op
import sqlalchemy as sa


revision = "018"
down_revision = "017"
branch_labels = None
depends_on = None

BUILTIN_PATH = "builtin/masjid.jpg"


def upgrade() -> None:
    op.add_column("presidents", sa.Column("image_path", sa.String(length=255), nullable=True))
    op.add_column("login_slides", sa.Column("is_builtin", sa.Boolean(), nullable=False, server_default=sa.false()))
    # The photo the login page always showed becomes the first slide, so the admin sees and manages it.
    op.execute(
        sa.text(
            "INSERT INTO login_slides (image_path, position, is_builtin, created_at) "
            "SELECT :path, 0, true, now() WHERE NOT EXISTS (SELECT 1 FROM login_slides WHERE is_builtin)"
        ).bindparams(path=BUILTIN_PATH)
    )


def downgrade() -> None:
    op.execute("DELETE FROM login_slides WHERE is_builtin")
    op.drop_column("login_slides", "is_builtin")
    op.drop_column("presidents", "image_path")
