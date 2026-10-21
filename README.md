# Ahl El Quran - Backend (FastAPI)

A comprehensive RESTful API backend for Quran school management built with FastAPI, PostgreSQL, and SQLAlchemy.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Environment Variables](#environment-variables)
- [Database Migrations](#database-migrations)
- [API Documentation](#api-documentation)
- [Authentication & Authorization](#authentication--authorization)
- [Admin Role Override System](#admin-role-override-system)
- [Seeding Test Data](#seeding-test-data)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

Ahl El Quran Backend is a FastAPI-based REST API that provides comprehensive school management functionality including user management, student enrollment, memorization tracking, attendance, achievements, and reporting.

## ✨ Features

- **Multi-tenant Architecture**: Support for multiple schools under one system
- **JWT Authentication**: Secure token-based authentication with refresh tokens
- **Role-Based Access Control (RBAC)**: 7 user roles with granular permissions
- **Admin Role Override**: Allows admins to manage any school as a chief supervisor
- **Async Operations**: Fast, non-blocking database operations using async/await
- **Database Migrations**: Automatic schema versioning with Alembic
- **WebSocket Support**: Real-time messaging and notifications
- **Comprehensive API**: 100+ endpoints covering all business logic
- **Type Safety**: Pydantic schemas for request/response validation
- **CORS Support**: Configured for cross-origin requests
- **Logging**: Detailed logging for debugging and monitoring
- **Docker Support**: Easy deployment with Docker Compose

## 🛠️ Tech Stack

- **Framework**: FastAPI 0.104+
- **Database**: PostgreSQL 15
- **ORM**: SQLAlchemy 2.0 (Async)
- **Migrations**: Alembic
- **Authentication**: JWT (python-jose)
- **Password Hashing**: Passlib with bcrypt
- **WebSockets**: FastAPI native WebSocket support
- **Validation**: Pydantic v2
- **Testing**: pytest (when test suite is available)

## 📁 Project Structure

```
ahlQuran_Back/
├── alembic/                      # Database migrations
│   ├── versions/                # Migration version files
│   │   ├── xxx_initial.py      # Initial schema
│   │   ├── xxx_add_field.py    # Subsequent migrations
│   │   └── ...
│   └── env.py                   # Alembic environment config
├── app/
│   ├── api/                     # API layer
│   │   └── v1/
│   │       └── routes/          # API endpoint definitions
│   │           ├── admin.py           # Admin endpoints (school/president CRUD)
│   │           ├── auth.py            # Authentication (login, refresh)
│   │           ├── student.py         # Student CRUD and operations
│   │           ├── teacher.py         # Teacher CRUD and operations
│   │           ├── supervisor.py      # Supervisor CRUD and operations
│   │           ├── president.py       # President operations and statistics
│   │           ├── chief_supervisor.py # Chief supervisor operations
│   │           ├── guardian.py        # Guardian (parent) operations
│   │           ├── lecture.py         # Lecture (حلقة) management
│   │           ├── messages.py        # Messaging system
│   │           ├── seed.py            # Database seeding endpoint
│   │           └── __init__.py        # Router registration
│   ├── core/                    # Core functionality
│   │   ├── config.py           # Application configuration
│   │   ├── dependencies.py     # Dependency injection (auth, role checking)
│   │   ├── security.py         # JWT token handling, password hashing
│   │   └── multi_tenancy.py    # Multi-tenant helper functions
│   ├── db/                      # Database
│   │   ├── base.py             # SQLAlchemy base and session
│   │   └── session.py          # Database session factory
│   ├── models/                  # SQLAlchemy ORM models
│   │   ├── user.py             # User model (base for all roles)
│   │   ├── admin.py            # Admin model
│   │   ├── president.py        # President model
│   │   ├── chief_supervisor.py # Chief Supervisor model
│   │   ├── supervisor.py       # Supervisor model
│   │   ├── teacher.py          # Teacher model
│   │   ├── student.py          # Student model
│   │   ├── guardian.py         # Guardian model
│   │   ├── lecture.py          # Lecture model
│   │   ├── attendance.py       # Attendance model
│   │   ├── achievement.py      # Achievement (memorization) model
│   │   └── message.py          # Message model
│   ├── schemas/                 # Pydantic schemas
│   │   ├── user.py             # User request/response schemas
│   │   ├── student.py          # Student schemas
│   │   ├── teacher.py          # Teacher schemas
│   │   ├── achievement.py      # Achievement schemas
│   │   ├── attendance.py       # Attendance schemas
│   │   └── statistics.py       # Statistics response schemas
│   └── main.py                  # FastAPI application entry point
├── scripts/
│   └── startup.sh               # Container startup script (runs migrations)
├── alembic.ini                  # Alembic configuration
├── docker-compose.yml           # Docker services orchestration
├── Dockerfile                   # Backend container image
├── requirements.txt             # Python dependencies
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- (Optional) Python 3.11+ for local development

### Using Docker (Recommended)

1. **Clone the repository**:
```bash
cd ahlQuran_Back
```

2. **Start all services** (database + backend):
```bash
docker-compose up -d
```

3. **View logs**:
```bash
docker-compose logs -f backend
```

4. **Access the API**:
- Backend: http://localhost:8000
- API Docs: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

5. **Stop services**:
```bash
docker-compose down
```

### What Happens on Startup

1. **PostgreSQL database starts** and waits for health check
2. **Backend container starts** and runs `scripts/startup.sh`:
   - Waits for database to be ready
   - Runs all pending Alembic migrations automatically (`alembic upgrade head`)
   - Starts the FastAPI application with uvicorn

**✅ Migrations run automatically** - you don't need to do anything!

### Local Development (Without Docker)

1. **Install PostgreSQL** locally

2. **Create a virtual environment**:
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**:
```bash
pip install -r requirements.txt
```

4. **Set environment variables** (see [Environment Variables](#environment-variables))

5. **Run migrations**:
```bash
alembic upgrade head
```

6. **Start the server**:
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 🔐 Environment Variables

Create a `.env` file in the root directory (optional - defaults are provided in `docker-compose.yml`):

```env
# Database Configuration
POSTGRES_USER=ahlquran_user
POSTGRES_PASSWORD=ahlquran_pass
POSTGRES_DB=ahlquran_db
DATABASE_URL=postgresql+asyncpg://ahlquran_user:ahlquran_pass@db:5432/ahlquran_db

# JWT Configuration
SECRET_KEY=your-super-secret-key-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=1800    # 30 minutes
REFRESH_TOKEN_EXPIRE_DAYS=7         # 7 days

# CORS Configuration (comma-separated)
CORS_ORIGINS=http://localhost:3000,https://ahl-el-quran.vercel.app

# Application Settings
DEBUG=True
LOG_LEVEL=INFO
```

### Environment Variables Explained:

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | PostgreSQL username | `ahlquran_user` |
| `POSTGRES_PASSWORD` | PostgreSQL password | `ahlquran_pass` |
| `POSTGRES_DB` | PostgreSQL database name | `ahlquran_db` |
| `DATABASE_URL` | Full database connection string | See above |
| `SECRET_KEY` | JWT signing secret (CHANGE IN PRODUCTION!) | Random generated |
| `ALGORITHM` | JWT algorithm | `HS256` |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Access token lifetime | `1800` (30 min) |
| `REFRESH_TOKEN_EXPIRE_DAYS` | Refresh token lifetime | `7` days |
| `CORS_ORIGINS` | Allowed frontend origins | `*` (allow all in dev) |

**⚠️ IMPORTANT**: Change `SECRET_KEY` to a secure random value in production!

Generate a secure secret key:
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

## 🗄️ Database Migrations

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

# Example:
docker-compose exec backend alembic revision -m "add_profile_image_to_students"

# 3. Edit the generated file in alembic/versions/
# Implement upgrade() and downgrade() functions

# 4. Restart backend to apply
docker-compose restart backend
```

### Manual Migration Commands

```bash
# Check current migration version
docker-compose exec backend alembic current

# View migration history
docker-compose exec backend alembic history --verbose

# Manually run migrations (usually not needed)
docker-compose exec backend alembic upgrade head

# Rollback one migration
docker-compose exec backend alembic downgrade -1

# Rollback to specific version
docker-compose exec backend alembic downgrade <revision_id>
```

### Migration Best Practices

1. **Always test migrations** on a development database first
2. **Create reversible migrations** (implement both upgrade and downgrade)
3. **One logical change per migration** (easier to debug and rollback)
4. **Add comments** explaining complex migrations
5. **Test with real data** to catch issues before production

## 📚 API Documentation

### Interactive API Docs

When the backend is running:
- **Swagger UI**: http://localhost:8000/docs (interactive, try endpoints)
- **ReDoc**: http://localhost:8000/redoc (clean documentation)

### API Structure

All endpoints are versioned under `/api/v1/`:

```
/api/v1/
├── /auth               # Authentication (login, refresh, logout)
├── /admin              # Admin operations (manage schools, presidents)
├── /president          # President operations (school management, statistics)
├── /students           # Student CRUD and operations
├── /teachers           # Teacher CRUD and operations
├── /supervisors        # Supervisor CRUD and operations
├── /chief-supervisors  # Chief Supervisor operations
├── /guardians          # Guardian operations
├── /lectures           # Lecture management
├── /messages           # Messaging system
└── /seed               # Database seeding (development only)
```

### Example API Calls

#### 1. Login
```bash
curl -X POST "http://localhost:8000/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@doctrine.com",
    "password": "admin123"
  }'
```

#### 2. Get Students (with auth)
```bash
curl -X GET "http://localhost:8000/api/v1/students" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

#### 3. Add Achievement (admin viewing school)
```bash
curl -X POST "http://localhost:8000/api/v1/students/75/achievements?school_id=1" \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "X-Role-Override: CHIEF_SUPERVISOR" \
  -H "Content-Type: application/json" \
  -d '{
    "from_surah": 1,
    "from_verse": 1,
    "to_surah": 1,
    "to_verse": 7,
    "achievement_type": "normal",
    "date": "21-10-2026"
  }'
```

## 🔒 Authentication & Authorization

### JWT Token System

The API uses JWT (JSON Web Tokens) for authentication:

1. **Login** → Receive `access_token` and `refresh_token`
2. **Include token** in all requests: `Authorization: Bearer <access_token>`
3. **Refresh** when access token expires using refresh token
4. **Logout** → Blacklist tokens (if implemented)

### Token Types

| Token Type | Purpose | Lifetime | Storage |
|------------|---------|----------|---------|
| Access Token | API authentication | 30 minutes | Memory/localStorage |
| Refresh Token | Get new access token | 7 days | httpOnly cookie (recommended) |

### User Roles

The system supports 7 user roles with hierarchical permissions:

| Role | Arabic | Level | Can Manage |
|------|--------|-------|------------|
| `ADMIN` | الرئيس | 1 (highest) | All schools, presidents |
| `PRESIDENT` | رئيس المدرسة | 2 | Own school, supervisors, teachers, students |
| `CHIEF_SUPERVISOR` | المشرف الرئيسي | 3 | Students, teachers, lectures (elevated permissions) |
| `SUPERVISOR` | المشرف | 4 | Students, attendance, achievements |
| `TEACHER` | المعلم | 5 | Own lectures, students, achievements |
| `STUDENT` | الطالب | 6 | Own data (read-only) |
| `GUARDIAN` | ولي الأمر | 6 | Ward data (read-only) |

### Permission Dependencies

Located in `app/core/dependencies.py`:

```python
# Require specific role
require_admin()
require_president()
require_president_or_supervisor()
require_president_or_chief_supervisor()
require_teacher()
require_student()
require_guardian()
```

## 🔑 Admin Role Override System

### How It Works

The admin role override system allows admins to manage any school as if they were the school's chief supervisor.

#### Backend Implementation

**1. Header Detection** (`app/core/dependencies.py`):
```python
async def get_current_user(request: Request, credentials: HTTPAuthorizationCredentials):
    # ... decode JWT token ...
    
    if token_type == "admin":
        # Check for role override header
        role_override = request.headers.get("X-Role-Override")
        
        if role_override == "CHIEF_SUPERVISOR":
            # Create AdminAsUser object with is_admin flag
            class AdminAsUser:
                def __init__(self, admin, role):
                    self.id = admin.id
                    self.role = UserRoleEnum.CHIEF_SUPERVISOR
                    self.is_admin = True  # Special flag
                    
            return AdminAsUser(admin, "CHIEF_SUPERVISOR")
```

**2. Permission Checking**:
```python
def require_president_or_supervisor(current_user):
    # Check if user is admin with role override
    if hasattr(current_user, 'is_admin') and current_user.is_admin:
        return current_user  # Allow access
    
    # Normal role check
    if current_user.role not in [UserRoleEnum.PRESIDENT, UserRoleEnum.SUPERVISOR]:
        raise HTTPException(status_code=403, detail="Access denied")
        
    return current_user
```

**3. Multi-Tenancy** (`app/core/multi_tenancy.py`):
```python
async def get_president_id_for_user(current_user, db, school_id=None):
    """Get president ID for current user (handles admin role override)"""
    
    # Admin with role override uses school_id parameter
    if hasattr(current_user, 'is_admin') and current_user.is_admin:
        if not school_id:
            raise HTTPException(400, "school_id required for admin")
        
        # Find president for this school
        result = await db.execute(
            select(President).where(President.school_id == school_id)
        )
        president = result.scalar_one_or_none()
        return president.id
    
    # Normal users: get their own president_id
    # ... (president, supervisor, teacher logic)
```

### Usage Flow

1. **Admin logs in** → Receives admin token
2. **Admin selects a school** → Frontend stores `school_id` in sessionStorage
3. **Frontend adds headers** to all requests:
   - `X-Role-Override: CHIEF_SUPERVISOR`
   - `?school_id=5` (query parameter)
4. **Backend detects headers** → Creates `AdminAsUser` with `is_admin=True`
5. **Permission checks pass** → Admin can manage the school
6. **Admin exits view** → Frontend removes sessionStorage → Normal admin access

### Security Considerations

- ✅ Admin authentication is still required (JWT validation)
- ✅ `school_id` parameter validates school exists
- ✅ Admin actions are logged with admin user ID
- ✅ Role override only grants CHIEF_SUPERVISOR permissions, not PRESIDENT
- ✅ Cannot override to other roles (only CHIEF_SUPERVISOR is allowed)

## 🌱 Seeding Test Data

For development and testing, use the seed endpoint to populate the database with sample data.

### Seed Endpoint

```bash
POST /api/v1/seed/populate
```

### Using the Seed Endpoint

```bash
curl -X POST "http://localhost:8000/api/v1/seed/populate"
```

Or visit http://localhost:8000/docs and try the `/seed/populate` endpoint.

### Seeded Data

The seed script creates:

**1 Admin**:
- Email: `admin@doctrine.com`
- Password: `admin123`

**2 Schools with complete data**:

**School 1 "مدرسة النور"**:
- President: `school1@doctrine.com` / `school123`
- Chief Supervisor: `chief1@doctrine.com` / `chief123`
- Supervisor: `supervisor1@doctrine.com` / `super123`
- Teachers (3): `teacher1-3@doctrine.com` / `teacher123`
- Lectures (3): Beginners, Intermediate, Advanced
- Students (15): `student1-15@doctrine.com` / `student123`
- Sample achievements and attendance records

**School 2 "مدرسة الهدى"**:
- President: `school2@doctrine.com` / `school123`
- Chief Supervisor: `chief2@doctrine.com` / `chief123`
- Teachers (2): `teacher4-5@doctrine.com` / `teacher123`
- Lectures (2): Beginners, Advanced
- Students (6): `student16-21@doctrine.com` / `student123`

### Credentials Summary

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@doctrine.com` | `admin123` |
| School President | `school1@doctrine.com` | `school123` |
| Chief Supervisor | `chief1@doctrine.com` | `chief123` |
| Supervisor | `supervisor1@doctrine.com` | `super123` |
| Teacher | `teacher1@doctrine.com` | `teacher123` |
| Student | `student1@doctrine.com` | `student123` |

**⚠️ Note**: Seeding is idempotent - running it multiple times won't create duplicates (emails are unique).

## 🚀 Deployment

### Docker Deployment (Recommended)

#### Using Docker Compose

```bash
# Production docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  backend:
    build: .
    environment:
      DATABASE_URL: ${DATABASE_URL}
      SECRET_KEY: ${SECRET_KEY}
      CORS_ORIGINS: ${CORS_ORIGINS}
    ports:
      - "8000:8000"
    depends_on:
      - db
    restart: unless-stopped

volumes:
  postgres_data:
```

```bash
# Deploy
docker-compose -f docker-compose.prod.yml up -d
```

### Deployment Platforms

#### Railway.app

1. Create a new project on [Railway.app](https://railway.app)
2. Add PostgreSQL database service
3. Add new service from GitHub repo
4. Set environment variables in Railway dashboard
5. Deploy automatically on push

#### Render.com

1. Create a new Web Service on [Render.com](https://render.com)
2. Connect your GitHub repository
3. Set build command: `pip install -r requirements.txt`
4. Set start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
5. Add PostgreSQL database
6. Set environment variables
7. Deploy

#### Heroku

```bash
# Install Heroku CLI and login
heroku login

# Create app
heroku create ahl-quran-api

# Add PostgreSQL
heroku addons:create heroku-postgresql:hobby-dev

# Set environment variables
heroku config:set SECRET_KEY="your-secret-key"
heroku config:set CORS_ORIGINS="https://your-frontend.vercel.app"

# Deploy
git push heroku main
```

### Using ngrok (Development/Demo)

Expose local backend to the internet:

```bash
# Install ngrok
# Download from https://ngrok.com/download

# Start your backend locally
docker-compose up -d

# Expose port 8000
ngrok http 8000

# Copy the URL (e.g., https://abc123.ngrok-free.dev)
# Update frontend NEXT_PUBLIC_API_BASE_URL to this URL
```

**Update CORS** in `app/main.py`:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "https://your-ngrok-url.ngrok-free.dev",
        "https://your-frontend.vercel.app"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Production Checklist

Before deploying to production:

- [ ] Change `SECRET_KEY` to a secure random value
- [ ] Set `DEBUG=False`
- [ ] Configure production database (not localhost)
- [ ] Update `CORS_ORIGINS` to your frontend domain
- [ ] Set up SSL/TLS (HTTPS)
- [ ] Configure proper logging
- [ ] Set up database backups
- [ ] Set up monitoring (e.g., Sentry)
- [ ] Review and update `ACCESS_TOKEN_EXPIRE_MINUTES`
- [ ] Set up rate limiting (optional)
- [ ] Configure reverse proxy (nginx) if needed
- [ ] Set up CI/CD pipeline
- [ ] Document deployment process

## 🐛 Troubleshooting

### Backend won't start

```bash
# Check logs
docker-compose logs backend

# Common issues:
# 1. Migration failed → Fix migration and restart
# 2. Database not ready → Wait a few seconds and restart
# 3. Port 8000 already in use → Change port in docker-compose.yml
```

### Database connection issues

```bash
# Ensure database is healthy
docker-compose ps

# Restart database
docker-compose restart db

# Check database logs
docker-compose logs db
```

### Migration errors

```bash
# Check current migration state
docker-compose exec backend alembic current

# View migration history
docker-compose exec backend alembic history

# Rollback problematic migration
docker-compose exec backend alembic downgrade -1

# Fix migration file and upgrade again
docker-compose exec backend alembic upgrade head
```

### CORS errors

Add your frontend URL to `CORS_ORIGINS` in `.env` or `app/main.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://your-frontend.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Reset everything

```bash
# Stop and remove all containers and volumes (⚠️ deletes all data)
docker-compose down -v

# Start fresh
docker-compose up -d
```

### Database access

```bash
# Connect to PostgreSQL
docker-compose exec db psql -U ahlquran_user -d ahlquran_db

# Common commands:
\dt                    # List tables
\d users               # Describe users table
SELECT * FROM users;   # Query users
\q                     # Quit
```

## 📊 Database Schema

Key tables:

- `users` - Base user accounts (all roles)
- `admins` - System administrators
- `presidents` - School owners
- `chief_supervisors` - Chief supervisors
- `supervisors` - Regular supervisors
- `teachers` - Teachers
- `students` - Students
- `guardians` - Parents/guardians
- `lectures` - Study circles (حلقات)
- `achievements` - Memorization achievements
- `attendances` - Attendance records
- `messages` - Internal messaging

## 🧪 Testing

```bash
# Run tests (when available)
docker-compose exec backend pytest

# Run with coverage
docker-compose exec backend pytest --cov=app --cov-report=html

# Run specific test file
docker-compose exec backend pytest tests/test_auth.py
```

## 📝 Code Documentation

Key files are documented with:
- Function docstrings
- Type hints
- Inline comments for complex logic
- Example usage in docstrings

Example:
```python
async def get_president_id_for_user(
    current_user,
    db: AsyncSession,
    school_id: Optional[int] = None
) -> int:
    """
    Get president ID for the current user.
    
    Handles multiple scenarios:
    - Admin with role override: uses school_id parameter
    - President: returns own ID
    - Supervisor/Teacher: returns their president_id
    
    Args:
        current_user: Current authenticated user object
        db: Database session
        school_id: Optional school ID (required for admin)
        
    Returns:
        int: President ID
        
    Raises:
        HTTPException: If user type not recognized or school_id missing for admin
        
    Example:
        president_id = await get_president_id_for_user(current_user, db, school_id=5)
    """
    # Implementation...
```

## 🤝 Contributing

When contributing:

1. Create a feature branch: `git checkout -b feature/my-feature`
2. Make changes and add comprehensive comments
3. Create migration if schema changes: `alembic revision -m "description"`
4. Test thoroughly (manual testing or write tests)
5. Update this README if needed
6. Create pull request with detailed description

## 📄 License

[Add your license here]

## 🙏 Acknowledgments

- FastAPI team for the excellent framework
- SQLAlchemy team for the powerful ORM
- Alembic team for database migrations
- All contributors to this project

---

**Note**: This is a development/demo setup. For production, please follow security best practices and use proper secrets management.
