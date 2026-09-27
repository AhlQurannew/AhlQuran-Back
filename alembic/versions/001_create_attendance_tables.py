"""create attendance tables

Revision ID: 001
Revises: 
Create Date: 2026-09-27

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '001'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    bind = op.get_bind()
    inspector = sa.inspect(bind)
    existing_tables = inspector.get_table_names()

    # Create attendances table for students if missing
    if 'attendances' not in existing_tables:
        op.create_table('attendances',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('student_id', sa.Integer(), nullable=False),
        sa.Column('president_id', sa.Integer(), nullable=True),
        sa.Column('date', sa.String(length=10), nullable=False),
        sa.Column('status', sa.Enum('present', 'late', 'absent', 'excused', name='attendancestatus'), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['president_id'], ['presidents.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['student_id'], ['students.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_attendances_id'), 'attendances', ['id'], unique=False)
        op.create_index(op.f('ix_attendances_student_id'), 'attendances', ['student_id'], unique=False)
        op.create_index(op.f('ix_attendances_president_id'), 'attendances', ['president_id'], unique=False)
        op.create_index(op.f('ix_attendances_date'), 'attendances', ['date'], unique=False)

    # Create teacher_attendances table if missing
    if 'teacher_attendances' not in existing_tables:
        op.create_table('teacher_attendances',
        sa.Column('id', sa.Integer(), nullable=False),
        sa.Column('teacher_id', sa.Integer(), nullable=False),
        sa.Column('president_id', sa.Integer(), nullable=True),
        sa.Column('date', sa.String(length=10), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.text('now()')),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['president_id'], ['presidents.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['teacher_id'], ['teachers.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
        )
        op.create_index(op.f('ix_teacher_attendances_id'), 'teacher_attendances', ['id'], unique=False)
        op.create_index(op.f('ix_teacher_attendances_teacher_id'), 'teacher_attendances', ['teacher_id'], unique=False)
        op.create_index(op.f('ix_teacher_attendances_president_id'), 'teacher_attendances', ['president_id'], unique=False)
        op.create_index(op.f('ix_teacher_attendances_date'), 'teacher_attendances', ['date'], unique=False)
        
        # Create unique index for teacher + date to prevent duplicates
        op.create_index('ix_teacher_attendances_teacher_date', 'teacher_attendances', ['teacher_id', 'date'], unique=True)


def downgrade() -> None:
    # Drop teacher_attendances table
    op.drop_index('ix_teacher_attendances_teacher_date', table_name='teacher_attendances')
    op.drop_index(op.f('ix_teacher_attendances_date'), table_name='teacher_attendances')
    op.drop_index(op.f('ix_teacher_attendances_president_id'), table_name='teacher_attendances')
    op.drop_index(op.f('ix_teacher_attendances_teacher_id'), table_name='teacher_attendances')
    op.drop_index(op.f('ix_teacher_attendances_id'), table_name='teacher_attendances')
    op.drop_table('teacher_attendances')
    
    # Drop attendances table
    op.drop_index(op.f('ix_attendances_date'), table_name='attendances')
    op.drop_index(op.f('ix_attendances_president_id'), table_name='attendances')
    op.drop_index(op.f('ix_attendances_student_id'), table_name='attendances')
    op.drop_index(op.f('ix_attendances_id'), table_name='attendances')
    op.drop_table('attendances')
    
    # Drop enum type for student attendance status
    op.execute('DROP TYPE IF EXISTS attendancestatus')
