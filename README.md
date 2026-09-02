# Ahl Quran Management System

A comprehensive management system for Quran schools (حلقات القرآن) with multi-tenancy support, featuring web admin dashboard and mobile guardian app.

## 🌟 Features

### Core System
- **Multi-tenancy:** Complete data isolation for multiple organizations (presidents)
- **User Management:** Presidents, Supervisors, Teachers, Students, and Guardians
- **Lecture Management:** Create and manage Quran study circles with weekly schedules
- **Attendance Tracking:** Track student and teacher attendance with date filtering
- **Achievement System:** Record student Quran memorization progress (حفظ/مراجعة)
- **Messaging System:** Real-time internal communication with role-based color coding
- **Reports & Analytics:** Generate detailed PDF reports and interactive charts

### Guardian Mobile App
- **Guardian Portal:** Dedicated mobile app for parents/guardians
- **Children Monitoring:** View all linked children's information
- **Attendance Tracking:** Monitor child attendance records with date filtering
- **Achievement Viewing:** Track child's Quran memorization progress
- **Statistics & Graphs:** Visual representation of child performance
- **Secure Authentication:** JWT-based login with token management

### Web Admin Dashboard
- **Student Management:** Complete CRUD operations with detailed profiles
- **Teacher Management:** Manage teachers with lecture assignments
- **Supervisor Management:** Hierarchical supervision structure
- **Lecture Management:** Create and schedule Quran study circles
- **Attendance System:** Mark and track attendance for students and teachers
- **Achievement Tracking:** Record memorization and review progress
- **Report Generation:** Multiple report types with PDF export
- **Chart Visualization:** Interactive charts using Syncfusion

## 🛠 Technology Stack

### Backend
- **FastAPI** - Modern async Python web framework
- **PostgreSQL 15** - Relational database with multi-tenancy
- **SQLAlchemy 2.0** - Async ORM
- **Alembic** - Database migrations
- **JWT** - Token-based authentication
- **Bcrypt** - Password hashing
- **Docker** - Containerization

### Web Frontend (Admin Dashboard)
- **Flutter Web** - Cross-platform UI framework
- **GetX** - State management and routing
- **Syncfusion Charts** - Data visualization
- **PDF Generation** - Report printing
- **HTTP** - API communication
- **Dart** - Programming language

### Mobile Frontend (Guardian App)
- **Flutter** - Native mobile development
- **Material Design** - Modern UI components
- **SharedPreferences** - Local token storage
- **HTTP** - REST API integration
- **SVG Support** - Vector graphics

## 🚀 Quick Start

### Prerequisites
- **Docker Desktop** (Windows/Mac) or Docker Engine (Linux)
- **Flutter SDK** (for frontend development)
- **Git**

### Backend Setup

```bash
# 1. Clone the repository
git clone <repository-url>
cd ahl_quran

# 2. Configure environment
cd ahlQuran_Back
cp .env.example .env
# Edit .env with your database credentials and secret key

# 3. Start with Docker (migrations run automatically on first start!)
docker-compose up -d

# The init-db.sh script will automatically:
# - Wait for PostgreSQL to be ready
# - Run Alembic migrations to create all tables
# - Fall back to database_backup.sql if migrations fail
# - Start the application

# 4. Verify setup
docker-compose ps
# All services should show "Up" status

# 5. Create admin account
docker-compose exec backend python -m app.Cli.admin

# 6. Access the application
# Backend API: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

**Note:** On first Docker startup, the system automatically runs migrations to create all database tables. No manual migration step needed!

### Web Frontend Setup

```bash
cd ahlQuran_Front

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome
```

### Mobile App Setup

```bash
cd ahlQuran-Front-mobile

# Install dependencies
flutter pub get

# Configure API endpoint
# Edit lib/services/api_config.dart with your backend URL

