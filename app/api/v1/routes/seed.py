"""
Seed endpoint to populate database with test data
Access via: POST /api/v1/seed/populate
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.admin import Admin
from app.models.president import President
from app.models.supervisor import Supervisor
from app.models.chief_supervisor import ChiefSupervisor
from app.models.teacher import Teacher
from app.models.student import Student
from app.models.lecture import Lecture, lecture_teachers
from app.models.sessionParticipation import SessionParticipation
from app.core.security import get_password_hash
from datetime import datetime, timezone
import logging

logger = logging.getLogger(__name__)
seedRouter = APIRouter()

@seedRouter.post("/populate")
async def populate_seed_data(db: AsyncSession = Depends(get_db)):
    """
    Populate database with test data
    ⚠️ WARNING: This will clear existing data!
    """
    
    try:
        logger.info("🌱 Starting database seed...")
        
        # Clear existing data
        logger.info("🗑️  Clearing existing data...")
        await db.execute(SessionParticipation.__table__.delete())
        await db.execute(lecture_teachers.delete())
        await db.execute(Student.__table__.delete())
        await db.execute(Teacher.__table__.delete())
        await db.execute(Lecture.__table__.delete())
        await db.execute(Supervisor.__table__.delete())
        await db.execute(ChiefSupervisor.__table__.delete())
        await db.execute(President.__table__.delete())
        await db.execute(Admin.__table__.delete())
        await db.execute(User.__table__.delete())
        await db.commit()
        logger.info("✅ Data cleared")
        
        # ====================
        # 1. CREATE ADMIN
        # ====================
        logger.info("👑 Creating Admin...")
        admin = Admin(
            user="admin@doctrine.com",
            password=get_password_hash("admin123"),
            role="admin"
        )
        db.add(admin)
        await db.commit()
        
        # ====================
        # 2. CREATE SCHOOL 1
        # ====================
        logger.info("🏫 Creating School 1...")
        school1_president_user = User(
            firstname="School1",
            lastname="President",
            email="school1@doctrine.com",
            hashed_password=get_password_hash("school123"),
            role=UserRoleEnum.PRESIDENT,
            is_active=True
        )
        db.add(school1_president_user)
        await db.flush()
        
        school1_president = President(
            user_id=school1_president_user.id,
            school_name="مدرسة النور"
        )
        db.add(school1_president)
        await db.flush()
        
        # Chief Supervisor
        chief_sup1_user = User(
            firstname="أحمد",
            lastname="المشرف",
            email="chief1@doctrine.com",
            hashed_password=get_password_hash("chief123"),
            role=UserRoleEnum.CHIEF_SUPERVISOR,
            is_active=True
        )
        db.add(chief_sup1_user)
        await db.flush()
        
        chief_sup1 = ChiefSupervisor(
            user_id=chief_sup1_user.id,
            president_id=school1_president.id
        )
        db.add(chief_sup1)
        
        # Regular Supervisor
        supervisor1_user = User(
            firstname="فاطمة",
            lastname="المساعدة",
            email="supervisor1@doctrine.com",
            hashed_password=get_password_hash("super123"),
            role=UserRoleEnum.SUPERVISOR,
            is_active=True
        )
        db.add(supervisor1_user)
        await db.flush()
        
        supervisor1 = Supervisor(
            user_id=supervisor1_user.id,
            president_id=school1_president.id
        )
        db.add(supervisor1)
        
        # Teachers (3)
        teachers_school1 = []
        for i in range(1, 4):
            teacher_user = User(
                firstname=f"محمد{i}",
                lastname="المعلم",
                email=f"teacher{i}@doctrine.com",
                hashed_password=get_password_hash("teacher123"),
                role=UserRoleEnum.TEACHER,
                is_active=True
            )
            db.add(teacher_user)
            await db.flush()
            
            teacher = Teacher(
                user_id=teacher_user.id,
                president_id=school1_president.id,
                riwaya="حفص عن عاصم",
                hire_date=datetime.now(timezone.utc).date()
            )
            db.add(teacher)
            await db.flush()
            teachers_school1.append(teacher)
        
        # Lectures (3)
        lectures_school1 = []
        lecture_names = [
            ("حلقة الفجر", "Dawn Circle"),
            ("حلقة الظهر", "Noon Circle"),
            ("حلقة العصر", "Afternoon Circle")
        ]
        
        for idx, (name_ar, name_en) in enumerate(lecture_names):
            lecture = Lecture(
                president_id=school1_president.id,
                lecture_name_ar=name_ar,
                lecture_name_en=name_en,
                circle_type="memorization and revision",
                category="both",
                shown_on_website=True
            )
            db.add(lecture)
            await db.flush()
            lectures_school1.append(lecture)
            
            # Assign teacher to lecture
            await db.execute(
                lecture_teachers.insert().values(
                    lecture_id=lecture.id,
                    teacher_id=teachers_school1[idx].id
                )
            )
        
        await db.commit()
        
        # Students (5 per lecture = 15 total)
        student_names = [
            ("عبد الله", "بن علي"),
            ("خديجة", "بنت محمد"),
            ("يوسف", "بن أحمد"),
            ("مريم", "بنت حسن"),
            ("عمر", "بن خالد")
        ]
        
        student_counter = 1
        for lecture_idx, lecture in enumerate(lectures_school1):
            for name_ar, lastname_ar in student_names:
                student_user = User(
                    firstname=name_ar,
                    lastname=lastname_ar,
                    email=f"student{student_counter}@doctrine.com",
                    hashed_password=get_password_hash("student123"),
                    role=UserRoleEnum.STUDENT,
                    is_active=True
                )
                db.add(student_user)
                await db.flush()
                
                student = Student(
                    user_id=student_user.id,
                    president_id=school1_president.id,
                    parent_name="ولي الأمر",
                    parent_phone="0555123456",
                    guardian_email=f"parent{student_counter}@doctrine.com",
                    sex="ذكر" if name_ar in ["عبد الله", "يوسف", "عمر"] else "أنثى",
                    nationality="Algerian",
                    academic_level="ابتدائي",
                    grade="السنة الخامسة",
                    school_name="مدرسة النجاح"
                )
                db.add(student)
                await db.flush()
                
                # Enroll student in lecture
                participation = SessionParticipation(
                    student_id=student.id,
                    lecture_id=lecture.id
                )
                db.add(participation)
                
                student_counter += 1
        
        await db.commit()
        
        # ====================
        # 3. CREATE SCHOOL 2
        # ====================
        logger.info("🏫 Creating School 2...")
        school2_president_user = User(
            firstname="School2",
            lastname="President",
            email="school2@doctrine.com",
            hashed_password=get_password_hash("school123"),
            role=UserRoleEnum.PRESIDENT,
            is_active=True
        )
        db.add(school2_president_user)
        await db.flush()
        
        school2_president = President(
            user_id=school2_president_user.id,
            school_name="مدرسة الهدى"
        )
        db.add(school2_president)
        await db.flush()
        
        # Chief Supervisor
        chief_sup2_user = User(
            firstname="خالد",
            lastname="المشرف",
            email="chief2@doctrine.com",
            hashed_password=get_password_hash("chief123"),
            role=UserRoleEnum.CHIEF_SUPERVISOR,
            is_active=True
        )
        db.add(chief_sup2_user)
        await db.flush()
        
        chief_sup2 = ChiefSupervisor(
            user_id=chief_sup2_user.id,
            president_id=school2_president.id
        )
        db.add(chief_sup2)
        
        # Teachers (2)
        teachers_school2 = []
        for i in range(4, 6):
            teacher_user = User(
                firstname=f"محمد{i}",
                lastname="المعلم",
                email=f"teacher{i}@doctrine.com",
                hashed_password=get_password_hash("teacher123"),
                role=UserRoleEnum.TEACHER,
                is_active=True
            )
            db.add(teacher_user)
            await db.flush()
            
            teacher = Teacher(
                user_id=teacher_user.id,
                president_id=school2_president.id,
                riwaya="ورش عن نافع",
                hire_date=datetime.now(timezone.utc).date()
            )
            db.add(teacher)
            await db.flush()
            teachers_school2.append(teacher)
        
        # Lectures (2)
        lectures_school2 = []
        lecture_names_2 = [
            ("حلقة الصباح", "Morning Circle"),
            ("حلقة المساء", "Evening Circle")
        ]
        
        for idx, (name_ar, name_en) in enumerate(lecture_names_2):
            lecture = Lecture(
                president_id=school2_president.id,
                lecture_name_ar=name_ar,
                lecture_name_en=name_en,
                circle_type="memorization and revision",
                category="both",
                shown_on_website=True
            )
            db.add(lecture)
            await db.flush()
            lectures_school2.append(lecture)
            
            # Assign teacher to lecture
            await db.execute(
                lecture_teachers.insert().values(
                    lecture_id=lecture.id,
                    teacher_id=teachers_school2[idx].id
                )
            )
        
        await db.commit()
        
        # Students (3 per lecture = 6 total)
        for lecture_idx, lecture in enumerate(lectures_school2):
            for i in range(3):
                student_user = User(
                    firstname=f"طالب{student_counter}",
                    lastname="الهدى",
                    email=f"student{student_counter}@doctrine.com",
                    hashed_password=get_password_hash("student123"),
                    role=UserRoleEnum.STUDENT,
                    is_active=True
                )
                db.add(student_user)
                await db.flush()
                
                student = Student(
                    user_id=student_user.id,
                    president_id=school2_president.id,
                    parent_name="ولي الأمر",
                    parent_phone="0555123456",
                    guardian_email=f"parent{student_counter}@doctrine.com",
                    sex="ذكر",
                    nationality="Algerian",
                    academic_level="إعدادي",
                    grade="السنة الأولى",
                    school_name="مدرسة التميز"
                )
                db.add(student)
                await db.flush()
                
                # Enroll student in lecture
                participation = SessionParticipation(
                    student_id=student.id,
                    lecture_id=lecture.id
                )
                db.add(participation)
                
                student_counter += 1
        
        await db.commit()
        
        logger.info("✅ DATABASE SEEDED SUCCESSFULLY!")
        
        return {
            "message": "Database seeded successfully!",
            "credentials": {
                "admin": {
                    "email": "admin@doctrine.com",
                    "password": "admin123"
                },
                "school1": {
                    "president": "school1@doctrine.com | school123",
                    "chief_supervisor": "chief1@doctrine.com | chief123",
                    "supervisor": "supervisor1@doctrine.com | super123",
                    "teachers": "teacher1-3@doctrine.com | teacher123",
                    "students": "student1-15@doctrine.com | student123",
                    "details": "School: مدرسة النور, 3 lectures, 15 students"
                },
                "school2": {
                    "president": "school2@doctrine.com | school123",
                    "chief_supervisor": "chief2@doctrine.com | chief123",
                    "teachers": "teacher4-5@doctrine.com | teacher123",
                    "students": "student16-21@doctrine.com | student123",
                    "details": "School: مدرسة الهدى, 2 lectures, 6 students"
                }
            }
        }
        
    except Exception as e:
        logger.error(f"❌ Seed error: {e}")
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Seed failed: {str(e)}"
        )
