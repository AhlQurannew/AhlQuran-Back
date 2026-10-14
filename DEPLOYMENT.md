# Deployment Runbook

## Configuration

Provide `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DATABASE_URL`, and `SECRET_KEY` through the deployment secret manager or an untracked `.env` file for local Compose. Use a randomly generated secret key and a database password that is URL-encoded in `DATABASE_URL`. Set `CORS_ORIGINS` to the exact frontend origins. Keep `DEBUG=false` in every shared environment.

The `.env` file and SQL backups are intentionally excluded from Git and Docker build context. Store backups outside the source tree, encrypt them, restrict access, and define retention and restore drills.

## Release

1. Build and publish one immutable backend image for the release.
2. Back up the target database and verify the backup can be read.
3. Run the `migrate` job for that image and wait for exit status zero.
4. Start or roll out the backend only after migration success.
5. Verify `/health/ready`, authentication, and tenant-scoped read/write flows; monitor application and database errors.

Compose encodes this dependency: PostgreSQL health precedes the one-shot `migrate` service, and the backend waits for that service to complete successfully. In orchestrated production environments, run the same migration command as a serialized release job, not once per application replica.

## Migration Rules

- Treat applied migrations as immutable. Add a new revision for every later schema change.
- The initial revision `000` is a fixed schema snapshot; do not modify it after deployment.
- Test upgrades against an empty PostgreSQL database and a recent copy of existing production schema/data.
- Review data migrations for row loss, tenant reassignment, lock duration, and rollback behavior.
- Before the first release of this migration chain, audit attendance duplicates: revision `002` deletes older duplicate rows before adding its unique index. Also review orphan supervisor users and their tenant assignments: revision `003` assigns them to the first available president. Back up affected rows and confirm intended ownership before running these revisions against any database containing data.
- Do not stamp a database or restore a full SQL dump to bypass migration errors. Inspect its schema and Alembic revision first; only stamp after proving they match.
- Prefer forward corrective migrations in production. Do not automatically downgrade or delete the PostgreSQL volume as a rollback strategy.

## Administrator Provisioning

There is no built-in production username or password. After migrations succeed, create an administrator interactively:

```sh
docker compose run --rm backend python -m app.cli.admin create
```

The command prompts for a username and password without placing the password in shell history. Existing legacy plaintext admin passwords are upgraded to hashes after a successful login; rotate them and confirm all admin rows use hashes as part of production cutover.

## Operations

```sh
docker compose ps
docker compose logs --tail=200 migrate backend
docker compose exec db sh -c 'psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"'
```

The database has no host-published port in this Compose configuration. Expose it only through an explicitly secured private network when operational access is required.