# Run on Android/iOS
flutter run
```

## 📁 Project Structure

```
ahl_quran/
├── ahlQuran_Back/              # Backend API (FastAPI)
│   ├── app/
│   │   ├── api/v1/routes/      # API endpoints
│   │   │   ├── auth.py         # Authentication (admin, teacher, supervisor, guardian)
│   │   │   ├── student.py      # Student management
│   │   │   ├── teacher.py      # Teacher management
│   │   │   ├── supervisor.py   # Supervisor management
│   │   │   ├── guardian.py     # Guardian endpoints (read-only)
│   │   │   ├── lectures.py     # Lecture management
│   │   │   ├── attendance.py   # Attendance tracking
│   │   │   ├── achievements.py # Achievement recording
│   │   │   └── messages.py     # Messaging system
│   │   ├── core/               # Core functionality
│   │   │   ├── security.py     # JWT, password hashing
│   │   │   ├── dependencies.py # Auth dependencies
│   │   │   └── multi_tenancy.py# Multi-tenancy helpers
│   │   ├── models/             # Database models
│   │   ├── schemas/            # Pydantic schemas
│   │   └── db/                 # Database configuration
│   ├── alembic/                # Database migrations
│   ├── tests/                  # Comprehensive test suite
│   └── uploads/                # File uploads
│
├── ahlQuran_Front/             # Web Admin Dashboard (Flutter)
│   ├── lib/
│   │   ├── system/
│   │   │   ├── screens/        # Admin screens
│   │   │   │   ├── student_managment_new.dart
│   │   │   │   ├── teacher_management_new.dart
│   │   │   │   ├── supervisor_management_new.dart
│   │   │   │   ├── lecture_management_new.dart
│   │   │   │   ├── guardian_management_new.dart
│   │   │   │   ├── attendance_students_screen.dart
│   │   │   │   ├── teacher_attendance_list_screen.dart
│   │   │   │   └── reports_menu_screen.dart
│   │   │   ├── widgets/        # Reusable UI components
│   │   │   │   ├── dialogs/    # Modal dialogs
│   │   │   │   │   └── messaging_dialog.dart
│   │   │   │   ├── grids/      # Data grids
│   │   │   │   └── attendance/ # Attendance widgets
│   │   │   ├── new_models/     # Data models (DTOs)
│   │   │   ├── services/       # API client
│   │   │   └── utils/          # Constants & helpers
│   │   ├── controllers/        # GetX controllers
│   │   ├── routes/             # Navigation
│   │   ├── stats/              # Chart screens
│   │   ├── reports/            # PDF generators
│   │   └── web/                # Marketing pages
│   └── assets/                 # Images and fonts
│
├── ahlQuran-Front-mobile/      # Guardian Mobile App (Flutter)
│   ├── lib/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart          # Animated splash
│   │   │   ├── login_screen.dart           # Guardian login
│   │   │   ├── home_screen.dart            # Dashboard
│   │   │   ├── child_selection_screen.dart # Select child
│   │   │   ├── child_info_screen.dart      # Child details
│   │   │   ├── attendance_screen.dart      # Attendance records
│   │   │   ├── achievements_screen.dart    # Achievement records
│   │   │   ├── statistics_screen.dart      # Statistics view
│   │   │   ├── graphs_screen.dart          # Performance graphs
│   │   │   └── profile_screen.dart         # Guardian profile
│   │   ├── services/
│   │   │   ├── auth_service.dart           # Authentication
│   │   │   ├── guardian_service.dart       # Guardian API calls
│   │   │   └── api_config.dart             # API configuration
│   │   ├── models/
│   │   │   ├── guardian.dart               # Guardian model
│   │   │   ├── student.dart                # Student model
│   │   │   ├── attendance.dart             # Attendance model
│   │   │   └── achievement.dart            # Achievement model
│   │   └── widgets/
│   │       └── app_background.dart         # Gradient background
│   └── assets/
│       ├── images/                         # SVG logos
│       └── landing/                        # Landing page assets
│
└── docker-compose.yml          # Docker orchestration
```

## 👥 User Roles & Permissions

### 1. Admin (System Administrator)
- Full system access
- Create and manage presidents
- System-wide configuration

### 2. President (Organization Owner)
- Owns an organization/school
- Complete data isolation (multi-tenancy)
- Manages supervisors, teachers, students, and guardians
- Access to all reports and analytics
- Messaging system access

### 3. Supervisor
- Manages teachers and students within organization
- Assigns teachers to lectures
- Views reports and analytics
- Messaging system access
- Cannot modify president-level settings

### 4. Teacher
- Manages assigned lectures
- Records student attendance
- Records student achievements (memorization/review)
- Views student progress
- Messaging system access
- Cannot modify student profiles

### 5. Student
- Attends lectures
- Earns achievements
- Profile managed by supervisors/teachers
- Linked to guardian accounts

### 6. Guardian (Parent/Guardian)
- **Read-only access** via mobile app
- View linked children's information
- Monitor attendance records (with date filtering)
- Track achievement progress (with date filtering)
- View statistics and graphs
- Cannot modify any data
- Secure JWT authentication

## 🎯 Key Features

### Multi-Tenancy System
- Complete data isolation per organization (president)
- Each president has their own:
  - Supervisors, teachers, students, guardians
  - Lectures and schedules
  - Attendance records
  - Achievements
  - Messages
- Automatic filtering by `president_id` at database level
- No data sharing between organizations

### Attendance System
- **Student Attendance:**
  - Mark attendance per lecture session
  - Status: Present, Absent, Excused
  - Date-based filtering
  - Bulk attendance marking
  - Attendance reports and statistics
  
- **Teacher Attendance:**
  - Track teacher presence
  - Date-based filtering
  - Attendance history

### Achievement System
- **Achievement Types:**
  - حفظ (Memorization) - New memorization
  - مراجعة (Review) - Review of previously memorized
  
- **Features:**
  - Record Surah and verse ranges
  - Date tracking
  - Notes and comments
  - Achievement history
  - Progress reports
  - Statistics and graphs

### Messaging System
- Real-time messaging (2-second polling)
- Role-based color coding:
  - 🔴 President (Red)
  - 🔵 Supervisor (Blue)
  - 🟢 Teacher (Green)
- Sender name and role display
- Relative timestamps
- Auto-scroll to newest messages
- Message deletion (own messages only)

### Guardian Mobile App Features
- **Authentication:**
  - Secure JWT-based login
  - Token storage in SharedPreferences
  - Automatic token refresh
  
- **Children Management:**
  - View all linked children
  - Detailed child information
  - Profile pictures and basic info
  
- **Attendance Monitoring:**
  - View attendance records
  - Date range filtering
  - Pagination support
  - Status indicators (Present/Absent/Excused)
  
- **Achievement Tracking:**
  - View memorization progress
  - Review history
  - Date range filtering
  - Surah and verse details
  
- **Statistics & Graphs:**
  - Visual performance charts
  - Progress over time
  - Attendance statistics

### Reports & Analytics
- **Report Types:**
  - Student detail reports
  - Lecture detail reports
  - Daily achievement reports
  - Attendance statistics
  - Teacher attendance reports
  
- **Features:**
  - PDF generation
  - Date range filtering
  - Export functionality
  - Print support
  
- **Charts:**
  - Student progress charts
  - Attendance charts
  - Performance analytics
  - Interactive visualizations (Syncfusion)

## 📡 API Documentation

### Authentication Endpoints
- `POST /api/v1/auth/admin/login` - Admin login
- `POST /api/v1/auth/teacher/login` - Teacher login
- `POST /api/v1/auth/supervisor/login` - Supervisor login
- `POST /api/v1/auth/guardian/login` - Guardian login (mobile app)

### Guardian Endpoints (Read-Only)
- `GET /api/v1/guardians/my-children` - List all linked children
- `GET /api/v1/guardians/my-children/{id}` - Get child details
- `GET /api/v1/guardians/students/{id}/attendance` - Get attendance records
- `GET /api/v1/guardians/students/{id}/achievements` - Get achievements

### Student Management
- `GET /api/v1/students/` - List students (filtered by president)
- `POST /api/v1/students/` - Create student
- `GET /api/v1/students/{id}` - Get student details
- `PUT /api/v1/students/{id}` - Update student
- `DELETE /api/v1/students/{id}` - Delete student

### Teacher Management
- `GET /api/v1/teacher/` - List teachers
- `POST /api/v1/teacher/` - Create teacher
- `GET /api/v1/teacher/{id}` - Get teacher details
- `PUT /api/v1/teacher/{id}` - Update teacher
- `DELETE /api/v1/teacher/{id}` - Delete teacher

### Lecture Management
- `GET /api/v1/lectures/` - List lectures
- `POST /api/v1/special/lectures/submit` - Create lecture
- `GET /api/v1/special/lectures/{id}` - Get lecture details
- `PUT /api/v1/special/lectures/{id}` - Update lecture
- `DELETE /api/v1/special/lectures/{id}` - Delete lecture

### Attendance
- `GET /api/v1/attendances/` - List attendance records
- `POST /api/v1/attendances/` - Mark attendance
- `GET /api/v1/teacher-attendances/` - List teacher attendance

### Achievements
- `GET /api/v1/achievements/` - List achievements
- `POST /api/v1/achievements/` - Record achievement
- `GET /api/v1/achievements/{id}` - Get achievement details

### Messaging
- `GET /api/v1/messages/` - List all messages
- `GET /api/v1/messages/recent` - Get recent messages (for polling)
- `POST /api/v1/messages/` - Send message
- `DELETE /api/v1/messages/{id}` - Delete own message

### Interactive Documentation
Once the backend is running, visit:
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc

## 🗄 Database Schema

The system uses PostgreSQL with the following main tables:

### Core Tables
- `users` - All system users (admin, president, supervisor, teacher, student, guardian)
- `presidents` - Organization owners
- `supervisors` - Organization supervisors
- `teachers` - Quran teachers
- `students` - Students with detailed profiles
- `guardians` - Student guardians/parents

### Operational Tables
- `lectures` - Study circles/classes
- `weekly_schedules` - Lecture schedules
- `session_participations` - Student-lecture enrollments
- `attendances` - Student attendance records
- `teacher_attendances` - Teacher attendance records
- `achievements` - Student Quran memorization achievements
- `messages` - Internal messaging system

### Multi-Tenancy
All operational tables include `president_id` foreign key for complete data isolation:
- Students, teachers, supervisors filtered by president
- Lectures, attendance, achievements scoped to president
- Guardians linked to students within same president
- Messages isolated per organization

### Key Relationships
```
President (1) ──→ (N) Supervisors
President (1) ──→ (N) Teachers
President (1) ──→ (N) Students
President (1) ──→ (N) Lectures
Student (1) ──→ (N) Guardians
Student (N) ←──→ (N) Lectures (via session_participations)
Student (1) ──→ (N) Attendances
Student (1) ──→ (N) Achievements
```

## 💻 Development

### Backend Development

```bash
cd ahlQuran_Back

