"""Exam helpers: ranking, per-exam statistics and speciality-weighted averages.

The pure functions take plain values so they can be unit tested without a database.
"""
from dataclasses import dataclass
from typing import Iterable, Optional

ATTENDANCE_VALUES = ("present", "absent", "excused")


@dataclass(frozen=True)
class MarkRow:
    student_id: int
    attendance: str
    mark: Optional[float]


def competition_ranks(rows: Iterable[MarkRow]) -> dict[int, int]:
    """Standard competition ranking (1, 1, 3) over present students that have a mark."""
    graded = sorted(
        (row for row in rows if row.attendance == "present" and row.mark is not None),
        key=lambda row: (-row.mark, row.student_id),
    )
    ranks: dict[int, int] = {}
    previous: Optional[float] = None
    rank = 0
    for position, row in enumerate(graded, start=1):
        if row.mark != previous:
            rank = position
            previous = row.mark
        ranks[row.student_id] = rank
    return ranks


def exam_stats(rows: Iterable[MarkRow], max_mark: float, pass_mark: float) -> dict:
    rows = list(rows)
    marks = [row.mark for row in rows if row.attendance == "present" and row.mark is not None]
    present = sum(1 for row in rows if row.attendance == "present")
    average = round(sum(marks) / len(marks), 2) if marks else None
    return {
        "total": len(rows),
        "present": present,
        "absent": sum(1 for row in rows if row.attendance == "absent"),
        "excused": sum(1 for row in rows if row.attendance == "excused"),
        "graded": len(marks),
        "pending": sum(1 for row in rows if row.attendance == "present" and row.mark is None),
        "average": average,
        "average_pct": round(average / max_mark * 100, 1) if average is not None and max_mark else None,
        "highest": max(marks) if marks else None,
        "lowest": min(marks) if marks else None,
        "passed": sum(1 for mark in marks if mark >= pass_mark),
        "pass_rate": round(sum(1 for mark in marks if mark >= pass_mark) / len(marks) * 100, 1) if marks else None,
        "attendance_rate": round(present / len(rows) * 100, 1) if rows else None,
    }


def weighted_average(percent_by_lecture: dict[int, float], coefficients: dict[int, float]) -> Optional[float]:
    """Coefficient-weighted mean of the circles that have marks (0-100 scale); None if none has."""
    used = [(coefficients[lecture_id], pct) for lecture_id, pct in percent_by_lecture.items() if lecture_id in coefficients]
    total = sum(coef for coef, _ in used)
    if not used or total <= 0:
        return None
    return round(sum(coef * pct for coef, pct in used) / total, 2)


def rank_values(values: dict[int, float]) -> dict[int, int]:
    """Competition ranking of arbitrary keyed values, highest first."""
    return competition_ranks(MarkRow(student_id=key, attendance="present", mark=value) for key, value in values.items())
