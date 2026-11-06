from datetime import date, datetime

from app.services.analytics import (
    AchievementRow,
    AttendanceRow,
    bucket_starts,
    build_series,
    coarsen,
    default_granularity,
    entity_rows,
    health,
    parse_achievement_day,
    rate,
    student_alerts,
    summarize,
)


def att(student, day, status, school=1, lecture=10):
    return AttendanceRow(student, school, lecture, day, status)


def ach(student, day, pages, kind="normal", school=1):
    return AchievementRow(student, school, day, kind, pages)


def test_rate_counts_present_and_late_as_attended():
    summary = summarize(
        [att(1, date(2026, 10, 1), "present"), att(1, date(2026, 10, 2), "late"),
         att(1, date(2026, 10, 3), "absent"), att(1, date(2026, 10, 4), "excused")],
        [],
    )
    assert summary["attendance_rate"] == 50.0
    assert summary["status_breakdown"] == {"present": 1, "late": 1, "excused": 1, "absent": 1}


def test_rate_is_none_without_records():
    assert rate(0, 0) is None
    assert summarize([], [])["attendance_rate"] is None


def test_health_thresholds_and_small_samples():
    assert health(90.0, 10) == "good"
    assert health(85.0, 10) == "good"
    assert health(75.0, 10) == "warning"
    assert health(60.0, 10) == "critical"
    assert health(100.0, 2) == "insufficient"
    assert health(None, 0) == "insufficient"


def test_pages_are_summed_per_type():
    summary = summarize([], [ach(1, date(2026, 10, 1), 2.0), ach(1, date(2026, 10, 2), 1.0, "big")])
    assert summary["pages"] == 3.0
    assert summary["pages_by_type"] == {"normal": 2.0, "small": 0.0, "big": 1.0}
    assert summary["achievements"] == 2


def test_achievement_dates_parse_from_text_or_fall_back_to_creation():
    assert parse_achievement_day("05-10-2026", None) == date(2026, 10, 5)
    assert parse_achievement_day("2026-10-05", None) == date(2026, 10, 5)
    assert parse_achievement_day("garbage", datetime(2026, 1, 2, 9)) == date(2026, 1, 2)
    assert parse_achievement_day(None, None) is None


def test_granularity_defaults_and_coarsening():
    assert default_granularity(date(2026, 10, 1), date(2026, 10, 31)) == "day"
    assert default_granularity(date(2026, 1, 1), date(2026, 5, 1)) == "week"
    assert default_granularity(date(2025, 1, 1), date(2026, 1, 1)) == "month"
    # Three years by day is over the point cap, so it steps up to weeks.
    assert coarsen(date(2024, 1, 1), date(2026, 12, 31), "day") == "week"


def test_weekly_and_monthly_buckets():
    assert bucket_starts(date(2026, 11, 4), date(2026, 11, 18), "week") == [
        date(2026, 11, 2), date(2026, 11, 9), date(2026, 11, 16)]
    assert bucket_starts(date(2026, 11, 20), date(2027, 1, 3), "month") == [
        date(2026, 11, 1), date(2026, 12, 1), date(2027, 1, 1)]


def test_series_includes_empty_buckets():
    series = build_series([att(1, date(2026, 10, 2), "present")], [], date(2026, 10, 1), date(2026, 10, 3), "day")
    assert [point["bucket"] for point in series] == ["2026-10-01", "2026-10-02", "2026-10-03"]
    assert [point["attendance_rate"] for point in series] == [None, 100.0, None]


def test_entity_rows_count_members_activity_and_health():
    rows = entity_rows(
        {1: {"name": "A"}, 2: {"name": "B"}},
        [att(1, date(2026, 10, d), "present", school=1) for d in range(1, 5)] + [att(3, date(2026, 10, 1), "absent", school=2)],
        [ach(2, date(2026, 10, 6), 1.5, school=1)],
        lambda r: [r.school_id], lambda r: [r.school_id],
        {1: {1, 2, 9}, 2: {3}},
    )
    by_id = {row["id"]: row for row in rows}
    assert by_id[1]["students"] == 3 and by_id[1]["active_students"] == 2
    assert by_id[1]["health"] == "good" and by_id[1]["last_activity"] == "2026-10-06"
    assert by_id[2]["health"] == "insufficient" and by_id[2]["attendance_rate"] == 0.0


def test_alerts_flag_low_attendance_first_then_inactive():
    students = {1: {"name": "Low"}, 2: {"name": "Idle"}, 3: {"name": "Fine"}}
    attendance = [att(1, date(2026, 10, d), "absent") for d in range(1, 4)] + [att(3, date(2026, 10, 1), "present")]
    alerts = student_alerts(students, attendance, [])
    assert [(a["id"], a["reason"]) for a in alerts] == [(1, "low_attendance"), (2, "no_activity")]
