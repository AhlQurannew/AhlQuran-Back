"""add unique constraint to attendances

Revision ID: 002
Revises: 001
Create Date: 2026-09-27

"""
from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = '002'
down_revision = '001'
branch_labels = None
depends_on = None


def upgrade() -> None:
    """Add unique constraint to prevent duplicate attendance records for same student on same date."""
    
    # First, check if the index already exists
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_indexes = [idx['name'] for idx in inspector.get_indexes('attendances')]
    
    # Only create if it doesn't exist
    if 'ix_attendances_student_date_president' not in existing_indexes:
        # Remove any potential duplicates before adding the constraint
        # Keep the most recent record (highest id) for each student+date+president combination
        bind.execute(sa.text("""
            DELETE FROM attendances a1
            USING attendances a2
            WHERE a1.student_id = a2.student_id
              AND a1.date = a2.date
              AND COALESCE(a1.president_id, -1) = COALESCE(a2.president_id, -1)
              AND a1.id < a2.id;
        """))
        
        # Create unique index for student + date + president to prevent duplicates
        # Using COALESCE to handle NULL president_id values
        op.create_index(
            'ix_attendances_student_date_president',
            'attendances',
            ['student_id', 'date', sa.text('COALESCE(president_id, -1)')],
            unique=True
        )


def downgrade() -> None:
    """Remove the unique constraint."""
    op.drop_index('ix_attendances_student_date_president', table_name='attendances')
