"""Realistic demo data: 3 schools (Oran, Alger, Annaba) with ~18 months of activity.

    python -m app.cli.seed_demo            # create (refuses if the demo schools already exist)
    python -m app.cli.seed_demo --purge    # remove everything this script created
    python -m app.cli.seed_demo --months 18 --students 90
    python -m app.cli.seed_demo --academics  # add specialities and exams to existing demo schools

Every demo account uses the password DEMO_PASSWORD and an e-mail on DEMO_DOMAIN (guardians
use a firstname_lastname username). The data is deterministic (fixed random seed), and each
school follows its own trend so the analytics have something to show: Oran is strong and
steady, Alger improves over time, Annaba dips mid-period and recovers. Attendance drops in
summer, students join throughout the period and a few drop out.
"""
import argparse
import asyncio
import random
import sys
from datetime import date, datetime, time, timedelta, timezone

from sqlalchemy import delete, func, insert, select

from app.core.quran_pages import QURAN_PAGES
from app.core.security import get_password_hash
from app.db.session import SessionLocal, engine
from app.models.acheivements import Achievement
from app.models.attendance import Attendance, AttendanceStatus
from app.models.chief_supervisor import ChiefSupervisor
from app.models.exam import Exam, ExamResult
from app.models.guardian import Guardian
from app.models.lecture import Lecture, WeeklySchedule, lecture_teachers
from app.models.message import Message, SenderRole
from app.models.president import President
from app.models.speciality import Speciality, SpecialityLecture
from app.models.sessionParticipation import SessionParticipation
from app.models.student import Student
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.teacher_attendance import TeacherAttendance
from app.models.teacher_note import TeacherNote
from app.models.user import User, UserRoleEnum
from app.services.specialities import set_student_lectures
from app.services.usernames import base_username

DEMO_DOMAIN = "demo.ahlquran.dz"
DEMO_PASSWORD = "Demo-2026-pass"
SEED = 2026

SCHOOLS = [
    # name, city slug, phone, attendance base, trend(month_index, months) -> delta
    {"name": "مدرسة الفرقان القرآنية — وهران", "city": "oran", "city_ar": "وهران", "phone": "041 22 33 44",
     "base": 0.90, "trend": lambda m, n: 0.0},
    {"name": "مدرسة النور القرآنية — الجزائر", "city": "alger", "city_ar": "الجزائر", "phone": "021 55 66 77",
     "base": 0.74, "trend": lambda m, n: 0.14 * m / max(1, n - 1)},
    {"name": "مدرسة الهدى القرآنية — عنابة", "city": "annaba", "city_ar": "عنابة", "phone": "038 11 22 33",
     "base": 0.84, "trend": lambda m, n: -0.16 * max(0.0, 1 - abs(m - n / 2) / (n / 4))},
]

MALE = ["محمد", "أحمد", "يوسف", "عبد الله", "إبراهيم", "عمر", "علي", "حمزة", "بلال", "أنس", "ياسين", "إسماعيل",
        "عبد الرحمن", "مصطفى", "خالد", "زكرياء", "إلياس", "أيوب", "سفيان", "هشام", "رضا", "نذير", "وليد", "أمين"]
FEMALE = ["فاطمة", "مريم", "خديجة", "عائشة", "آمنة", "سارة", "هاجر", "إيمان", "أسماء", "زينب", "نور", "ملاك",
          "رميساء", "شيماء", "سلمى", "هبة", "لينة", "دعاء", "ياسمين", "إكرام", "صفية", "حفصة", "رقية", "بشرى"]
LAST = ["بن علي", "بوزيد", "حداد", "منصوري", "شريف", "سعيدي", "قاسي", "رحماني", "بلقاسم", "عمراني", "زروقي",
        "بوعلام", "مزيان", "تواتي", "بن يحيى", "حمادي", "لعربي", "بلعيد", "صالحي", "دراجي", "بن عمر", "عيساوي"]
CIRCLES = ["حلقة الإمام ورش", "حلقة أبي بكر الصديق", "حلقة عمر بن الخطاب", "حلقة أم المؤمنين خديجة",
           "حلقة الإمام نافع", "حلقة عائشة رضي الله عنها", "حلقة الفاروق", "حلقة البراعم"]
