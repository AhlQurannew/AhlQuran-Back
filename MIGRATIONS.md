# Database Migrations Guide

This project uses **Alembic** for database schema migrations.

## How It Works

### Automatic Migrations on Startup

The backend is configured to **automatically run migrations on startup**:

1. When `docker-compose up` is executed, the `migrate` service runs first
2. It waits for the database to be ready
3. Runs `alembic upgrade head` to apply all pending migrations
4. Fixes any missing supervisor records (data consistency check)
5. The backend service starts only after migrations complete successfully

**You don't need to manually run migrations** - they happen automatically when you start the containers.

## Creating New Migrations

### Step 1: Create a Migration File

```bash
cd AhlQuran-Back
docker-compose exec backend alembic revision -m "description_of_changes"
```

This creates a new migration file in `alembic/versions/` with a revision ID.

### Step 2: Edit the Migration File

Open the generated file and implement:
- `upgrade()` - Apply changes (e.g., add columns, create tables)
- `downgrade()` - Revert changes (optional but recommended)

Example:
```python
def upgrade() -> None:
    op.add_column('users', sa.Column('phone', sa.String(20), nullable=True))

def downgrade() -> None:
    op.drop_column('users', 'phone')
```

### Step 3: Apply the Migration

Migrations are applied automatically on next startup, or manually:

```bash
docker-compose exec backend alembic upgrade head
```

## Common Migration Commands

### Check Current Version
```bash
docker-compose exec backend alembic current
```

### View Migration History
```bash
docker-compose exec backend alembic history
```

### Rollback One Migration
```bash
docker-compose exec backend alembic downgrade -1
```

### Rollback to Specific Version
```bash
docker-compose exec backend alembic downgrade <revision_id>
```

### Generate Migration from Model Changes (Auto-detect)
```bash
docker-compose exec backend alembic revision --autogenerate -m "description"
```
⚠️ **Always review auto-generated migrations** - they may not detect all changes correctly.

## Migration Best Practices

### 1. Always Test Migrations
- Test `upgrade()` on a copy of production data
- Test `downgrade()` to ensure rollback works
- Never skip testing migrations

### 2. Make Small, Focused Changes
- One migration = one logical change
- Don't mix unrelated schema changes
- Keep migrations simple and reversible

### 3. Handle Data Migrations Carefully
```python
def upgrade() -> None:
    # Step 1: Add column as nullable
    op.add_column('users', sa.Column('status', sa.String(20), nullable=True))
    
    # Step 2: Populate data
    connection = op.get_bind()
    connection.execute(text("UPDATE users SET status = 'active' WHERE is_active = true"))
    
    # Step 3: Make it non-nullable (optional)
    op.alter_column('users', 'status', nullable=False)
```

### 4. Use Transactions
Alembic uses transactions by default. If a migration fails, changes are rolled back automatically.

### 5. Document Breaking Changes
Add comments explaining:
- Why the change is needed
- What impact it has on existing data
- Any manual steps required

## Troubleshooting

### "Can't locate revision identified by..."
The database version doesn't match migration files. Fix:
```bash
# Check current version in database
docker-compose exec backend alembic current

# Manually set version (use with caution!)
docker-compose exec db psql -U ahlquran_user -d ahlquran_db -c "UPDATE alembic_version SET version_num = '<revision_id>';"
```

### "Target database is not up to date"
```bash
docker-compose exec backend alembic upgrade head
```

### Migration Fails Halfway
1. Check logs: `docker-compose logs backend`
2. Fix the issue in the migration file
3. Rollback: `docker-compose exec backend alembic downgrade -1`
4. Try again: `docker-compose exec backend alembic upgrade head`

## Current Migrations

- **001** - Create attendance tables
- **002** - Add unique constraint to attendances
- **003** - Fix missing supervisor records (data consistency)

## Migration Workflow Summary

```
┌─────────────────────────────────────┐
│   Developer makes model changes     │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Create migration:                  │
│  alembic revision -m "description"  │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Edit migration file:               │
│  - Implement upgrade()              │
│  - Implement downgrade()            │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Commit migration to git            │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Deploy: docker-compose up          │
│  (Migrations run automatically)     │
└─────────────────────────────────────┘
```

## Notes

- Migrations run in the `migrate` service before the backend starts
- The `migrate` service also checks and fixes data consistency issues
- Backend will not start if migrations fail
- Always keep migrations in version control
