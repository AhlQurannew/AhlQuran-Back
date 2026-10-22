"""model guardian-to-student links as one-to-many

Revision ID: 007
Revises: 006
Create Date: 2026-10-14
"""
from alembic import op
import sqlalchemy as sa


revision = "007"
down_revision = "006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    connection = op.get_bind()

    invalid_links = connection.execute(sa.text(
        """
        SELECT students.id, students.guardian_id
        FROM students
        LEFT JOIN guardians ON guardians.id = students.guardian_id
        WHERE students.guardian_id IS NOT NULL AND guardians.id IS NULL
        LIMIT 1
        """
    )).first()
    if invalid_links:
        raise RuntimeError(
            "Cannot migrate guardian links: students.guardian_id contains an unknown guardian "
            f"(student={invalid_links.id}, guardian={invalid_links.guardian_id}). Repair this data and retry."
        )

    cross_school_link = connection.execute(sa.text(
        """
        SELECT students.id, guardians.id AS guardian_id
        FROM students
        JOIN guardians ON guardians.id = students.guardian_id
        WHERE guardians.president_id IS DISTINCT FROM students.president_id
        LIMIT 1
        """
    )).first()
    if cross_school_link:
        raise RuntimeError(
            "Cannot migrate guardian links across organizations "
            f"(student={cross_school_link.id}, guardian={cross_school_link.guardian_id}). Repair this data and retry."
        )

    invalid_legacy_link = connection.execute(sa.text(
        """
        SELECT guardians.id AS guardian_id, guardians.student_id
        FROM guardians
        JOIN students ON students.id = guardians.student_id
        WHERE guardians.president_id IS DISTINCT FROM students.president_id
        LIMIT 1
        """
    )).first()
    if invalid_legacy_link:
        raise RuntimeError(
            "Cannot migrate legacy guardian links across organizations "
            f"(student={invalid_legacy_link.student_id}, guardian={invalid_legacy_link.guardian_id}). Repair this data and retry."
        )

    conflicting_legacy_link = connection.execute(sa.text(
        """
        SELECT legacy.student_id, legacy.id AS legacy_guardian_id,
               students.guardian_id AS current_guardian_id
        FROM guardians AS legacy
        JOIN students ON students.id = legacy.student_id
        WHERE students.guardian_id IS NOT NULL
          AND students.guardian_id <> legacy.id
        LIMIT 1
        """
    )).first()
    if conflicting_legacy_link:
        raise RuntimeError(
            "Cannot migrate guardian links: the direct student link conflicts with the legacy guardian link "
            f"(student={conflicting_legacy_link.student_id}, legacy_guardian="
            f"{conflicting_legacy_link.legacy_guardian_id}, current_guardian="
            f"{conflicting_legacy_link.current_guardian_id}). Resolve the conflict and retry."
        )

    ambiguous_legacy_link = connection.execute(sa.text(
        """
        SELECT guardians.student_id AS student_id
        FROM guardians
        WHERE guardians.student_id IS NOT NULL
        GROUP BY guardians.student_id
        HAVING COUNT(DISTINCT guardians.id) > 1
        LIMIT 1
        """
    )).first()
    if ambiguous_legacy_link:
        raise RuntimeError(
            "Cannot migrate guardian links: multiple legacy guardians refer to the same student "
            f"(student={ambiguous_legacy_link.student_id}). Resolve the conflict and retry."
        )

    op.execute(sa.text(
        """
        UPDATE students
        SET guardian_id = legacy.guardian_id
        FROM (
            SELECT DISTINCT ON (student_id) student_id, id AS guardian_id
            FROM guardians
            WHERE student_id IS NOT NULL
            ORDER BY student_id, id
        ) AS legacy
        WHERE students.id = legacy.student_id
          AND students.guardian_id IS NULL
        """
    ))

    op.create_foreign_key(
        "fk_students_guardian_id_guardians",
        "students",
        "guardians",
        ["guardian_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_index("ix_students_guardian_id", "students", ["guardian_id"], unique=False)
    op.drop_column("guardians", "student_id")


def downgrade() -> None:
    connection = op.get_bind()
    guardian_with_many_students = connection.execute(sa.text(
        """
        SELECT guardian_id
        FROM students
        WHERE guardian_id IS NOT NULL
        GROUP BY guardian_id
        HAVING COUNT(*) > 1
        LIMIT 1
        """
    )).first()
    if guardian_with_many_students:
        raise RuntimeError(
            "Cannot downgrade guardian links without losing data: guardian "
            f"{guardian_with_many_students.guardian_id} has multiple students."
        )

    op.add_column("guardians", sa.Column("student_id", sa.Integer(), nullable=True))
    op.create_foreign_key(
        "guardians_student_id_fkey",
        "guardians",
        "students",
        ["student_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.execute(sa.text(
        """
        UPDATE guardians
        SET student_id = students.id
        FROM students
        WHERE students.guardian_id = guardians.id
        """
    ))
    op.drop_index("ix_students_guardian_id", table_name="students")
    op.drop_constraint("fk_students_guardian_id_guardians", "students", type_="foreignkey")
