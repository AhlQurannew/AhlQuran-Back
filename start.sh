#!/bin/sh
# Single-container start for hosts without separate migrate/seed jobs (e.g. Render free tier).
# Stops at the first failure so a broken migration never starts the server.
set -e

alembic upgrade head
python -m app.cli.admin seed
exec uvicorn app.main:app --host 0.0.0.0 --port "${PORT:-8000}"
