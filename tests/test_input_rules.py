from datetime import timedelta

import pytest
from pydantic import ValidationError

from app.core.clock import today_algeria
from app.schemas.achievement import AchievementCreate, AchievementUpdate
from app.schemas.attendance import AttendanceBulkSave, AttendanceCreate
from app.schemas.dates import checked_text_date
from app.schemas.teacher_attendance import TeacherAttendanceCreate

RANGE = {"from_surah": 1, "from_verse": 1, "to_surah": 1, "to_verse": 7}
FUTURE = today_algeria() + timedelta(days=30)


@pytest.mark.parametrize("value", ["hello", "31-02-2026", "2026-13-45"])
def test_impossible_text_dates_are_refused(value):
    with pytest.raises(ValueError):
        checked_text_date(value)


@pytest.mark.parametrize("value", ["05-11-2026", "2026-11-05"])
def test_real_text_dates_are_kept_as_written(value):
    assert checked_text_date(value) == value


def test_blank_text_date_means_no_date():
    assert checked_text_date("  ") is None


def test_achievement_in_the_future_is_refused():
    with pytest.raises(ValidationError):
        AchievementCreate(**RANGE, date=FUTURE.strftime("%d-%m-%Y"))


def test_new_achievement_must_use_a_verse_that_exists_in_warsh():
    with pytest.raises(ValidationError):
        AchievementCreate(from_surah=2, from_verse=1, to_surah=2, to_verse=286)
    assert AchievementCreate(from_surah=2, from_verse=1, to_surah=2, to_verse=285).to_verse == 285


def test_editing_an_older_record_may_keep_its_hafs_verse_number():
    assert AchievementUpdate(from_surah=2, from_verse=1, to_surah=2, to_verse=286, note="x").to_verse == 286


def test_attendance_in_the_future_is_refused():
    with pytest.raises(ValidationError):
        AttendanceCreate(date=FUTURE, lecture_id=1)
    with pytest.raises(ValidationError):
        AttendanceBulkSave(date=FUTURE, records=[])


def test_teacher_attendance_needs_a_real_date():
    with pytest.raises(ValidationError):
        TeacherAttendanceCreate(teacher_id=1, date="not-a-date", status="present")
