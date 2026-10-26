# Deployment Runbook

## Configuration

Provide `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DATABASE_URL`, `SECRET_KEY`, `APP_ENV=production`, `INITIAL_ADMIN_USERNAME`, and `INITIAL_ADMIN_PASSWORD` through the deployment secret manager. Use unique random secrets, URL-encode the database password in `DATABASE_URL`, and set `CORS_ORIGINS` to exact frontend origins. Keep `DEBUG=false` in every shared environment. Production bootstrap passwords must be at least 12 characters; `admin123` is rejected in production.

Administrator contact emails can be saved after confirming the current password. Email changes are not verified and no email is sent in this release; the UI labels saved addresses as unverified. This address is separate from the administrator's username/login.

The `.env` file and SQL backups are intentionally excluded from Git and Docker build context. Store backups outside the source tree, encrypt them, restrict access, and define retention and restore drills.

## Release

1. Build and publish one immutable backend image for the release.
2. Back up the target database and verify the backup can be read.
3. Run the `migrate` job for that image and wait for exit status zero. Revision `010` adds the administrator contact-email and verification-status fields; its token table is retained for possible future verification support but is not used to send email in this release.
4. Start or roll out the backend only after migration success.
5. Verify `/health/ready`, authentication, and tenant-scoped read/write flows; monitor application and database errors.

Compose encodes this dependency: PostgreSQL health precedes the one-shot `migrate` service, `seed-admin` runs only after migrations, and the backend waits for the seed job to complete. The seed is idempotent and does not reset an existing administrator password. In orchestrated production environments, run migrations as a serialized release job, then run the seed job before starting application replicas.

## Migration Rules

- Treat applied migrations as immutable. Add a new revision for every later schema change.
- The initial revision `000` is a fixed schema snapshot; do not modify it after deployment.
- Test upgrades against an empty PostgreSQL database and a recent copy of existing production schema/data.
- Review data migrations for row loss, tenant reassignment, lock duration, and rollback behavior.
- Before the first release of this migration chain, audit attendance duplicates: revision `002` deletes older duplicate rows before adding its unique index. Also review orphan supervisor users and their tenant assignments: revision `003` assigns them to the first available president. Back up affected rows and confirm intended ownership before running these revisions against any database containing data.
- Do not stamp a database or restore a full SQL dump to bypass migration errors. Inspect its schema and Alembic revision first; only stamp after proving they match.
- Prefer forward corrective migrations in production. Do not automatically downgrade or delete the PostgreSQL volume as a rollback strategy.

## Administrator Provisioning

The one-shot seed job provisions the configured administrator after migrations. For manual provisioning or rotation, create an administrator interactively:

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