SPECIALITIES = ["التجويد", "القراءات", "الحفظ والمراجعة", "التفسير", "الفقه", "اللغة العربية"]
RIWAYAT = ["ورش عن نافع", "حفص عن عاصم", "قالون عن نافع"]
MEDICAL = ["ربو خفيف", "حساسية من الغبار", "ضعف في البصر", "سكري من النوع الأول", "صداع متكرر"]
# (days, start, end) — days are Python weekdays (Mon=0 ... Sun=6)
SCHEDULES = [((5, 0, 2), "16:00", "18:00"), ((6, 1, 3), "17:00", "19:00"), ((4, 5), "09:00", "11:30"),
             ((5, 1, 3), "14:00", "16:00"), ((6, 2), "17:30", "19:30"), ((0, 2, 4), "08:30", "10:30")]
AR_DAYS = ["الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت", "الأحد"]
CHAT = [
    "السلام عليكم، تذكير بموعد المراجعة الكبرى يوم السبت إن شاء الله.",
    "بارك الله فيكم، نسبة الحضور هذا الأسبوع ممتازة.",
    "الرجاء من المعلمين تسجيل الحضور قبل نهاية كل حصة.",
    "تم تحديث جدول الحلقات للفصل القادم.",
    "نذكّر الأولياء بمتابعة مراجعة أبنائهم في البيت.",
    "اجتماع المعلمين يوم الخميس بعد صلاة العصر.",
    "مبارك للطلاب الذين أتموا حفظ جزء عمّ هذا الشهر.",
    "سيكون هناك اختبار شهري للتجويد الأسبوع القادم.",
]
# Specialities: (name, is_common, [(circle index, coefficient)]) — each circle belongs to one speciality
DEMO_SPECIALITIES = [
    ("الجذع المشترك", True, [(0, 2), (1, 1.5)]),
    ("الفقه والعلوم الشرعية", False, [(2, 3), (3, 1)]),
    ("التلاوة والتجويد", False, [(4, 2.5), (5, 1.5)]),
]
EXAM_GOOD = ["حفظ متقن وأداء ممتاز", "تجويد سليم، واصل", "مراجعة قوية ومخارج حروف واضحة", "تحسن ملحوظ هذا الشهر"]
EXAM_WEAK = ["يحتاج إلى مراجعة المحفوظ", "أخطاء في أحكام المد", "تردد في الحفظ، يُنصح بالتكرار", "ضعف في المراجعة"]


def pick(rng, items):
    return items[rng.randrange(len(items))]


def months_between(start: date, end: date) -> int:
    return (end.year - start.year) * 12 + end.month - start.month + 1


def seasonal(day: date) -> float:
    """Summer break and exam periods lower attendance."""
    if day.month in (7, 8):
        return -0.12
    if (day.month == 12 and day.day >= 10) or (day.month == 5 and day.day >= 15) or (day.month == 3 and day.day >= 10 and day.day <= 25):
        return -0.05
    return 0.0


def page_range(start_page: int, end_page: int) -> tuple[int, int, int, int]:
    """(from_surah, from_verse, to_surah, to_verse) spanning Mushaf pages start..end (inclusive)."""
    lo, hi = sorted((max(1, start_page), min(604, end_page)))
    fs, fv = QURAN_PAGES[lo]
    ts, tv = QURAN_PAGES[hi]
    return fs, fv, ts, tv