# Install dependencies
pip install -r requirements.txt

# Run migrations
alembic upgrade head

# Create admin user
python -m app.Cli.admin

# Start development server
uvicorn app.main:app --reload

# Run tests
pytest

# Run specific test file
pytest tests/test_guardian_authorization.py

# Run with coverage
pytest --cov=app tests/
```

### Web Frontend Development

```bash
cd ahlQuran_Front

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Build for production
flutter build web

# Run tests
flutter test
```

### Mobile App Development

```bash
cd ahlQuran-Front-mobile

# Install dependencies
flutter pub get

# Configure API endpoint
# Edit lib/services/api_config.dart

# For Android Emulator
static const String baseUrl = 'http://10.0.2.2:8000';

# For iOS Simulator
static const String baseUrl = 'http://localhost:8000';

# For Physical Device
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8000';

# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

### Database Migrations

```bash
cd ahlQuran_Back

# Create new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# View migration history
alembic history

# Backup database (Windows)
backup_database.bat

# Backup database (Linux/Mac)
./backup_database.sh

# Restore database (Windows)
restore_database.bat

# Restore database (Linux/Mac)
./restore_database.sh
```

## 🧪 Testing

### Backend Tests

The backend includes a comprehensive test suite with property-based testing:

```bash
cd ahlQuran_Back

# Run all tests
pytest

# Run with verbose output
pytest -v

# Run specific test categories
pytest tests/test_guardian_*.py
pytest tests/test_http_status_codes_property.py

# Run with coverage report
pytest --cov=app --cov-report=html tests/

# View coverage report
# Open htmlcov/index.html in browser
```

