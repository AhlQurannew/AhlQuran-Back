"""Unique registration numbers for students/teachers, school & medical info, teacher profile.

Existing rows get a generated number (S<year>-0001 / T<year>-0001, by creation order) so the
unique index can be created and every record has an ID straight away.

Revision ID: 015
Revises: 014
"""
from alembic import op
import sqlalchemy as sa


revision = "015"
down_revision = "014"
branch_labels = None
depends_on = None


def _backfill(table: str, prefix: str, date_column: str) -> None:
    op.execute(f"""
        UPDATE {table} AS t
        SET registration_number = numbered.code
        FROM (
            SELECT id,
                   '{prefix}' || EXTRACT(YEAR FROM COALESCE({date_column}, NOW()))::int || '-' ||
                   LPAD(ROW_NUMBER() OVER (
                       PARTITION BY EXTRACT(YEAR FROM COALESCE({date_column}, NOW())) ORDER BY id
                   )::text, 4, '0') AS code
            FROM {table}
        ) AS numbered
        WHERE t.id = numbered.id AND t.registration_number IS NULL
    """)


def upgrade() -> None:
    with op.batch_alter_table("students") as batch:
        batch.add_column(sa.Column("registration_number", sa.String(length=30), nullable=True))
        batch.add_column(sa.Column("medical_condition", sa.Text(), nullable=True))
        batch.add_column(sa.Column("enrollment_type", sa.String(length=20), nullable=True))
        batch.add_column(sa.Column("start_year", sa.Integer(), nullable=True))

    with op.batch_alter_table("teachers") as batch:
        batch.add_column(sa.Column("registration_number", sa.String(length=30), nullable=True))
        batch.add_column(sa.Column("medical_condition", sa.Text(), nullable=True))
        batch.add_column(sa.Column("speciality", sa.String(length=150), nullable=True))
        batch.add_column(sa.Column("date_of_birth", sa.String(length=20), nullable=True))
        batch.add_column(sa.Column("place_of_birth", sa.String(length=100), nullable=True))
        batch.add_column(sa.Column("phone_number", sa.String(length=20), nullable=True))
        batch.add_column(sa.Column("address", sa.String(length=255), nullable=True))

    _backfill("students", "S", "enrollment_date")
    _backfill("teachers", "T", "hire_date")

    op.create_index("uq_students_registration_number", "students", ["registration_number"], unique=True)
    op.create_index("uq_teachers_registration_number", "teachers", ["registration_number"], unique=True)


def downgrade() -> None:
    op.drop_index("uq_teachers_registration_number", table_name="teachers")
    op.drop_index("uq_students_registration_number", table_name="students")
    with op.batch_alter_table("teachers") as batch:
        for column in ("address", "phone_number", "place_of_birth", "date_of_birth", "speciality",
                       "medical_condition", "registration_number"):
            batch.drop_column(column)
    with op.batch_alter_table("students") as batch:
        for column in ("start_year", "enrollment_type", "medical_condition", "registration_number"):
            batch.drop_column(column)
