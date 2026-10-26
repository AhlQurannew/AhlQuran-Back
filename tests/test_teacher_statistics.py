from datetime import date

import pytest

from app.api.v1.routes.teacher import (
    get_teacher_attendance_trend,
    get_teacher_lecture_distribution,
    get_teacher_statistics_summary,
    get_teacher_top_memorizers,
)
from app.models.acheivements import Achievement, AchievementType
from app.models.attendance import Attendance, AttendanceStatus
from app.models.lecture import Lecture
from app.models.president import President
from app.models.sessionParticipation import SessionParticipation
from app.models.student import Student
from app.models.teacher import Teacher
from app.models.user import User, UserRoleEnum


def make_user(email: str, role: UserRoleEnum, firstname: str) -> User:
    return User(
        firstname=firstname,
        lastname="Statistics",
        email=email,
        hashed_password="test-hash",
        role=role,
        is_active=True,
    )


@pytest.mark.asyncio
async def test_teacher_statistics_return_empty_data_when_no_lectures(db_session, teacher_user):
    president_user = make_user("reports-empty-president@test.com", UserRoleEnum.PRESIDENT, "Empty")
    db_session.add(president_user)
    await db_session.flush()
    president = President(user_id=president_user.id, school_name="Empty Reports School")
    db_session.add(president)
    await db_session.flush()
    db_session.add(Teacher(user_id=teacher_user.id, president_id=president.id, riwaya="Hafs"))
    await db_session.flush()

    summary = await get_teacher_statistics_summary(db_session, teacher_user)
    attendance = await get_teacher_attendance_trend(db=db_session, current_user=teacher_user)
    memorizers = await get_teacher_top_memorizers(db=db_session, current_user=teacher_user)
    distribution = await get_teacher_lecture_distribution(db_session, teacher_user)

    assert summary == {
        "total_students": 0,
        "total_teachers": 0,
        "total_supervisors": 0,
        "present_today": 0,
        "total_pages_memorized": 0,
        "total_lectures": 0,
    }
    assert attendance == []
    assert memorizers == []
    assert distribution == []


@pytest.mark.asyncio
async def test_teacher_statistics_are_scoped_to_assigned_school_lectures(db_session, teacher_user):
    president_user_a = make_user("reports-president-a@test.com", UserRoleEnum.PRESIDENT, "SchoolA")
    president_user_b = make_user("reports-president-b@test.com", UserRoleEnum.PRESIDENT, "SchoolB")
    teacher_user_b = make_user("reports-teacher-b@test.com", UserRoleEnum.TEACHER, "TeacherB")
    student_user_a = make_user("reports-student-a@test.com", UserRoleEnum.STUDENT, "StudentA")
    student_user_b = make_user("reports-student-b@test.com", UserRoleEnum.STUDENT, "StudentB")
    db_session.add_all([president_user_a, president_user_b, teacher_user_b, student_user_a, student_user_b])
    await db_session.flush()

    president_a = President(user_id=president_user_a.id, school_name="School A")
    president_b = President(user_id=president_user_b.id, school_name="School B")
    db_session.add_all([president_a, president_b])
    await db_session.flush()

    teacher_a = Teacher(user_id=teacher_user.id, president_id=president_a.id, riwaya="Hafs")
    teacher_b = Teacher(user_id=teacher_user_b.id, president_id=president_b.id, riwaya="Warsh")
    student_a = Student(user_id=student_user_a.id, president_id=president_a.id)
    student_b = Student(user_id=student_user_b.id, president_id=president_b.id)
    lecture_a = Lecture(
        president_id=president_a.id,
        lecture_name_ar="حلقة أ",
        lecture_name_en="Circle A",
        circle_type="memorization",
        category="both",
    )
    lecture_b = Lecture(
        president_id=president_b.id,
        lecture_name_ar="حلقة ب",
        lecture_name_en="Circle B",
        circle_type="memorization",
        category="both",
    )
    teacher_a.lectures.append(lecture_a)
    teacher_b.lectures.append(lecture_b)
    db_session.add_all([teacher_a, teacher_b, student_a, student_b])
    await db_session.flush()

    db_session.add_all([
        SessionParticipation(student_id=student_a.id, lecture_id=lecture_a.id),
        SessionParticipation(student_id=student_b.id, lecture_id=lecture_b.id),
        Attendance(
            student_id=student_a.id,
            president_id=president_a.id,
            lecture_id=lecture_a.id,
            date=date.today(),
            status=AttendanceStatus.PRESENT,
        ),
        Attendance(
            student_id=student_b.id,
            president_id=president_b.id,
            lecture_id=lecture_b.id,
            date=date.today(),
            status=AttendanceStatus.ABSENT,
        ),
        Achievement(
            student_id=student_a.id,
            president_id=president_a.id,
            from_surah=1,
            from_verse=1,
            to_surah=1,
            to_verse=16,
            achievement_type=AchievementType.NORMAL,
        ),
        Achievement(
            student_id=student_b.id,
            president_id=president_b.id,
            from_surah=1,
            from_verse=1,
            to_surah=1,
            to_verse=16,
            achievement_type=AchievementType.NORMAL,
        ),
    ])
    await db_session.flush()

    summary = await get_teacher_statistics_summary(db_session, teacher_user)
    attendance = await get_teacher_attendance_trend(db=db_session, current_user=teacher_user)
    memorizers = await get_teacher_top_memorizers(db=db_session, current_user=teacher_user)
    distribution = await get_teacher_lecture_distribution(db_session, teacher_user)

    assert summary["total_students"] == 1
    assert summary["total_lectures"] == 1
    assert summary["present_today"] == 1
    assert summary["total_pages_memorized"] == 1
    assert attendance == [{
        "date": date.today(),
        "present": 1,
        "absent": 0,
        "total": 1,
        "percentage": "100.0%",
    }]
    assert memorizers == [{"student": "StudentA Statistics", "pages": 1, "rank": 1}]
    assert distribution == [{"className": "حلقة أ", "students": 1, "percentage": "100.0%"}]