**Test Coverage:**
- Guardian authentication and authorization
- Multi-tenancy isolation
- Guardian read-only access enforcement
- HTTP status code properties
- JWT token validation
- Database layer integrity
- Pagination consistency
- Error handling

### Frontend Tests

```bash
# Web frontend
cd ahlQuran_Front
flutter test

# Mobile app
cd ahlQuran-Front-mobile
flutter test
```

### Manual Testing

**Guardian Mobile App:**
1. Start backend: `docker-compose up`
2. Run mobile app: `flutter run`
3. Login with test guardian credentials
4. Verify children list loads
5. Check attendance and achievement data
6. Test date filtering
7. Verify pagination

**Web Admin Dashboard:**
1. Login as president/supervisor/teacher
2. Test CRUD operations
3. Mark attendance
4. Record achievements
5. Send messages
6. Generate reports

## 📚 Documentation

### Backend Documentation
- `ahlQuran_Back/README.md` - Comprehensive backend setup guide
- `ahlQuran_Back/QUICK_START.md` - Quick start guide
- `ahlQuran_Back/MULTI_TENANCY_IMPLEMENTATION.md` - Multi-tenancy details
- `ahlQuran_Back/MESSAGING_SYSTEM.md` - Messaging API documentation
- `ahlQuran_Back/API_UPDATES_COMPLETED.md` - API update summary
- `ahlQuran_Back/DATABASE_BACKUP_GUIDE.md` - Backup procedures
- `ahlQuran_Back/MIGRATIONS.md` - Migration guide
- `ahlQuran_Back/DOCKER_MIGRATION_SETUP.md` - Docker setup

