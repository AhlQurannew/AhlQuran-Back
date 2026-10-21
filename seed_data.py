"""
Seed script to populate database with test data
Run with: python seed_data.py
"""

import asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.db.session import get_db
from app.models.user import User, UserRoleEnum
from app.models.admin import Admin
from app.models.president import President
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.student import Student
from app.models.lecture import Lecture, lecture_teachers
from app.models.sessionParticipation import SessionParticipation
from app.core.security import get_password_hash
from datetime import datetime, timezone

async def clear_data(db: AsyncSession):
    """Clear existing data"""
    print("🗑️  Clearing existing data...")
    
    # Delete in reverse order of dependencies
    await db.execute(SessionParticipation.__table__.delete())
    await db.execute(lecture_teachers.delete())
    await db.execute(Student.__table__.delete())
    await db.execute(Teacher.__table__.delete())
    await db.execute(Lecture.__table__.delete())
    await db.execute(Supervisor.__table__.delete())
    await db.execute(President.__table__.delete())
    await db.execute(Admin.__table__.delete())
    await db.execute(User.__table__.delete())
    await db.commit()
    print("✅ Data cleared")

async def seed_data():
    """Seed the database with test data"""
    
    async for db in get_db():
        try:
            # Clear existing data
            await clear_data(db)
            
            print("\n🌱 Seeding data...\n")
            
            # ====================
            # 1. CREATE ADMIN
            # ====================
            print("👑 Creating Admin...")
            admin_user = User(
                firstname="Admin",
                lastname="System",
                email="admin@doctrine.com",
                password_hash=get_password_hash("admin123"),
                role=UserRoleEnum.ADMIN,
                is_active=True
            )
            db.add(admin_user)
            await db.flush()
            
            admin = Admin(
                user_id=admin_user.id,
                permissions="all"
            )
            db.add(admin)
            await db.commit()
            print(f"✅ Admin created - Email: admin@doctrine.com | Password: admin123")
            
            # ====================
            # 2. CREATE SCHOOLS (2 schools)
            # ====================
            print("\n🏫 Creating Schools...")
            
            # School 1
            school1_president_user = User(
                firstname="School1",
                lastname="President",
                email="school1@doctrine.com",
                password_hash=get_password_hash("school123"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db.add(school1_president_user)
            await db.flush()
            
            school1_president = President(
                user_id=school1_president_user.id,
                school_name="مدرسة النور",
                location="الجزائر العاصمة"
            )
            db.add(school1_president)
            await db.flush()
            print(f"✅ School 1 (مدرسة النور) - Email: school1@doctrine.com | Password: school123")
            
            # School 2
            school2_president_user = User(
                firstname="School2",
                lastname="President",
                email="school2@doctrine.com",
                password_hash=get_password_hash("school123"),
                role=UserRoleEnum.PRESIDENT,
                is_active=True
            )
            db.add(school2_president_user)
            await db.flush()
            
            school2_president = President(
                user_id=school2_president_user.id,
                school_name="مدرسة الهدى",
                location="وهران"
            )
            db.add(school2_president)
            await db.flush()
            print(f"✅ School 2 (مدرسة الهدى) - Email: school2@doctrine.com | Password: school123")
            
            # ====================
            # 3. SCHOOL 1 - STAFF & STUDENTS
            # ====================
            print(f"\n📚 Populating School 1 (مدرسة النور)...")
            
            # Chief Supervisor for School 1
            chief_sup1_user = User(
                firstname="أحمد",
                lastname="المشرف",
                email="chief1@doctrine.com",
                password_hash=get_password_hash("chief123"),
                role=UserRoleEnum.CHIEF_SUPERVISOR,
                is_active=True
            )
            db.add(chief_sup1_user)
            await db.flush()
            
            chief_sup1 = Supervisor(
                user_id=chief_sup1_user.id,
                president_id=school1_president.id,
                hire_date=datetime.now(timezone.utc).date(),
                is_senior=True
            )
            db.add(chief_sup1)
            print(f"  ✅ Chief Supervisor - Email: chief1@doctrine.com | Password: chief123")
            
            # Regular Supervisor for School 1
            supervisor1_user = User(
                firstname="فاطمة",
                lastname="المساعدة",
                email="supervisor1@doctrine.com",
                password_hash=get_password_hash("super123"),
                role=UserRoleEnum.SUPERVISOR,
                is_active=True
            )
            db.add(supervisor1_user)
            await db.flush()
            
            supervisor1 = Supervisor(
                user_id=supervisor1_user.id,
                president_id=school1_president.id,
                hire_date=datetime.now(timezone.utc).date(),
                is_senior=False
            )
            db.add(supervisor1)
            print(f"  ✅ Supervisor - Email: supervisor1@doctrine.com | Password: super123")
            
            # Teachers for School 1 (3 teachers)
            teachers_school1 = []
            for i in range(1, 4):
                teacher_user = User(
                    firstname=f"محمد{i}",
                    lastname="المعلم",
                    email=f"teacher{i}@doctrine.com",
                    password_hash=get_password_hash("teacher123"),
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
                print(f"  ✅ Teacher {i} - Email: teacher{i}@doctrine.com | Password: teacher123")
            
            # Lectures for School 1 (3 lectures)
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
                print(f"  ✅ Lecture: {name_ar} (assigned to Teacher {idx+1})")
            
            await db.commit()
            
            # Students for School 1 (5 students per lecture = 15 total)
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
                        password_hash=get_password_hash("student123"),
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
                        lecture_id=lecture.id,
                        president_id=school1_president.id
                    )
                    db.add(participation)
                    
                    student_counter += 1
                
                print(f"  ✅ Added 5 students to {lecture.lecture_name_ar}")
            
            await db.commit()
            print(f"  ✅ Total: 15 students in School 1")
            
            # ====================
            # 4. SCHOOL 2 - STAFF & STUDENTS
            # ====================
            print(f"\n📚 Populating School 2 (مدرسة الهدى)...")
            
            # Chief Supervisor for School 2
            chief_sup2_user = User(
                firstname="خالد",
                lastname="المشرف",
                email="chief2@doctrine.com",
                password_hash=get_password_hash("chief123"),
                role=UserRoleEnum.CHIEF_SUPERVISOR,
                is_active=True
            )
            db.add(chief_sup2_user)
            await db.flush()
            
            chief_sup2 = Supervisor(
                user_id=chief_sup2_user.id,
                president_id=school2_president.id,
                hire_date=datetime.now(timezone.utc).date(),
                is_senior=True
            )
            db.add(chief_sup2)
            print(f"  ✅ Chief Supervisor - Email: chief2@doctrine.com | Password: chief123")
            
            # Teachers for School 2 (2 teachers)
            teachers_school2 = []
            for i in range(4, 6):
                teacher_user = User(
                    firstname=f"محمد{i}",
                    lastname="المعلم",
                    email=f"teacher{i}@doctrine.com",
                    password_hash=get_password_hash("teacher123"),
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
                print(f"  ✅ Teacher {i} - Email: teacher{i}@doctrine.com | Password: teacher123")
            
            # Lectures for School 2 (2 lectures)
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
                print(f"  ✅ Lecture: {name_ar} (assigned to Teacher {idx+4})")
            
            await db.commit()
            
            # Students for School 2 (3 students per lecture = 6 total)
            for lecture_idx, lecture in enumerate(lectures_school2):
                for i in range(3):
                    student_user = User(
                        firstname=f"طالب{student_counter}",
                        lastname="الهدى",
                        email=f"student{student_counter}@doctrine.com",
                        password_hash=get_password_hash("student123"),
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
                        lecture_id=lecture.id,
                        president_id=school2_president.id
                    )
                    db.add(participation)
                    
                    student_counter += 1
                
                print(f"  ✅ Added 3 students to {lecture.lecture_name_ar}")
            
            await db.commit()
            print(f"  ✅ Total: 6 students in School 2")
            
            print("\n" + "="*60)
            print("✅ DATABASE SEEDED SUCCESSFULLY!")
            print("="*60)
            print("\n📋 LOGIN CREDENTIALS:\n")
            print("🔷 ADMIN:")
            print("   Email: admin@doctrine.com")
            print("   Password: admin123")
            print("\n🔷 SCHOOL 1 (مدرسة النور):")
            print("   President: school1@doctrine.com | school123")
            print("   Chief Supervisor: chief1@doctrine.com | chief123")
            print("   Supervisor: supervisor1@doctrine.com | super123")
            print("   Teachers: teacher1-3@doctrine.com | teacher123")
            print("   Students: student1-15@doctrine.com | student123")
            print("\n🔷 SCHOOL 2 (مدرسة الهدى):")
            print("   President: school2@doctrine.com | school123")
            print("   Chief Supervisor: chief2@doctrine.com | chief123")
            print("   Teachers: teacher4-5@doctrine.com | teacher123")
            print("   Students: student16-21@doctrine.com | student123")
            print("\n" + "="*60)
            
        except Exception as e:
            print(f"\n❌ Error: {e}")
            await db.rollback()
            raise
        finally:
            await db.close()

if __name__ == "__main__":
    asyncio.run(seed_data())
