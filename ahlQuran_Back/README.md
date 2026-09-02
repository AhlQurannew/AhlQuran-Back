# 🕌 Ahl Quran Backend

A modern, containerized FastAPI backend system for managing Quranic education institutions. Fully dockerized - **no Python or PostgreSQL installation required!**

---

## 📋 Table of Contents

- [What You Need](#-what-you-need)
- [Quick Start (5 Minutes)](#-quick-start-5-minutes)
- [What This Application Does](#-what-this-application-does)
- [API Documentation](#-api-documentation)
- [User Roles](#-user-roles)
- [Common Commands](#-common-commands)
- [Troubleshooting](#-troubleshooting)

---

## 🎯 What You Need

**Only Docker is required!** No need to install Python, PostgreSQL, or any other dependencies.

### Install Docker Desktop

Choose your operating system:

- **Windows**: [Download Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- **Mac**: [Download Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
- **Linux**:
  ```bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo apt-get install docker-compose-plugin
  ```

> **Verify Installation**: Open a terminal and run `docker --version`

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Get the Code

```bash
git clone <your-repository-url>
cd ahl_quran_backend
```

### Step 2: Configure Environment

Copy the example environment file and customize it:

```bash
cp .env.example .env
```

**Windows PowerShell:**
```powershell
Copy-Item .env.example .env
```

Edit `.env` file with your preferred text editor and change these values:

```dotenv
POSTGRES_USER=your_username
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=ahl_quran_db
SECRET_KEY=generate_a_secure_key_here
```

> **🔐 Generate a Secure Secret Key:**
> ```bash
> python -c "import secrets; print(secrets.token_hex(32))"
> ```
> Or use an online generator: https://randomkeygen.com/

### Step 3: Start the Application

```bash
docker-compose up --build
```

**What happens:**
- ✅ Downloads necessary Docker images (first time only)
- ✅ Starts PostgreSQL database
- ✅ Waits for database to be ready
- ✅ Starts FastAPI application
- ✅ Application available at http://localhost:8000

**You'll see logs like:**
```
db_1   | database system is ready to accept connections
web_1  | INFO:     Application startup complete.
web_1  | INFO:     Uvicorn running on http://0.0.0.0:8000
```

> **Note**: First run takes 2-3 minutes to download images. Subsequent runs are instant!

### Step 4: Run Database Migrations

Open a **new terminal** (keep the first one running) and run:

**On Windows:**
```cmd
cd ahlQuran_Back
run_migrations.bat
```

**On Linux/Mac:**
```bash
cd ahlQuran_Back
chmod +x run_migrations.sh
./run_migrations.sh
```

This applies all database schema changes. See [MIGRATIONS.md](MIGRATIONS.md) for more details.

### Step 5: Create Your Admin Account

```bash
docker-compose exec web python -m app.Cli.admin
```

Follow the prompts:
```
Enter admin username: admin
Enter admin password: YourSecurePassword123
Admin user 'admin' created successfully!
```

### Step 6: Access the Application

🎉 **You're ready!**

- **Interactive API Docs**: http://localhost:8000/docs
- **API Base URL**: http://localhost:8000/api/v1
- **Alternative Docs**: http://localhost:8000/redoc

---

## 💡 What This Application Does

### Core Features

- **👤 User Management**: Manage admins, presidents, supervisors, teachers, and students
- **🔐 Authentication**: Secure JWT-based login system
- **📚 Session Tracking**: Record and track Quranic learning sessions
- **🏆 Achievements**: Monitor student progress and achievements
- **🎓 Role-Based Access**: Different permissions for different user types
- **📊 Reports**: Generate reports on student performance

### Technology Stack

| Component | Technology |
|-----------|------------|
| **Backend Framework** | FastAPI (Python 3.11) |
| **Database** | PostgreSQL 15 |
| **Authentication** | JWT with bcrypt |
| **ORM** | SQLAlchemy 2.0 (Async) |
| **Containerization** | Docker + Docker Compose |
| **API Documentation** | Swagger/OpenAPI |

---

## 📚 API Documentation

### Getting Started with the API

1. **Open Interactive Docs**: http://localhost:8000/docs

2. **Login to Get Token**:
   - Click on `POST /api/v1/auth/admin/login`
   - Click "Try it out"
   - Enter your credentials:
     ```json
     {
       "user": "admin",
       "password": "YourSecurePassword123"
     }
     ```
   - Click "Execute"
   - Copy the `access_token` from the response

3. **Authorize**:
   - Click the 🔒 "Authorize" button at the top
   - Enter: `Bearer <your_access_token>`
   - Click "Authorize"

4. **Use Protected Endpoints**:
   - Now you can test any endpoint!

### Example API Calls

#### Login
```bash
POST http://localhost:8000/api/v1/auth/admin/login
Content-Type: application/json

{
  "user": "admin",
  "password": "YourSecurePassword123"
}
```

#### Create a President
```bash
POST http://localhost:8000/api/v1/admin/presidents
Authorization: Bearer <your_token>
Content-Type: application/json

{
  "firstname": "Ahmed",
  "lastname": "Hassan",
  "email": "ahmed@example.com",
  "password": "SecurePass123",
  "school_name": "Al-Noor Academy",
  "phone_number": "+1234567890"
}
```

#### Create a Teacher
```bash
POST http://localhost:8000/api/v1/teachers
Authorization: Bearer <your_token>
Content-Type: application/json

{
  "firstname": "Fatima",
  "lastname": "Ali",
  "email": "fatima@example.com",
  "password": "TeacherPass123",
  "riwaya": "Hafs"
}
`` create a supervisor
{
  "email": "amine@gmail.com",
  "password": "amineamine12",
  "firstname": "amine",
  "lastname": "youcef"
}
---

## 👥 User Roles

### Role Hierarchy

```
Admin (System Administrator)
  ├── Can manage Presidents
  │
  └── President (School/Institution Head)
      ├── Can manage Supervisors, Teachers, Students
      │
      └── Supervisor
          ├── Can manage Teachers, Students
          │
          └── Teacher
              ├── Can manage Students
              │
              └── Student
```

### Permissions

| Role | Create | Manage | Access |
|------|--------|--------|--------|
| **Admin** | Presidents | All users | Full system access |
| **President** | Supervisors, Teachers, Students | Own hierarchy | Institution management |
| **Supervisor** | Teachers, Students | Assigned users | Section management |
| **Teacher** | - | Assigned students | Teaching & sessions |
| **Student** | - | Own profile | Personal data |

---

## 🛠 Common Commands

### Starting & Stopping

```bash
# Start application (normal mode)
docker-compose up

# Start in background (detached mode)
docker-compose up -d

# Stop application
docker-compose down

# Stop and remove all data (⚠️ DELETES DATABASE)
docker-compose down -v
```

### Viewing Logs

```bash
# View all logs
docker-compose logs -f

# View only web application logs
docker-compose logs -f web

# View only database logs
docker-compose logs -f db
```

### Database Operations

```bash
# Run migrations (after code changes)
docker-compose exec web alembic upgrade head

# Rollback last migration
docker-compose exec web alembic downgrade -1

# View migration history
docker-compose exec web alembic history

# Access PostgreSQL database directly
docker-compose exec db psql -U postgres -d ahl_quran
```

### Container Management

```bash
# View running containers
docker-compose ps

# Restart specific service
docker-compose restart web

# Rebuild after code changes
docker-compose up --build

# Access container shell
docker-compose exec web bash

# Run Python commands
docker-compose exec web python -m app.Cli.admin
```

---

## 🐛 Troubleshooting

### Problem: Port 8000 is already in use

**Error:**
```
Error starting userland proxy: listen tcp4 0.0.0.0:8000: bind: address already in use
```

**Solution 1: Stop the conflicting process**

**Windows:**
```powershell
netstat -ano | findstr :8000
taskkill /PID <PID_NUMBER> /F
```

**Mac/Linux:**
```bash
lsof -ti:8000 | xargs kill -9
```

**Solution 2: Change the port**

Edit `docker-compose.yml`:
```yaml
web:
  ports:
    - "8001:8000"  # Use port 8001 instead
```

Then access: http://localhost:8001

---

### Problem: Database connection refused

**Error:**
```
sqlalchemy.exc.OperationalError: connection refused
```

**Solution:**

```bash
# Check if database is running
docker-compose ps

# Restart database
docker-compose restart db

# View database logs
docker-compose logs db

# If still failing, recreate everything
docker-compose down
docker-compose up --build
```

---

### Problem: Migration errors

**Error:**
```
Target database is not up to date
```

**Solution:**

```bash
# Check current migration status
docker-compose exec web alembic current

# Apply all pending migrations
docker-compose exec web alembic upgrade head

# If migrations are corrupted, reset
docker-compose down -v
docker-compose up -d db
docker-compose exec web alembic upgrade head
```

---

### Problem: Docker daemon not running

**Error:**
```
Cannot connect to the Docker daemon
```

**Solution:**

- **Windows/Mac**: Start Docker Desktop application
- **Linux**: 
  ```bash
  sudo systemctl start docker
  sudo systemctl enable docker
  ```

---

### Problem: Permission denied (Linux)

**Error:**
```
permission denied while trying to connect to the Docker daemon
```

**Solution:**

```bash
# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes
newgrp docker

# Restart terminal or logout/login
```

---

### Problem: Changes not reflecting

**Solution:**

```bash
# Rebuild containers
docker-compose up --build

# If database changes, also run migrations
docker-compose exec web alembic upgrade head

# For complete refresh
docker-compose down
docker-compose up --build
```

---

### Problem: Out of disk space

**Solution:**

```bash
# Remove unused Docker resources
docker system prune -a

# Remove all stopped containers
docker container prune

# Remove unused volumes (⚠️ may delete data)
docker volume prune
```

---

## 🔄 Fresh Start (Reset Everything)

If you want to start completely fresh:

```bash
# Stop and remove everything
docker-compose down -v

# Remove Docker images
docker-compose rm -f

# Rebuild from scratch
docker-compose up --build

# Setup database
docker-compose exec web alembic upgrade head

# Create admin
docker-compose exec web python -m app.Cli.admin
```

---

## 📖 Additional Resources

### Project Structure

```
ahl_quran_backend/
├── app/
│   ├── api/v1/routes/      # API endpoints
│   ├── models/             # Database models
│   ├── schemas/            # Request/response schemas
│   ├── core/               # Configuration & security
│   └── db/                 # Database connection
├── alembic/                # Database migrations
├── Dockerfile              # Container image definition
├── docker-compose.yml      # Multi-container orchestration
├── requirements.txt        # Python dependencies
└── .env                    # Environment configuration
```