class Seeder:
    def __init__(self, session, months: int, students_per_school: int):
        self.s = session
        self.rng = random.Random(SEED)
        self.end = date.today() - timedelta(days=1)
        self.start = self.end - timedelta(days=round(months * 30.44))
        self.months = months_between(self.start, self.end)
        self.students_per_school = students_per_school
        self.hash = get_password_hash(DEMO_PASSWORD)  # one bcrypt hash reused by every demo account
        self.emails: set[str] = set()
        self.usernames: set[str] = set()
        self.counters = {"S": 0, "T": 0}
        self.taken_numbers: set[str] = set()
        self.stats = {k: 0 for k in ("schools", "supervisors", "teachers", "lectures", "students", "guardians",
                                     "attendance", "achievements", "teacher_attendance", "messages", "notes")}

    # ---------------------------------------------------------------- helpers
    def email(self, local: str) -> str:
        base, n = local, 1
        while f"{local}@{DEMO_DOMAIN}" in self.emails:
            n += 1
            local = f"{base}{n}"
        self.emails.add(f"{local}@{DEMO_DOMAIN}")
        return f"{local}@{DEMO_DOMAIN}"

    def username(self, first: str, last: str) -> str:
        base = base_username(first, last)
        candidate, n = base, 1
        while candidate in self.usernames:
            n += 1
            candidate = f"{base}{n}"
        self.usernames.add(candidate)
        return candidate

    def number(self, prefix: str, year: int) -> str:
        """Next free registration number; skips the ones real accounts already use."""
        while True:
            self.counters[prefix] += 1
            candidate = f"{prefix}{year}-{self.counters[prefix]:04d}"
            if candidate not in self.taken_numbers:
                self.taken_numbers.add(candidate)
                return candidate

    async def user(self, first, last, email, role, created_at=None, active=True) -> User:
        user = User(firstname=first, lastname=last, email=email, hashed_password=self.hash, role=role, is_active=active)
        self.s.add(user)
        await self.s.flush()
        return user

    def when(self, day: date, hour: int = 17) -> datetime:
        return datetime.combine(day, time(hour, self.rng.randrange(60)), tzinfo=timezone.utc)

    # ---------------------------------------------------------------- build
    async def run(self) -> dict:
        names = [school["name"] for school in SCHOOLS]
        existing = (await self.s.execute(select(President.id).where(President.school_name.in_(names)))).first()
        if existing:
            raise SystemExit("Demo schools already exist. Run with --purge first.")
        # The database may already hold real accounts: never reuse their identifiers.
        for model in (Student, Teacher):
            self.taken_numbers |= set((await self.s.execute(
                select(model.registration_number).where(model.registration_number.is_not(None)))).scalars())
        existing_logins = set((await self.s.execute(select(User.email))).scalars())
        self.emails |= existing_logins
        self.usernames |= existing_logins
        for index, school in enumerate(SCHOOLS):
            await self.school(index, school)
            await self.s.commit()
            print(f"  {school['name']}: done", flush=True)
        self.stats.update(await seed_academics(self.s))
        return self.stats

    async def school(self, index: int, cfg: dict) -> None:
        rng = self.rng
        city = cfg["city"]
        opened = self.start - timedelta(days=rng.randrange(200, 600))

        placeholder = await self.user("System", "Admin", self.email(f"system.{city}"), UserRoleEnum.PRESIDENT)
        president = President(user_id=placeholder.id, school_name=cfg["name"], phone_number=cfg["phone"],
                              approval_date=datetime.combine(opened, time(9)), is_verified=True)
        self.s.add(president)
        await self.s.flush()
        self.stats["schools"] += 1

        chief_first, chief_last = pick(rng, MALE), pick(rng, LAST)
        chief = await self.user(chief_first, chief_last, self.email(f"chef.{city}"), UserRoleEnum.CHIEF_SUPERVISOR)
        self.s.add(ChiefSupervisor(user_id=chief.id, president_id=president.id, created_by_id=placeholder.id))

        supervisors = []
        for k in range(2):
            first = pick(rng, MALE if k == 0 else FEMALE)
            sup = await self.user(first, pick(rng, LAST), self.email(f"superviseur{k + 1}.{city}"), UserRoleEnum.SUPERVISOR)
            self.s.add(Supervisor(user_id=sup.id, president_id=president.id, created_by_id=chief.id))
            supervisors.append(sup)
            self.stats["supervisors"] += 1

        teachers = []
        for k in range(6):
            female = k in (2, 5)
            first, last = pick(rng, FEMALE if female else MALE), pick(rng, LAST)
            tu = await self.user(first, last, self.email(f"enseignant{k + 1}.{city}"), UserRoleEnum.TEACHER)
            hired = opened + timedelta(days=rng.randrange(0, 300))
            birth = date(rng.randrange(1965, 1998), rng.randrange(1, 13), rng.randrange(1, 28))
            teacher = Teacher(
                user_id=tu.id, president_id=president.id, riwaya=pick(rng, RIWAYAT), created_by_id=chief.id,
                hire_date=datetime.combine(hired, time(9), tzinfo=timezone.utc),
                registration_number=self.number("T", hired.year),
                speciality=pick(rng, SPECIALITIES), date_of_birth=birth.isoformat(),
                place_of_birth=cfg["city_ar"], phone_number=f"0{rng.choice([5, 6, 7])}{rng.randrange(10**7, 10**8)}",
                address=f"{cfg['city_ar']}", medical_condition=pick(rng, MEDICAL) if rng.random() < 0.1 else None,
            )
            self.s.add(teacher)
            await self.s.flush()
            teachers.append((teacher, tu, female))
            self.stats["teachers"] += 1

        # Circles: 6 per school, each with a schedule and 1 teacher (2 for the large ones)
        lectures = []
        circle_names = rng.sample(CIRCLES, 6)
        for k in range(6):
            days, start_t, end_t = SCHEDULES[k]
            teacher, tu, female = teachers[k]
            category = "female" if female else ("male" if k % 2 == 0 else "both")
            lecture = Lecture(president_id=president.id, lecture_name_ar=f"{circle_names[k]}",
                              lecture_name_en=f"Circle {k + 1} — {city.title()}", circle_type="حفظ ومراجعة",
                              category=category, shown_on_website=k < 3)
            self.s.add(lecture)
            await self.s.flush()
            await self.s.execute(insert(lecture_teachers), [{"lecture_id": lecture.id, "teacher_id": teacher.id}])
            for d in days:
                self.s.add(WeeklySchedule(lecture_id=lecture.id, day_of_week=AR_DAYS[d], start_time=start_t, end_time=end_t))
            # each circle has its own quality around the school's level
            lectures.append({"lecture": lecture, "days": set(days), "teacher": teacher, "teacher_user": tu,
                             "female": female, "category": category, "offset": rng.uniform(-0.06, 0.05)})
            self.stats["lectures"] += 1
        await self.s.flush()

        await self.students(president, chief, cfg, lectures)
        await self.messages(president, chief, supervisors, lectures)

    async def students(self, president, chief, cfg, lectures) -> None:
        rng = self.rng
        attendance_rows, achievement_rows, teacher_rows = [], [], []
        guardians: list[tuple[Guardian, str]] = []  # (guardian, family name) for siblings

        for k in range(self.students_per_school):
            info = lectures[k % len(lectures)]
            female = info["category"] == "female" or (info["category"] == "both" and rng.random() < 0.5)
            first = pick(rng, FEMALE if female else MALE)

            # ~30% siblings: reuse an existing guardian of the school
            if guardians and rng.random() < 0.3:
                guardian, family = pick(rng, guardians)
            else:
                family = pick(rng, LAST)
                g_first = pick(rng, MALE if rng.random() < 0.7 else FEMALE)
                g_user = await self.user(g_first, family, self.username(g_first, family), UserRoleEnum.GUARDIAN)
                guardian = Guardian(user_id=g_user.id, president_id=president.id, first_name=g_first, last_name=family,
                                    relationship_to_student="أب" if g_first in MALE else "أم",
                                    phone_number=f"0{rng.choice([5, 6, 7])}{rng.randrange(10**7, 10**8)}",
                                    job=pick(rng, ["أستاذ", "مهندس", "طبيب", "تاجر", "موظف", "ممرضة", "محاسب", None]),
                                    address=cfg["city_ar"], created_by_id=chief.id)
                self.s.add(guardian)
                await self.s.flush()
                guardians.append((guardian, family))
                self.stats["guardians"] += 1

            # Enrollment: 55% were already there, the rest join during the period
            if rng.random() < 0.55:
                joined = self.start - timedelta(days=rng.randrange(30, 700))
            else:
                joined = self.start + timedelta(days=rng.randrange(0, (self.end - self.start).days - 30))
            dropped = joined + timedelta(days=rng.randrange(90, 400)) if rng.random() < 0.06 else None
            age = rng.randrange(7, 17)
            birth = date(self.end.year - age, rng.randrange(1, 13), rng.randrange(1, 28))

            s_user = await self.user(first, family, self.email(f"eleve.{base_username(first, family)}"),
                                     UserRoleEnum.STUDENT, active=dropped is None)
            student = Student(
                user_id=s_user.id, president_id=president.id, created_by_id=chief.id, guardian_id=guardian.id,
                enrollment_date=datetime.combine(joined, time(10), tzinfo=timezone.utc),
                parent_name=f"{guardian.first_name} {guardian.last_name}", parent_phone=guardian.phone_number,
                sex="Féminin" if female else "Masculin", date_of_birth=birth.strftime("%d/%m/%Y"),
                place_of_birth=cfg["city_ar"], nationality="Algerian", academic_level=None,
                registration_number=self.number("S", joined.year),
                enrollment_type="external" if rng.random() < 0.35 else "internal",
                start_year=joined.year,
                medical_condition=pick(rng, MEDICAL) if rng.random() < 0.08 else None,
            )
            self.s.add(student)
            await self.s.flush()
            self.s.add(SessionParticipation(student_id=student.id, lecture_id=info["lecture"].id))
            self.stats["students"] += 1

            # Personal profile: regularity and pace
            regularity = rng.gauss(0, 0.08)  # personal offset on top of the school/circle level
            pace = rng.choice([0.5, 0.5, 1, 1, 1, 1.5])  # pages per new-memorization session
            page = rng.choice([604, 604, 604, 590, 560, 520, 480])  # Maghreb tradition: start from the end
            memorized_low = page + 1  # lowest memorized page (memorization moves towards page 1)
            day = max(joined, self.start)
            last_day = min(dropped or self.end, self.end)
            while day <= last_day:
                if day.weekday() in info["days"]:
                    month_index = months_between(self.start, day) - 1
                    p = (cfg["base"] + cfg["trend"](month_index, self.months) + info["offset"]
                         + seasonal(day) + regularity + rng.gauss(0, 0.02))
                    attended = rng.random() < min(0.995, max(0.2, p))
                    if attended:
                        status = "late" if rng.random() < 0.09 else "present"
                    else:
                        status = "excused" if rng.random() < 0.3 else "absent"
                    attendance_rows.append({"student_id": student.id, "president_id": president.id,
                                            "lecture_id": info["lecture"].id, "date": day, "status": status,
                                            "created_at": self.when(day)})
                    if attended and rng.random() < 0.75:
                        roll = rng.random()
                        if roll < 0.55 and memorized_low > 1:  # new memorization
                            size = max(1, round(pace * rng.uniform(0.6, 1.4)))
                            top = memorized_low - 1
                            bottom = max(1, top - size + 1)
                            kind, rng_pages = "normal", (bottom, top)
                            memorized_low = bottom
                        elif memorized_low <= 604:  # review of already memorized pages
                            big = roll > 0.94
                            size = rng.randrange(6, 13) if big else rng.randrange(1, 4)
                            low = rng.randrange(memorized_low, 605)
                            kind, rng_pages = ("big" if big else "small"), (low, min(604, low + size - 1))
                        else:
                            kind = None
                        if kind:
                            fs, fv, ts, tv = page_range(*rng_pages)
                            achievement_rows.append({"student_id": student.id, "president_id": president.id,
                                                     "from_surah": fs, "from_verse": fv, "to_surah": ts, "to_verse": tv,
                                                     "achievement_type": kind, "date": day.strftime("%d-%m-%Y"),
                                                     "note": None, "created_at": self.when(day, 18)})
                day += timedelta(days=1)

        # Teacher attendance on their teaching days
        for info in lectures:
            day = self.start
            reliability = self.rng.uniform(0.9, 0.99)
            while day <= self.end:
                if day.weekday() in info["days"]:
                    r = self.rng.random()
                    status = "present" if r < reliability else "late" if r < reliability + 0.03 else "excused" if r < reliability + 0.05 else "absent"
                    teacher_rows.append({"teacher_id": info["teacher"].id, "president_id": president.id,
                                         "date": day.strftime("%d-%m-%Y"), "status": status, "created_at": self.when(day)})
                day += timedelta(days=1)
            for n in range(3):
                self.s.add(TeacherNote(user_id=info["teacher_user"].id, title=pick(self.rng, [
                    "خطة المراجعة الشهرية", "ملاحظات عن الطلاب الجدد", "أفكار لتحفيز الحضور", "تحضير اختبار التجويد"]),
                    content="- متابعة الطلاب المتأخرين في الحفظ\n- مراجعة جماعية للأحزاب الأخيرة\n- التواصل مع الأولياء",
                    pinned=n == 0))
                self.stats["notes"] += 1

        for table, rows, key in ((Attendance, attendance_rows, "attendance"), (Achievement, achievement_rows, "achievements"),
                                 (TeacherAttendance, teacher_rows, "teacher_attendance")):
            for i in range(0, len(rows), 2000):
                await self.s.execute(insert(table), rows[i:i + 2000])
            self.stats[key] += len(rows)

    async def messages(self, president, chief, supervisors, lectures) -> None:
        senders = [(chief, SenderRole.CHIEF_SUPERVISOR)] + [(s, SenderRole.SUPERVISOR) for s in supervisors] + \
                  [(info["teacher_user"], SenderRole.TEACHER) for info in lectures]
        rows = []
        for n in range(40):
            user, role = pick(self.rng, senders)
            day = self.start + timedelta(days=round((self.end - self.start).days * n / 40) + self.rng.randrange(5))
            rows.append({"sender_id": user.id, "sender_name": f"{user.firstname} {user.lastname}", "sender_role": role,
                         "president_id": president.id, "message": pick(self.rng, CHAT), "created_at": self.when(min(day, self.end), 19)})
        await self.s.execute(insert(Message), rows)
        self.stats["messages"] += len(rows)


