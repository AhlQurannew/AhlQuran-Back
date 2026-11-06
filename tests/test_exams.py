from app.services.exams import MarkRow, competition_ranks, exam_stats, rank_values, weighted_average


def test_competition_ranks_share_ties_and_skip_absent():
    rows = [
        MarkRow(1, "present", 18.0),
        MarkRow(2, "present", 15.5),
        MarkRow(3, "present", 18.0),
        MarkRow(4, "absent", None),
        MarkRow(5, "present", None),
        MarkRow(6, "present", 12.0),
        MarkRow(7, "excused", 19.0),
    ]
    assert competition_ranks(rows) == {1: 1, 3: 1, 2: 3, 6: 4}


def test_exam_stats():
    rows = [
        MarkRow(1, "present", 16.0),
        MarkRow(2, "present", 8.0),
        MarkRow(3, "absent", None),
        MarkRow(4, "present", None),
    ]
    stats = exam_stats(rows, max_mark=20, pass_mark=10)
    assert stats["total"] == 4
    assert stats["present"] == 3
    assert stats["absent"] == 1
    assert stats["graded"] == 2
    assert stats["pending"] == 1
    assert stats["average"] == 12.0
    assert stats["average_pct"] == 60.0
    assert stats["passed"] == 1
    assert stats["pass_rate"] == 50.0
    assert stats["attendance_rate"] == 75.0


def test_exam_stats_empty():
    stats = exam_stats([], max_mark=20, pass_mark=10)
    assert stats["average"] is None and stats["pass_rate"] is None and stats["attendance_rate"] is None


def test_weighted_average_uses_only_graded_circles():
    coefficients = {10: 3.0, 11: 1.0, 12: 2.0}
    # circle 12 has no mark yet: it is left out of the weights
    assert weighted_average({10: 80.0, 11: 40.0}, coefficients) == 70.0
    assert weighted_average({}, coefficients) is None
    # circles outside the speciality are ignored
    assert weighted_average({99: 100.0}, coefficients) is None


def test_rank_values():
    assert rank_values({1: 70.0, 2: 90.0, 3: 70.0}) == {2: 1, 1: 2, 3: 2}
