"""fix missing supervisor records

Revision ID: 003
Revises: 002
Create Date: 2024-09-30 16:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import text

# revision identifiers, used by Alembic.
revision: str = '003'
down_revision: Union[str, None] = '002'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Create supervisor records for users with SUPERVISOR role who are missing
    their corresponding supervisor table entry.
    """
    connection = op.get_bind()
    
    # Find all SUPERVISOR users who don't have a supervisor record
    result = connection.execute(text("""
        SELECT u.id, u.firstname, u.lastname, u.email
        FROM users u
        LEFT JOIN supervisors s ON s.user_id = u.id
        WHERE u.role = 'SUPERVISOR'
        AND s.id IS NULL
    """))
    
    missing_supervisors = result.fetchall()
    
    if not missing_supervisors:
        return
    
    print(f"Found {len(missing_supervisors)} users with SUPERVISOR role but no supervisor record.")
    
    # Get first available president
    president_result = connection.execute(text("SELECT id, user_id FROM presidents LIMIT 1"))
    president_row = president_result.fetchone()
    
    if not president_row:
        print("WARNING: No presidents found. Skipping supervisor record creation.")
        return
    
    president_id, president_user_id = president_row
    
    # Create supervisor records
    for user_id, firstname, lastname, email in missing_supervisors:
        connection.execute(text("""
            INSERT INTO supervisors (user_id, president_id, created_by_id, created_at)
            VALUES (:user_id, :president_id, :created_by_id, NOW())
        """), {
            "user_id": user_id,
            "president_id": president_id,
            "created_by_id": president_user_id
        })
        print(f"Created supervisor record for user {user_id} ({firstname} {lastname})")


def downgrade() -> None:
    """
    This migration fixes data consistency and should not be downgraded.
    """
    pass
