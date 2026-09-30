#!/bin/bash

echo "=================================================="
echo "  Rebuilding Backend with Auto-Migration Support"
echo "=================================================="
echo ""

# Stop containers
echo "1. Stopping containers..."
docker-compose down

# Rebuild backend
echo ""
echo "2. Rebuilding backend container..."
docker-compose build backend

# Start services
echo ""
echo "3. Starting services..."
docker-compose up -d

# Wait a bit for startup
echo ""
echo "4. Waiting for backend to start..."
sleep 5

# Show logs
echo ""
echo "5. Checking startup logs..."
docker-compose logs backend | tail -30

echo ""
echo "=================================================="
echo "  ✅ Done!"
echo "=================================================="
echo ""
echo "Migrations should have run automatically."
echo "Check above for migration output."
echo ""
echo "To verify supervisor was fixed:"
echo "  docker-compose exec db psql -U ahlquran_user -d ahlquran_db -c"
echo "    \"SELECT u.id, u.firstname, s.president_id"
echo "     FROM users u"
echo "     LEFT JOIN supervisors s ON s.user_id = u.id"
echo "     WHERE u.email = 'zertal@zertal.com';\""
echo ""
