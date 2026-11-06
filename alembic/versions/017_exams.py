"""Exams per circle and their results (attendance, mark, notes).

Revision ID: 017
Revises: 016
"""
from alembic import op
import sqlalchemy as sa


revision = "017"
down_revision = "016"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "exams",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("president_id", sa.Integer(), sa.ForeignKey("presidents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("lecture_id", sa.Integer(), sa.ForeignKey("lectures.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("exam_type", sa.String(length=50), nullable=True),
        sa.Column("exam_date", sa.Date(), nullable=False),
        sa.Column("max_mark", sa.Numeric(6, 2), nullable=False, server_default="20"),
        sa.Column("pass_mark", sa.Numeric(6, 2), nullable=False, server_default="10"),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("created_by_id", sa.Integer(), sa.ForeignKey("users.id", ondelete="SET NULL"), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("max_mark > 0", name="ck_exams_max_mark_positive"),
        sa.CheckConstraint("pass_mark >= 0 AND pass_mark <= max_mark", name="ck_exams_pass_mark_range"),
    )
    op.create_index("ix_exams_president_id", "exams", ["president_id"])
    op.create_index("ix_exams_lecture_id", "exams", ["lecture_id"])
    op.create_index("ix_exams_exam_date", "exams", ["exam_date"])

    op.create_table(
        "exam_results",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("exam_id", sa.Integer(), sa.ForeignKey("exams.id", ondelete="CASCADE"), nullable=False),
        sa.Column("student_id", sa.Integer(), sa.ForeignKey("students.id", ondelete="CASCADE"), nullable=False),
        sa.Column("attendance", sa.String(length=20), nullable=False, server_default="present"),
        sa.Column("mark", sa.Numeric(6, 2), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=True),
        sa.UniqueConstraint("exam_id", "student_id", name="uq_exam_results_exam_student"),
        sa.CheckConstraint("attendance IN ('present', 'absent', 'excused')", name="ck_exam_results_attendance"),
        sa.CheckConstraint("mark IS NULL OR mark >= 0", name="ck_exam_results_mark_positive"),
    )
    op.create_index("ix_exam_results_exam_id", "exam_results", ["exam_id"])
    op.create_index("ix_exam_results_student_id", "exam_results", ["student_id"])


def downgrade() -> None:
    op.drop_index("ix_exam_results_student_id", table_name="exam_results")
    op.drop_index("ix_exam_results_exam_id", table_name="exam_results")
    op.drop_table("exam_results")
    op.drop_index("ix_exams_exam_date", table_name="exams")
    op.drop_index("ix_exams_lecture_id", table_name="exams")
    op.drop_index("ix_exams_president_id", table_name="exams")
    op.drop_table("exams")
