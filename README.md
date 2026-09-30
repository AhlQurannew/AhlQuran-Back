# AhlQuran Backend

FastAPI backend for Ahl El Quran School Management System.

## Quick Start

```bash
# Start all services (database + backend)
docker-compose up -d

# View logs
docker-compose logs -f backend

# Stop services
docker-compose down
```

The backend will be available at `http://localhost:8000`

## What Happens on Startup

1. **Database starts** and waits for health check
2. **Backend container starts** and runs the startup script:
   - Waits for database to be ready
   - Runs all pending Alembic migrations automatically (`alembic upgrade head`)
   - Starts the FastAPI application

**Migrations run automatically** - you don't need to do anything!

## Database Migrations

This project uses **Alembic** for database schema migrations.

### Automatic Migration on Startup

✅ **Migrations run automatically every time the backend container starts**

The startup script (`scripts/startup.sh`) ensures:
- Database is ready before connecting
- All pending migrations are applied before the app starts
- Application only starts if migrations succeed

### Creating New Migrations

When you need to change the database schema:

```bash
# 1. Make changes to your SQLAlchemy models in app/models/

# 2. Create a new migration
docker-compose exec backend alembic revision -m "description_of_change"

# 3. Edit the generated file in alembic/versions/
# Implement upgrade() and downgrade() functions

# 4. Restart backend to apply
docker-compose restart backend
```

The migration will be automatically applied on restart.

### Manual Migration Commands

```bash
# Check current migration version
docker-compose exec backend alembic current

# View migration history
docker-compose exec backend alembic history

# Manually run migrations (usually not needed)
docker-compose exec backend alembic upgrade head

# Rollback one migration
docker-compose exec backend alembic downgrade -1
```

See [MIGRATIONS.md](MIGRATIONS.md) for detailed migration documentation.

## Development

### Environment Variables

Create a `.env` file (optional - defaults are provided):

```env
POSTGRES_USER=ahlquran_user
POSTGRES_PASSWORD=ahlquran_pass
POSTGRES_DB=ahlquran_db
DATABASE_URL=postgresql+asyncpg://ahlquran_user:ahlquran_pass@db:5432/ahlquran_db
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### Hot Reload

The backend runs with `--reload` flag in development, so code changes are automatically reflected.

### Database Access

```bash
# Connect to PostgreSQL
docker-compose exec db psql -U ahlquran_user -d ahlquran_db

# View tables
\dt

# Query data
SELECT * FROM users;
```

## Project Structure

```
AhlQuran-Back/
├── alembic/              # Database migrations
│   └── versions/         # Migration files
├── app/
│   ├── api/              # API routes
│   │   └── v1/
│   │       └── routes/   # Endpoint definitions
│   ├── core/             # Security, config
│   ├── db/               # Database setup
│   ├── models/           # SQLAlchemy models
│   └── schemas/          # Pydantic schemas
├── scripts/
│   └── startup.sh        # Container startup script
├── alembic.ini           # Alembic configuration
├── docker-compose.yml    # Service orchestration
├── Dockerfile            # Backend container image
└── requirements.txt      # Python dependencies
```

## API Documentation

When the backend is running, visit:
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Troubleshooting

### Backend won't start

```bash
# Check logs
docker-compose logs backend

# Common issue: Migration failed
# Fix the migration and restart
docker-compose restart backend
```

### Database connection issues

```bash
# Ensure database is healthy
docker-compose ps

# Restart database
docker-compose restart db
```

### Reset everything

```bash
# Stop and remove all containers and volumes
docker-compose down -v

# Start fresh
docker-compose up -d
```

## WebSocket Support

The backend includes WebSocket support for real-time messaging:

- **Endpoint**: `ws://localhost:8000/ws/messages?token=YOUR_JWT_TOKEN`
- **Features**: Real-time chat, typing indicators, message deletion
- **Authentication**: JWT token passed as query parameter

## Testing

```bash
# Run tests (when test suite is available)
docker-compose exec backend pytest

# Run with coverage
docker-compose exec backend pytest --cov=app
```

## Production Deployment

1. Update environment variables for production
2. Change `SECRET_KEY` to a secure random value
3. Set `DEBUG=false`
4. Use production-grade database configuration
5. Set up proper CORS origins in `app/main.py`

## Migrations are Sustainable ✅

- ✅ Migrations run automatically on container startup
- ✅ No manual intervention needed for deployments
- ✅ Backend won't start if migrations fail (fail-safe)
- ✅ Data consistency issues fixed through migrations
- ✅ Version controlled migration files
- ✅ Easy to create, test, and deploy new migrations

**Just restart the container and migrations apply automatically!**
