# Import all models so they're registered with Base.metadata
# This is needed for alembic and create_all() to work
from app.models.user import User, UserRoleEnum
from app.models.president import President
from app.models.supervisor import Supervisor
from app.models.chief_supervisor import ChiefSupervisor
from app.models.teacher import Teacher
from app.models.student import Student
from app.models.guardian import Guardian
from app.models.admin import Admin
from app.models.session import Session
from app.models.sessionParticipation import SessionParticipation, ParticipationStatus
from app.models.acheivements import Achievement
from app.models.lecture import Lecture, WeeklySchedule
from app.models.message import Message
from app.models.attendance import Attendance, AttendanceStatus
from app.models.teacher_attendance import TeacherAttendance

__all__ = [
    "User",
    "UserRoleEnum",
    "President",
    "Supervisor",
    "ChiefSupervisor",
    "Teacher",
    "Student",
    "Guardian",
    "Admin",
    "Session",
    "SessionParticipation",
    "ParticipationStatus",
    "Achievement",
    "Lecture",
    "WeeklySchedule",
    "Message",
    "Attendance",
    "AttendanceStatus",
    "TeacherAttendance",
]