### Web Frontend Documentation
- `ahlQuran_Front/README.md` - Detailed folder structure guide
- `ahlQuran_Front/MESSAGING_USAGE.md` - Messaging dialog usage

### Mobile App Documentation
- `ahlQuran-Front-mobile/README.md` - Mobile app overview
- `ahlQuran-Front-mobile/GUARDIAN_LOGIN_SETUP.md` - Setup guide
- `ahlQuran-Front-mobile/GUARDIAN_CONNECTION_SUMMARY.md` - API integration
- `ahlQuran-Front-mobile/CONNECTION_FLOW.md` - Authentication flow
- `ahlQuran-Front-mobile/QUICK_TEST_GUIDE.md` - Testing guide
- `ahlQuran-Front-mobile/SETUP_INSTRUCTIONS.md` - Setup instructions
- `ahlQuran-Front-mobile/VERIFICATION_CHECKLIST.md` - Verification steps
- `ahlQuran-Front-mobile/NETWORK_TROUBLESHOOTING.md` - Network issues

### API Documentation
- Interactive Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🔧 Configuration

### Backend Configuration (.env)
```env
# Database
POSTGRES_USER=your_username
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=ahl_quran_db
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Security
SECRET_KEY=your_secret_key_here
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Mobile App Configuration
Edit `ahlQuran-Front-mobile/lib/services/api_config.dart`:
```dart
class ApiConfig {
  // Development
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Production
  // static const String baseUrl = 'https://your-domain.com';
  
  static const String apiVersion = '/api/v1';
}
```

### Web Frontend Configuration
Edit `ahlQuran_Front/lib/system/utils/const/api_endpoints.dart`:
```dart
static const String baseUrl = 'http://localhost:8000/api/v1';
```

## 🚀 Deployment

### Docker Deployment (Recommended)

```bash
# Production build
docker-compose -f docker-compose.prod.yml up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Manual Deployment

**Backend:**
```bash
cd ahlQuran_Back
pip install -r requirements.txt
alembic upgrade head
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker
```

**Web Frontend:**
```bash
cd ahlQuran_Front
flutter build web
# Deploy build/web/ to web server
```

**Mobile App:**
```bash
cd ahlQuran-Front-mobile

# Android
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk

# iOS
flutter build ios --release
# Submit to App Store
```

## 🔐 Security Features

- **Authentication:** JWT-based token authentication
- **Password Hashing:** Bcrypt with salt
- **Multi-tenancy:** Complete data isolation
- **Authorization:** Role-based access control (RBAC)
- **Read-only Guardian Access:** Guardians cannot modify data
- **SQL Injection Prevention:** SQLAlchemy ORM
- **CORS Configuration:** Configurable allowed origins
- **HTTPS Ready:** SSL/TLS support
- **Token Expiration:** Configurable token lifetime
- **Account Status:** Active/inactive user management


## 🐛 Troubleshooting

### Backend Issues

**Port 8000 already in use:**
```bash
# Windows
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Linux/Mac
lsof -ti:8000 | xargs kill -9
```

**Database connection refused:**
```bash
docker-compose restart db
docker-compose logs db
```

**Migration errors:**
```bash
alembic downgrade -1
alembic upgrade head
```

### Mobile App Issues

