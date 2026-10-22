"""scope student attendance to lecture and use calendar dates

Revision ID: 008
Revises: 007
Create Date: 2026-10-15
"""
from alembic import op
import sqlalchemy as sa


revision = "008"
down_revision = "007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("attendances", sa.Column("lecture_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "fk_attendances_lecture_id_lectures",
        "attendances",
        "lectures",
        ["lecture_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index("ix_attendances_lecture_id", "attendances", ["lecture_id"])
    op.alter_column(
        "attendances",
        "date",
        existing_type=sa.String(length=10),
        type_=sa.Date(),
        existing_nullable=False,
        postgresql_using=(
            "CASE "
            "WHEN date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN date::date "
            "WHEN date ~ '^[0-9]{2}-[0-9]{2}-[0-9]{4}$' THEN make_date("
            "substring(date from 7 for 4)::integer, "
            "substring(date from 4 for 2)::integer, "
            "substring(date from 1 for 2)::integer) "
            "ELSE NULL END"
        ),
    )
    op.drop_index("ix_attendances_student_date_president", table_name="attendances")
    op.create_index(
        "ix_attendances_student_lecture_date_president",
        "attendances",
        ["student_id", "lecture_id", "date", sa.text("COALESCE(president_id, -1)")],
        unique=True,
    )


def downgrade() -> None:
    bind = op.get_bind()
    conflict = bind.execute(sa.text("""
        SELECT student_id, date, COALESCE(president_id, -1)
        FROM attendances
        GROUP BY student_id, date, COALESCE(president_id, -1)
        HAVING count(*) > 1
        LIMIT 1
    """)).first()
    if conflict:
        raise RuntimeError("Cannot downgrade: multiple lecture attendance records exist for a student/date")

    op.drop_index("ix_attendances_student_lecture_date_president", table_name="attendances")
    op.alter_column(
        "attendances",
        "date",
        existing_type=sa.Date(),
        type_=sa.String(length=10),
        existing_nullable=False,
        postgresql_using="to_char(date, 'DD-MM-YYYY')",
    )
    op.drop_index("ix_attendances_lecture_id", table_name="attendances")
    op.drop_constraint("fk_attendances_lecture_id_lectures", "attendances", type_="foreignkey")
    op.drop_column("attendances", "lecture_id")
    op.create_index(
        "ix_attendances_student_date_president",
        "attendances",
        ["student_id", "date", sa.text("COALESCE(president_id, -1)")],
        unique=True,
    )