async def seed_academics(s) -> dict:
    """Specialities (with circle coefficients) and about a year of exams for each demo school without exams.

    Marks follow each student's attendance rate so the rankings are plausible; the latest exam of
    the first circle keeps a few marks pending and every circle has one upcoming exam.
    """
    rng = random.Random(SEED + 17)
    today = date.today()
    stats = {"specialities": 0, "exams": 0, "exam_results": 0}
    names = [school["name"] for school in SCHOOLS]
    schools = list((await s.execute(
        select(President.id).where(President.school_name.in_(names)).order_by(President.id))).scalars())
    for president_id in schools:
        if await s.scalar(select(Exam.id).where(Exam.president_id == president_id).limit(1)):
            continue
        lectures = list((await s.execute(
            select(Lecture).where(Lecture.president_id == president_id).order_by(Lecture.id))).scalars())
        if len(lectures) < 6:
            continue
        lecture_ids = [lecture.id for lecture in lectures]
        teacher_user = dict((await s.execute(
            select(lecture_teachers.c.lecture_id, Teacher.user_id)
            .join(Teacher, Teacher.id == lecture_teachers.c.teacher_id)
            .where(lecture_teachers.c.lecture_id.in_(lecture_ids))
        )).all())

        # Specialities: the students of a circle join its speciality (and so its other circle)
        if not await s.scalar(select(Speciality.id).where(Speciality.president_id == president_id).limit(1)):
            for name, common, circles in DEMO_SPECIALITIES:
                spec = Speciality(
                    president_id=president_id, name=name, is_common=common,
                    description="الحلقات الأساسية لجميع الطلاب" if common else "تخصص تجريبي",
                    lectures=[SpecialityLecture(lecture_id=lectures[i].id, coefficient=c) for i, c in circles],
                )
                s.add(spec)
                await s.flush()
                stats["specialities"] += 1
                circle_ids = [lectures[i].id for i, _ in circles]
                members = list((await s.execute(
                    select(SessionParticipation.student_id)
                    .where(SessionParticipation.lecture_id.in_(circle_ids), SessionParticipation.session_id.is_(None))
                    .distinct()
                )).scalars())
                for student_id in members:
                    if rng.random() < 0.85:  # a few students stay without a speciality
                        await s.execute(Student.__table__.update().where(Student.id == student_id).values(speciality_id=spec.id))
                        await set_student_lectures(s, student_id, circle_ids)
            await s.flush()

        # Ability per student from their attendance rate
        rates = {
            sid: present / total
            for sid, present, total in (await s.execute(
                select(Attendance.student_id,
                       func.count().filter(Attendance.status.in_([AttendanceStatus.PRESENT, AttendanceStatus.LATE])),
                       func.count())
                .where(Attendance.president_id == president_id).group_by(Attendance.student_id)
            )).all() if total
        }
        enrolled: dict[int, list] = {}
        for lecture_id, student_id, joined in (await s.execute(
            select(SessionParticipation.lecture_id, Student.id, Student.enrollment_date)
            .join(Student, Student.id == SessionParticipation.student_id)
            .where(SessionParticipation.lecture_id.in_(lecture_ids), SessionParticipation.session_id.is_(None))
            .order_by(Student.id)
        )).all():
            enrolled.setdefault(lecture_id, []).append((student_id, joined.date() if joined else None))
        ability = {sid: min(0.97, max(0.2, 0.2 + 0.55 * rates.get(sid, 0.75) + rng.gauss(0, 0.12)))
                   for members in enrolled.values() for sid, _ in members}

        for index, lecture in enumerate(lectures):
            plans = []
            for months_ago in range(12, 0, -2):  # a monthly exam every two months over the last year
                day = today - timedelta(days=months_ago * 30 + rng.randrange(0, 6))
                plans.append(("monthly", f"الامتحان الشهري — {day.strftime('%m/%Y')}", day))
            for months_ago, kind, title in ((11, "term", "امتحان الفصل الأول"), (7, "term", "امتحان الفصل الثاني"),
                                            (3, "tajwid", "امتحان التجويد")):
                plans.append((kind, title, today - timedelta(days=months_ago * 30 - rng.randrange(0, 6))))
            plans.append(("monthly", "الامتحان الشهري القادم", today + timedelta(days=7 + index * 2)))
            plans.sort(key=lambda item: item[2])
            last_past = max(i for i, plan in enumerate(plans) if plan[2] <= today)
            for i, (kind, title, day) in enumerate(plans):
                exam = Exam(president_id=president_id, lecture_id=lecture.id, title=title, exam_type=kind, exam_date=day,
                            max_mark=20, pass_mark=10, created_by_id=teacher_user.get(lecture.id),
                            notes=pick(rng, ["سورة البقرة", "جزء عمّ", "حزب سبّح", "أحكام النون الساكنة", "مراجعة عامة", None]))
                s.add(exam)
                await s.flush()
                stats["exams"] += 1
                rows = []
                for student_id, joined in enrolled.get(lecture.id, []):
                    if day > today:  # upcoming: the circle's roster, nothing recorded yet (as the app creates it)
                        rows.append({"exam_id": exam.id, "student_id": student_id, "attendance": "present",
                                     "mark": None, "notes": None})
                        continue
                    if joined and joined > day:
                        continue
                    roll = rng.random()
                    attendance = "absent" if roll < 0.07 else "excused" if roll < 0.11 else "present"
                    mark = None
                    pending = i == last_past and index == 0 and rng.random() < 0.25
                    if attendance == "present" and not pending:
                        level = ability[student_id] + (0.04 if kind == "tajwid" else 0) + rng.gauss(0, 0.07)
                        mark = round(min(20, max(2, level * 20)) * 4) / 4
                    note = None
                    if mark is not None and rng.random() < 0.35:
                        note = pick(rng, EXAM_GOOD if mark >= 14 else EXAM_WEAK if mark < 10 else EXAM_GOOD + EXAM_WEAK)
                    rows.append({"exam_id": exam.id, "student_id": student_id, "attendance": attendance,
                                 "mark": mark, "notes": note})
                if rows:
                    await s.execute(insert(ExamResult), rows)
                    stats["exam_results"] += len(rows)
        await s.commit()
    return stats


