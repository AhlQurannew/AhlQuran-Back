from datetime import date

import pytest

from app.api.v1.routes.president import (
    get_achievement_breakdown,
    get_attendance_breakdown,
    get_halqa_breakdown,
    get_progress_timeline,
)
from app.api.v1.routes.teacher import (
    get_teacher_achievement_breakdown,
    get_teacher_attendance_breakdown,
    get_teacher_halqa_breakdown,
    get_teacher_progress_timeline,
)
from app.models.acheivements import Achievement, AchievementType
from app.models.attendance import Attendance, AttendanceStatus
from app.models.lecture import Lecture
from app.models.president import President
from app.models.sessionParticipation import SessionParticipation
from app.models.student import Student
from app.models.supervisor import Supervisor
from app.models.teacher import Teacher
from app.models.user import User, UserRoleEnum


def make_user(email: str, role: UserRoleEnum, firstname: str) -> User:
    return User(
        firstname=firstname,
        lastname="Reports",
        email=email,
        hashed_password="test-hash",
        role=role,
        is_active=True,
    )


def make_lecture(president_id: int, name: str) -> Lecture:
    return Lecture(
        president_id=president_id,
        lecture_name_ar=name,
        lecture_name_en=name,
        circle_type="memorization",
        category="both",
    )


@pytest.mark.asyncio
async def test_supervisor_achievement_breakdown_is_school_scoped_and_filters_dates_and_lecture(db_session):
    president_user = make_user("achievement-school-owner@test.com", UserRoleEnum.PRESIDENT, "School")
    supervisor_user = make_user("achievement-supervisor@test.com", UserRoleEnum.SUPERVISOR, "Supervisor")
    student_user = make_user("achievement-student@test.com", UserRoleEnum.STUDENT, "Student")
    same_school_other_student_user = make_user(
        "achievement-same-school-other-student@test.com", UserRoleEnum.STUDENT, "OtherStudent"
    )
    other_school_owner = make_user("achievement-other-owner@test.com", UserRoleEnum.PRESIDENT, "Other")
    other_school_student_user = make_user("achievement-other-student@test.com", UserRoleEnum.STUDENT, "OtherStudent")
    db_session.add_all([
        president_user,
        supervisor_user,
        student_user,
        same_school_other_student_user,
        other_school_owner,
        other_school_student_user,
    ])
    await db_session.flush()

    president = President(user_id=president_user.id, school_name="Reports School")
    other_president = President(user_id=other_school_owner.id, school_name="Other School")
    db_session.add_all([president, other_president])
    await db_session.flush()

    supervisor = Supervisor(user_id=supervisor_user.id, president_id=president.id)
    student = Student(user_id=student_user.id, president_id=president.id)
    same_school_other_student = Student(
        user_id=same_school_other_student_user.id, president_id=president.id
    )
    other_school_student = Student(user_id=other_school_student_user.id, president_id=other_president.id)
    lecture = make_lecture(president.id, "Assigned lecture")
    other_lecture = make_lecture(president.id, "Other lecture")
    other_school_lecture = make_lecture(other_president.id, "Other school lecture")
    db_session.add_all([
        supervisor,
        student,
        same_school_other_student,
        other_school_student,
        lecture,
        other_lecture,
        other_school_lecture,
    ])
    await db_session.flush()

    db_session.add_all([
        SessionParticipation(student_id=student.id, lecture_id=lecture.id),
        SessionParticipation(student_id=same_school_other_student.id, lecture_id=other_lecture.id),
        SessionParticipation(student_id=other_school_student.id, lecture_id=other_school_lecture.id),
        Attendance(
            student_id=student.id,
            president_id=president.id,
            lecture_id=lecture.id,
            date=date(2026, 3, 15),
            status=AttendanceStatus.PRESENT,
        ),
        Attendance(
            student_id=same_school_other_student.id,
            president_id=president.id,
            lecture_id=other_lecture.id,
            date=date(2026, 3, 15),
            status=AttendanceStatus.ABSENT,
        ),
        Attendance(
            student_id=other_school_student.id,
            president_id=other_president.id,
            lecture_id=other_school_lecture.id,
            date=date(2026, 3, 15),
            status=AttendanceStatus.ABSENT,
        ),
        Achievement(
            student_id=student.id,
            president_id=president.id,
            from_surah=1,
            from_verse=1,
            to_surah=1,
            to_verse=5,
            achievement_type=AchievementType.NORMAL,
            date="15-03-2026",
        ),
        Achievement(
            student_id=student.id,
            president_id=president.id,
            from_surah=1,
            from_verse=6,
            to_surah=1,
            to_verse=10,
            achievement_type=AchievementType.SMALL,
            date="10-04-2026",
        ),
        Achievement(
            student_id=student.id,
            president_id=president.id,
            from_surah=1,
            from_verse=11,
            to_surah=1,
            to_verse=15,
            achievement_type=AchievementType.BIG,
            date="15-12-2025",
        ),
        Achievement(
            student_id=same_school_other_student.id,
            president_id=president.id,
            from_surah=1,
            from_verse=1,
            to_surah=1,
            to_verse=5,
            achievement_type=AchievementType.BIG,
            date="15-03-2026",
        ),
        Achievement(
            student_id=other_school_student.id,
            president_id=other_president.id,
            from_surah=1,
            from_verse=1,
            to_surah=1,
            to_verse=5,
            achievement_type=AchievementType.BIG,
            date="15-03-2026",
        ),
    ])
    await db_session.flush()

    result = await get_achievement_breakdown(
        lecture_id=lecture.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=supervisor_user,
    )
    selected_student_result = await get_achievement_breakdown(
        student_id=student.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=supervisor_user,
    )
    attendance = await get_attendance_breakdown(
        lecture_id=lecture.id,
        student_id=student.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=supervisor_user,
    )
    halqa = await get_halqa_breakdown(
        lecture_id=lecture.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=supervisor_user,
    )
    timeline = await get_progress_timeline(
        student_id=student.id,
        lecture_id=lecture.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=supervisor_user,
    )
    no_matches = await get_achievement_breakdown(
        student_id=student.id,
        start_date=date(2024, 1, 1),
        end_date=date(2024, 12, 31),
        db=db_session,
        current_user=supervisor_user,
    )

    assert result == {"normal": 1, "small": 1, "big": 0}
    assert selected_student_result == {"normal": 1, "small": 1, "big": 0}
    assert attendance == {"present": 1, "late": 0, "absent": 0, "excused": 0, "total": 1}
    assert halqa == [{"student": "Student Reports", "pages": 2.0}]
    assert timeline == [
        {"date": "2026-03-15", "memorization": 1.0, "minorRev": 0.0, "majorRev": 0.0},
        {"date": "2026-04-10", "memorization": 1.0, "minorRev": 1.0, "majorRev": 0.0},
    ]
    assert no_matches == {"normal": 0, "small": 0, "big": 0}


