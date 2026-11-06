"""Specialities (تخصصات): circles per speciality with coefficients, and the student's speciality.

Revision ID: 016
Revises: 015
"""
from alembic import op
import sqlalchemy as sa


revision = "016"
down_revision = "015"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "specialities",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("president_id", sa.Integer(), sa.ForeignKey("presidents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("name", sa.String(length=150), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("is_common", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_specialities_president_id", "specialities", ["president_id"])
    # One name per school, case-insensitive.
    op.create_index("uq_specialities_school_name", "specialities", ["president_id", sa.text("lower(name)")], unique=True)

    op.create_table(
        "speciality_lectures",
        sa.Column("speciality_id", sa.Integer(), sa.ForeignKey("specialities.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("lecture_id", sa.Integer(), sa.ForeignKey("lectures.id", ondelete="CASCADE"), primary_key=True),
        sa.Column("coefficient", sa.Numeric(5, 2), nullable=False, server_default="1"),
        sa.CheckConstraint("coefficient > 0", name="ck_speciality_lectures_coefficient_positive"),
    )
    op.create_index("ix_speciality_lectures_lecture_id", "speciality_lectures", ["lecture_id"])

    with op.batch_alter_table("students") as batch:
        batch.add_column(sa.Column("speciality_id", sa.Integer(), nullable=True))
        batch.create_foreign_key("fk_students_speciality_id", "specialities", ["speciality_id"], ["id"], ondelete="SET NULL")
    op.create_index("ix_students_speciality_id", "students", ["speciality_id"])


def downgrade() -> None:
    op.drop_index("ix_students_speciality_id", table_name="students")
    with op.batch_alter_table("students") as batch:
        batch.drop_constraint("fk_students_speciality_id", type_="foreignkey")
        batch.drop_column("speciality_id")
    op.drop_index("ix_speciality_lectures_lecture_id", table_name="speciality_lectures")
    op.drop_table("speciality_lectures")
    op.drop_index("uq_specialities_school_name", table_name="specialities")
    op.drop_index("ix_specialities_president_id", table_name="specialities")
    op.drop_table("specialities")
