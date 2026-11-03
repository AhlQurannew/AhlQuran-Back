"""Make created_by_id optional and SET NULL on user deletion for school member tables.

Revision 000 created supervisors/teachers/students/guardians.created_by_id as NOT NULL with a
plain foreign key, while the models (and school deletion) expect it to be nullable with
ON DELETE SET NULL. Deleting a school therefore failed with a NOT NULL violation.

Revision ID: 014
Revises: 013
"""
from alembic import op


revision = "014"
down_revision = "013"
branch_labels = None
depends_on = None

TABLES = ("supervisors", "teachers", "students", "guardians")


def upgrade() -> None:
    for table in TABLES:
        constraint = f"{table}_created_by_id_fkey"
        op.execute(f'ALTER TABLE {table} DROP CONSTRAINT IF EXISTS "{constraint}"')
        op.execute(f"ALTER TABLE {table} ALTER COLUMN created_by_id DROP NOT NULL")
        op.execute(
            f'ALTER TABLE {table} ADD CONSTRAINT "{constraint}" '
            f"FOREIGN KEY (created_by_id) REFERENCES users (id) ON DELETE SET NULL"
        )


def downgrade() -> None:
    # Rows may now hold NULL, so the NOT NULL constraint cannot be restored safely; only the
    # foreign key behaviour is reverted.
    for table in TABLES:
        constraint = f"{table}_created_by_id_fkey"
        op.execute(f'ALTER TABLE {table} DROP CONSTRAINT IF EXISTS "{constraint}"')
        op.execute(
            f'ALTER TABLE {table} ADD CONSTRAINT "{constraint}" '
            f"FOREIGN KEY (created_by_id) REFERENCES users (id)"
        )