@pytest.mark.asyncio
async def test_teacher_achievement_breakdown_limits_results_to_assigned_lectures(db_session, teacher_user):
    president_user = make_user("teacher-achievement-owner@test.com", UserRoleEnum.PRESIDENT, "School")
    student_user = make_user("teacher-achievement-student@test.com", UserRoleEnum.STUDENT, "Student")
    db_session.add_all([president_user, student_user])
    await db_session.flush()

    president = President(user_id=president_user.id, school_name="Teacher Reports School")
    db_session.add(president)
    await db_session.flush()

    teacher = Teacher(user_id=teacher_user.id, president_id=president.id, riwaya="Hafs")
    student = Student(user_id=student_user.id, president_id=president.id)
    lecture = make_lecture(president.id, "Teacher lecture")
    teacher.lectures.append(lecture)
    db_session.add_all([teacher, student])
    await db_session.flush()

    db_session.add_all([
        SessionParticipation(student_id=student.id, lecture_id=lecture.id),
        Attendance(
            student_id=student.id,
            president_id=president.id,
            lecture_id=lecture.id,
            date=date(2026, 3, 15),
            status=AttendanceStatus.LATE,
        ),
        Achievement(
            student_id=student.id,
            president_id=president.id,
            from_surah=1,
            from_verse=1,
            to_surah=1,
            to_verse=5,
            achievement_type=AchievementType.NORMAL,
            date="15-03-2026",
        ),
    ])
    await db_session.flush()

    result = await get_teacher_achievement_breakdown(
        lecture_id=lecture.id,
        student_id=student.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=teacher_user,
    )

    assert result == {"normal": 1, "small": 0, "big": 0}

    attendance = await get_teacher_attendance_breakdown(
        lecture_id=lecture.id,
        student_id=student.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=teacher_user,
    )
    halqa = await get_teacher_halqa_breakdown(
        lecture_id=lecture.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=teacher_user,
    )
    timeline = await get_teacher_progress_timeline(
        student_id=student.id,
        lecture_id=lecture.id,
        start_date=date(2026, 1, 1),
        end_date=date(2026, 10, 26),
        db=db_session,
        current_user=teacher_user,
    )

    assert attendance == {"present": 0, "late": 1, "absent": 0, "excused": 0, "total": 1}
    assert halqa == [{"student": "Student Reports", "pages": 1.0}]
    assert timeline == [
        {"date": "2026-03-15", "memorization": 1.0, "minorRev": 0.0, "majorRev": 0.0}
    ]
