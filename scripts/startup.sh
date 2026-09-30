#!/bin/sh
set -e

echo "=== Backend Startup ==="

# Wait for database
echo "Waiting for database..."
while ! pg_isready -h db -p 5432 -U ahlquran_user -d ahlquran_db > /dev/null 2>&1; do
  sleep 1
done
echo "✓ Database is ready"

# Run migrations
echo "Running database migrations..."
alembic upgrade head
echo "✓ Migrations complete"

echo "=== Startup Complete ==="

# Start the application
exec "$@"