async def purge() -> None:
    names = [school["name"] for school in SCHOOLS]
    async with SessionLocal() as s:
        ids = list((await s.execute(select(President.id).where(President.school_name.in_(names)))).scalars())
        users = set()
        for model in (ChiefSupervisor, Supervisor, Teacher, Student, Guardian):
            users |= set((await s.execute(select(model.user_id).where(model.president_id.in_(ids)))).scalars())
        users |= set((await s.execute(select(President.user_id).where(President.id.in_(ids)))).scalars())
        users |= set((await s.execute(select(User.id).where(User.email.like(f"%@{DEMO_DOMAIN}")))).scalars())
        await s.execute(delete(Message).where(Message.president_id.in_(ids)))
        await s.execute(delete(President).where(President.id.in_(ids)))  # cascades to the school's data
        if users:
            await s.execute(delete(User).where(User.id.in_(list(users))))
        await s.commit()
    print(f"Removed {len(ids)} demo schools and {len(users)} accounts.")


async def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--purge", action="store_true", help="remove the demo data")
    parser.add_argument("--months", type=int, default=18)
    parser.add_argument("--students", type=int, default=90, help="students per school")
    parser.add_argument("--academics", action="store_true", help="add specialities and exams to the existing demo schools")
    args = parser.parse_args()
    try:
        if args.purge:
            await purge()
            return 0
        if args.academics:
            async with SessionLocal() as session:
                stats = await seed_academics(session)
            print("Created:", ", ".join(f"{k}={v}" for k, v in stats.items()))
            return 0
        async with SessionLocal() as session:
            seeder = Seeder(session, args.months, args.students)
            print(f"Seeding {seeder.start} -> {seeder.end} ...", flush=True)
            stats = await seeder.run()
        print("Created:", ", ".join(f"{k}={v}" for k, v in stats.items()))
        print(f"All demo accounts use the password: {DEMO_PASSWORD}")
        for school in SCHOOLS:
            print(f"  chief supervisor: chef.{school['city']}@{DEMO_DOMAIN}")
        return 0
    finally:
        await engine.dispose()


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
