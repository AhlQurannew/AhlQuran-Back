# Ahl Quran Backend

FastAPI service for the Ahl El Quran school management system.

## Local Setup

1. Copy `.env.example` to `.env` and set unique database credentials, a random `SECRET_KEY` of at least 32 characters, `APP_ENV=development`, and an administrator password. URL-encode special characters in the database URL.
2. Start the services with `docker compose up --build -d`.
3. Check `docker compose ps` and `docker compose logs migrate seed-admin backend`. The API starts only after migration and seeding succeed.
4. The one-shot `seed-admin` job creates the configured administrator after migrations. For local development, set `INITIAL_ADMIN_USERNAME=admin` and `INITIAL_ADMIN_PASSWORD=admin123`; never use that password in production.

The API listens on port 8000 by default. Swagger UI is available at `/docs`. PostgreSQL is not published on the host; use `docker compose exec db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"` for local database access.

## Database Changes

Alembic is the only schema management mechanism. Update a model, create and review a migration, then test it on a disposable PostgreSQL database before deployment. Never edit a migration that has been applied in a shared environment; add a new forward migration instead.

The `migrate` Compose service applies `alembic upgrade head`, then `seed-admin` creates the configured administrator before the API starts. Application startup does not create tables or insert default users. See [DEPLOYMENT.md](DEPLOYMENT.md) for migration and recovery procedures.

## Project Layout

- `app/api/v1/routes/`: HTTP and WebSocket endpoints
- `app/core/`: settings, security, authorization, and tenant resolution
- `app/db/`: SQLAlchemy metadata and async session setup
- `app/models/` and `app/schemas/`: persistence and API contracts
- `app/cli/`: explicit operator commands
- `alembic/versions/`: immutable, versioned schema changes
- `tests/`: automated tests; install development dependencies from `requirements-dev.txt`

## Runtime Checks

- `GET /health/live` reports that the process is running.
- `GET /health/ready` checks database connectivity.

Do not use `docker compose down -v` for routine restarts; it deletes the local PostgreSQL volume.