**Cannot connect to backend:**
- Android Emulator: Use `http://10.0.2.2:8000`
- iOS Simulator: Use `http://localhost:8000`
- Physical Device: Use `http://YOUR_COMPUTER_IP:8000`
- Check firewall settings
- Verify backend is running: `docker-compose ps`

**Login fails:**
- Verify guardian account exists in database
- Check account is active (`is_active = true`)
- Verify credentials are correct
- Check backend logs: `docker-compose logs web`

**Token not persisting:**
- Check SharedPreferences permissions
- Clear app data and retry
- Verify token is being saved in `auth_service.dart`

### Web Frontend Issues

**CORS errors:**
- Add frontend URL to `ALLOWED_ORIGINS` in backend `.env`
- Restart backend: `docker-compose restart web`

**API connection failed:**
- Verify `baseUrl` in `api_endpoints.dart`
- Check backend is running
- Test API directly: http://localhost:8000/docs

## 📊 System Requirements

### Development
- **OS:** Windows 10+, macOS 10.14+, or Linux
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 10GB free space
- **Docker:** Docker Desktop 4.0+ or Docker Engine 20.10+
- **Flutter:** Flutter 3.0+ with Dart 2.17+
- **Python:** Python 3.11+ (for local development)

### Production
- **Server:** 2 CPU cores, 4GB RAM minimum
- **Database:** PostgreSQL 15+
- **Storage:** 20GB+ depending on data volume
- **Network:** HTTPS/SSL certificate for production

## 🌍 Internationalization

### Current Support
- **Arabic (العربية):** Primary language for UI
- **English:** Secondary language for some fields

### Adding New Languages
1. Add translations to `lib/system/utils/const/translations.dart`
2. Update GetX locale configuration in `app.dart`
3. Add language selector in settings

## 🎨 Customization

### Branding
- Logo: Replace files in `assets/images/`
- Colors: Edit `lib/system/utils/theme.dart`
- Fonts: Add fonts to `assets/fonts/` and update `pubspec.yaml`

### Features
- Enable/disable features in `lib/system/utils/const/features.dart`
- Customize dashboard tiles in `lib/system/screens/admin_dashboard.dart`
- Modify report templates in `lib/reports/`

## 📈 Performance

### Backend Optimization
- Database indexing on frequently queried fields
- Async SQLAlchemy for concurrent requests
- Connection pooling
- Query optimization with eager loading

### Frontend Optimization
- Lazy loading for large lists
- Pagination for data tables
- Image caching
- Debounced search inputs

### Mobile App Optimization
- Token caching in SharedPreferences
- Pagination for attendance/achievements
- Efficient list rendering
- Background data refresh

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch:** `git checkout -b feature/amazing-feature`
3. **Commit your changes:** `git commit -m 'Add amazing feature'`
4. **Push to the branch:** `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Code Style
- **Python:** Follow PEP 8
- **Dart/Flutter:** Follow official Dart style guide
- **Commits:** Use conventional commit messages

### Testing
- Add tests for new features
- Ensure all tests pass before submitting PR
- Update documentation as needed

## 📝 License

[Add your license here - e.g., MIT, GPL, Apache 2.0]

## 👨‍💻 Authors & Contributors

[Add author information and contributors]

## 🙏 Acknowledgments

- FastAPI framework
- Flutter framework
- PostgreSQL database
- Syncfusion charts
- All open-source contributors

## 📞 Support & Contact

For support, questions, or feature requests:
- **Issues:** Open an issue on GitHub
- **Email:** [your-email@example.com]
- **Documentation:** See docs folder for detailed guides

## 🗺 Roadmap

### Planned Features
- [ ] WebSocket support for real-time messaging
- [ ] Push notifications for mobile app
- [ ] Biometric authentication for mobile
- [ ] Password reset flow
- [ ] Email notifications
- [ ] SMS notifications
- [ ] Advanced analytics dashboard
- [ ] Export data to Excel/CSV
- [ ] Bulk import students
- [ ] Parent-teacher messaging
- [ ] Calendar integration
- [ ] Homework assignments
- [ ] Exam management
- [ ] Certificate generation
- [ ] Multi-language support expansion

### Version History
- **v1.0.0** - Initial release with core features
  - Multi-tenancy support
  - Guardian mobile app
  - Attendance tracking
  - Achievement system
  - Messaging system
  - Reports and analytics

---

**Built with ❤️ for Quran education**
