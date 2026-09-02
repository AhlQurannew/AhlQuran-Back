# Guide

## Scope
This guide documents the implemented Docker refactor for this repository:
1. Keep only root-level compose files.
2. Use one-shot containers for migrations and restore.
3. Remove shell-script bootstrap flow.
4. Keep backup-first workflow for PostgreSQL data.

Implemented date: 2026-04-17.

## What Was Implemented
1. Added root compose files:
- `docker-compose.dev.yml`
- `docker-compose.prod.yml`

2. Removed legacy orchestration/scripts:
- `docker-compose.yml` (root old file)
- `ahlQuran_Back/docker-compose.yml`
- `ahlQuran_Back/init-db.sh`
- `ahlQuran_Back/backup_database.sh`
- `ahlQuran_Back/backup_database.bat`
- `ahlQuran_Back/restore_database.sh`
- `ahlQuran_Back/restore_database.bat`
- `ahlQuran_Back/run_migrations.sh`
- `ahlQuran_Back/run_migrations.bat`

3. Cleaned backend Dockerfile:
- Removed script bootstrap assumptions (`init-db.sh`, `dos2unix`).
- Kept app code + Alembic + `database_backup.sql`.

4. Added one-shot restore service (`db_restore`) in both compose files using profile `restore`.

## Service Map And Dependencies
Both dev and prod files use the same dependency model:
1. `db` (PostgreSQL)
- Persistent named volume (`postgres_data_dev` or `postgres_data_prod`).
- Healthcheck with `pg_isready`.

2. `migrate` (one-shot)
- Depends on `db` healthy.
- Runs Alembic and exits.
- `restart: "no"`.

3. `backend` (FastAPI)
- Depends on `db` healthy.
- Depends on `migrate` completed successfully.
- Starts only after DB is ready and migrations finish.

4. `db_restore` (one-shot, manual)
- Only runs when profile `restore` is enabled.
- Depends on `db` healthy.
- Restores from `ahlQuran_Back/database_backup.sql` and exits.

## Environment Loading Model
Environment keys are loaded from:
- `env_file: ./ahlQuran_Back/.env` for `db`, `migrate`, `backend`, and `db_restore`.

Important behavior:
1. Service runtime keys come from `ahlQuran_Back/.env`.
2. Optional host port overrides come from shell at command time (example: `DB_PORT=55433`, `BACKEND_PORT=18000`).
3. If you change DB credentials in `.env`, existing initialized Postgres volumes keep old credentials; you must recreate the volume or use matching credentials.

## Migration Strategy (Current Working Solution)

### Why `alembic upgrade head` was not used
The migration tree has multiple heads/roots (`f6g7h8i9j0k1`, `add_multi_tenancy`, `z9y8x7w6v5u4`, plus `comprehensive_all_tables` root), so `upgrade head` fails.

### Implemented migrate command
Both compose files run this sequence in `migrate`:
1. `alembic upgrade f6g7h8i9j0k1`
2. `alembic upgrade z9y8x7w6v5u4`
3. `alembic upgrade add_multi_tenancy`

This sequence was validated on a fresh isolated stack and is repeat-safe.

### Long-term migration cleanup (recommended)
1. Fix `z9y8x7w6v5u4` to point to the intended parent revision (not `down_revision = None`).
2. Decide whether `comprehensive_all_tables` remains in history or is retired.
3. Create proper Alembic merge revision(s) so one canonical `head` exists.
4. Switch `migrate` back to `alembic upgrade head` after cleanup.

## Backup-First Workflow

### Export database (pg_dump)
Preferred for your case (single app DB):

```bash
docker compose -f docker-compose.dev.yml exec -T db \
  sh -lc 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB"' \
  > backups/pre_refactor_YYYYMMDD_HHMMSS.sql
```

Alternative with container name:

```bash
docker exec -t <db_container> pg_dump -U <user> -d <database> > backup.sql
```

A pre-refactor export was already generated during implementation:
- `backups/pre_refactor_20260417_193413.sql`

## How To Run

### Development
```bash
docker compose -f docker-compose.dev.yml up --build
```

### Production
```bash
docker compose -f docker-compose.prod.yml up -d --build
```

### Restore from SQL backup (manual one-shot)
```bash
docker compose -f docker-compose.dev.yml --profile restore up db_restore
```

For prod:
```bash
docker compose -f docker-compose.prod.yml --profile restore up db_restore
```

## First Build vs Existing Volume
1. First build with empty volume:
- `db` initializes with credentials from `ahlQuran_Back/.env`.
- `migrate` applies schema.
- `backend` starts.

2. Existing volume with old credentials:
- You can see `password authentication failed`.
- Fix by either:
- Using the original credentials that initialized that volume.
- Recreating volume for a clean bootstrap:

```bash
docker compose -f docker-compose.dev.yml down -v
docker compose -f docker-compose.dev.yml up --build
```

## Verification Commands
```bash
docker compose -f docker-compose.dev.yml config
docker compose -f docker-compose.prod.yml config
docker compose -f docker-compose.dev.yml --profile restore config
```

Migration heads check:
```bash
docker compose -f docker-compose.dev.yml run --rm migrate alembic heads
```

## Notes
1. No application business logic was changed in this refactor.
2. The key functional change is orchestration and migration execution flow.
3. If you want, the next step can be a dedicated migration-history cleanup PR to restore single-head Alembic behavior.
