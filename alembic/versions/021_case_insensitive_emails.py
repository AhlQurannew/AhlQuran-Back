"""Login emails are unique whatever their capitals.

Stores existing emails trimmed and lower-cased, then adds a unique index on lower(email) so that
"T.Name@x.dz" can no longer be created next to "t.name@x.dz" (two such accounts made sign-in fail).
If old data already holds such a pair, the index is skipped (and logged) rather than blocking startup.

Revision ID: 021
Revises: 020
"""
import logging

from alembic import op
import sqlalchemy as sa


revision = "021"
down_revision = "020"
branch_labels = None
depends_on = None

logger = logging.getLogger("alembic.runtime.migration")


def upgrade() -> None:
    bind = op.get_bind()
    # Normalize every email whose normalized form is not already taken by another account.
    bind.execute(sa.text("""
        UPDATE users u SET email = lower(btrim(u.email))
        WHERE u.email <> lower(btrim(u.email))
          AND NOT EXISTS (
              SELECT 1 FROM users o WHERE o.id <> u.id AND lower(btrim(o.email)) = lower(btrim(u.email))
          )
    """))
    clashes = bind.execute(sa.text(
        "SELECT lower(email) FROM users GROUP BY lower(email) HAVING count(*) > 1"
    )).scalars().all()
    if clashes:
        logger.warning("Case-insensitive email index skipped: %d email(s) are used by several accounts: %s",
                       len(clashes), ", ".join(clashes[:20]))
        return
    op.create_index("uq_users_email_lower", "users", [sa.text("lower(email)")], unique=True)


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS uq_users_email_lower")
