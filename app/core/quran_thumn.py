"""Thumn (eighth of a Hizb) division of the Quran, Warsh reading: 60 Hizb, 480 Thumn, 6,214 verses.

The boundaries and verse counts come from nuralhifz-data (Moroccan Muhammadi Mushaf),
https://github.com/smartmaker-devs/nuralhifz-data, (c) 2026 Noureddine El-Ahmadi, CC BY 4.0.
They were converted to this table without changing them.

Verse numbers are Warsh numbers. A verse number past the end of a surah counts as its last verse,
which keeps records entered before the app switched from Hafs numbering usable.
"""

from bisect import bisect_right
from itertools import accumulate
from typing import Optional

THUMN_PER_HIZB = 8
TOTAL_THUMN = 480

# Index 0 is Al-Fatiha.
WARSH_VERSE_COUNTS = (
    7, 285, 200, 175, 122, 167, 206, 76, 130, 109, 121, 111, 44, 54, 99, 128,
    110, 105, 99, 134, 111, 76, 119, 62, 77, 226, 95, 88, 69, 59, 33, 30,
    73, 54, 46, 82, 182, 86, 72, 84, 53, 50, 89, 56, 36, 34, 39, 29,
    18, 45, 60, 47, 61, 55, 77, 99, 28, 21, 24, 13, 14, 11, 11, 18,
    12, 12, 31, 52, 52, 44, 30, 28, 18, 55, 39, 31, 50, 40, 45, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 32, 20, 15, 21, 11, 8, 8, 20,
    5, 8, 9, 11, 10, 8, 3, 9, 5, 5, 6, 3, 6, 3, 5, 4,
    5, 6,
)

# (surah, verse) where each Thumn starts, in Mushaf order.
THUMN_STARTS = (
    (1, 1), (2, 16), (2, 25), (2, 33), (2, 41), (2, 53), (2, 59), (2, 66),
    (2, 75), (2, 84), (2, 91), (2, 100), (2, 105), (2, 113), (2, 123), (2, 132),
    (2, 141), (2, 147), (2, 157), (2, 165), (2, 176), (2, 184), (2, 188), (2, 195),
    (2, 201), (2, 211), (2, 217), (2, 225), (2, 231), (2, 233), (2, 241), (2, 246),
    (2, 251), (2, 257), (2, 262), (2, 266), (2, 271), (2, 279), (2, 282), (3, 5),
    (3, 15), (3, 23), (3, 33), (3, 42), (3, 51), (3, 63), (3, 74), (3, 80),
    (3, 91), (3, 103), (3, 113), (3, 121), (3, 133), (3, 144), (3, 153), (3, 160),
    (3, 171), (3, 181), (3, 186), (3, 196), (4, 6), (4, 11), (4, 13), (4, 19),
    (4, 24), (4, 29), (4, 36), (4, 45), (4, 57), (4, 64), (4, 73), (4, 78),
    (4, 86), (4, 91), (4, 99), (4, 104), (4, 113), (4, 123), (4, 129), (4, 139),
    (4, 147), (4, 156), (4, 165), (4, 173), (5, 4), (5, 7), (5, 13), (5, 19),
    (5, 25), (5, 34), (5, 43), (5, 47), (5, 51), (5, 60), (5, 69), (5, 75),
    (5, 84), (5, 92), (5, 99), (5, 108), (5, 113), (6, 1), (6, 14), (6, 27),
    (6, 37), (6, 49), (6, 60), (6, 70), (6, 81), (6, 92), (6, 96), (6, 104),
    (6, 112), (6, 121), (6, 128), (6, 136), (6, 141), (6, 146), (6, 152), (6, 159),
    (7, 4), (7, 20), (7, 30), (7, 38), (7, 46), (7, 56), (7, 68), (7, 76),
    (7, 87), (7, 99), (7, 116), (7, 131), (7, 142), (7, 149), (7, 156), (7, 163),
    (7, 171), (7, 179), (7, 188), (7, 199), (8, 5), (8, 15), (8, 22), (8, 31),
    (8, 41), (8, 49), (8, 61), (8, 72), (9, 5), (9, 12), (9, 19), (9, 28),
    (9, 34), (9, 40), (9, 46), (9, 55), (9, 61), (9, 70), (9, 76), (9, 86),
    (9, 94), (9, 102), (9, 112), (9, 118), (9, 124), (10, 3), (10, 11), (10, 19),
    (10, 26), (10, 37), (10, 49), (10, 61), (10, 71), (10, 83), (10, 93), (10, 104),
    (11, 6), (11, 15), (11, 24), (11, 32), (11, 41), (11, 53), (11, 61), (11, 72),
    (11, 83), (11, 93), (11, 105), (11, 117), (12, 10), (12, 23), (12, 33), (12, 42),
    (12, 53), (12, 66), (12, 77), (12, 88), (12, 101), (12, 111), (13, 5), (13, 15),
    (13, 21), (13, 31), (13, 36), (14, 1), (14, 13), (14, 22), (14, 30), (14, 41),
    (15, 1), (15, 22), (15, 49), (15, 78), (16, 1), (16, 15), (16, 30), (16, 38),
    (16, 51), (16, 63), (16, 71), (16, 79), (16, 90), (16, 98), (16, 111), (16, 120),
    (17, 1), (17, 11), (17, 23), (17, 36), (17, 50), (17, 61), (17, 70), (17, 85),
    (17, 99), (18, 1), (18, 17), (18, 23), (18, 30), (18, 41), (18, 49), (18, 58),
    (18, 74), (18, 85), (18, 98), (19, 6), (19, 21), (19, 40), (19, 59), (19, 75),
    (20, 1), (20, 35), (20, 54), (20, 71), (20, 81), (20, 95), (20, 108), (20, 124),
    (21, 1), (21, 15), (21, 30), (21, 42), (21, 51), (21, 72), (21, 86), (21, 100),
    (22, 1), (22, 11), (22, 19), (22, 28), (22, 36), (22, 47), (22, 58), (22, 70),
    (23, 1), (23, 24), (23, 39), (23, 58), (23, 76), (23, 94), (23, 116), (24, 11),
    (24, 21), (24, 30), (24, 35), (24, 42), (24, 51), (24, 58), (24, 61), (25, 10),
    (25, 21), (25, 35), (25, 45), (25, 61), (26, 1), (26, 24), (26, 50), (26, 82),
    (26, 111), (26, 146), (26, 181), (26, 210), (27, 6), (27, 17), (27, 27), (27, 42),
    (27, 58), (27, 68), (27, 84), (28, 1), (28, 11), (28, 21), (28, 29), (28, 39),
    (28, 51), (28, 63), (28, 76), (28, 83), (29, 7), (29, 16), (29, 25), (29, 36),
    (29, 46), (29, 60), (30, 8), (30, 21), (30, 29), (30, 40), (30, 53), (31, 10),
    (31, 21), (31, 32), (32, 11), (32, 21), (33, 1), (33, 9), (33, 18), (33, 25),
    (33, 31), (33, 37), (33, 49), (33, 53), (33, 60), (34, 1), (34, 10), (34, 18),
    (34, 24), (34, 37), (34, 46), (35, 8), (35, 15), (35, 31), (35, 41), (36, 6),
    (36, 27), (36, 45), (36, 59), (36, 79), (37, 22), (37, 51), (37, 83), (37, 114),
    (37, 145), (38, 1), (38, 20), (38, 30), (38, 51), (38, 83), (39, 9), (39, 20),
    (39, 31), (39, 40), (39, 51), (39, 64), (40, 1), (40, 10), (40, 21), (40, 30),
    (40, 41), (40, 53), (40, 66), (40, 78), (41, 8), (41, 16), (41, 24), (41, 37),
    (41, 46), (42, 3), (42, 11), (42, 18), (42, 25), (42, 39), (42, 48), (43, 10),
    (43, 23), (43, 42), (43, 63), (43, 85), (44, 24), (45, 1), (45, 13), (45, 24),
    (46, 1), (46, 14), (46, 20), (46, 32), (47, 11), (47, 21), (47, 34), (48, 8),
    (48, 18), (48, 26), (49, 1), (49, 9), (49, 14), (50, 9), (50, 27), (51, 1),
    (51, 31), (51, 56), (52, 22), (52, 42), (53, 26), (53, 46), (54, 10), (54, 37),
    (55, 1), (55, 40), (56, 1), (56, 52), (56, 78), (57, 7), (57, 15), (57, 21),
    (58, 1), (58, 8), (58, 14), (59, 2), (59, 11), (60, 1), (60, 7), (61, 1),
    (62, 1), (63, 1), (63, 9), (64, 7), (65, 1), (65, 6), (66, 1), (66, 8),
    (67, 1), (67, 20), (68, 19), (68, 48), (69, 18), (70, 1), (70, 40), (71, 15),
    (72, 1), (72, 23), (73, 18), (74, 31), (75, 1), (76, 1), (76, 19), (77, 16),
    (78, 1), (79, 1), (79, 41), (81, 1), (82, 1), (83, 14), (84, 16), (85, 12),
    (87, 1), (88, 17), (90, 1), (92, 1), (94, 1), (98, 1), (100, 9), (106, 1),
)

# Thumn (1-based) that start inside a verse; that verse is shared half and half with the previous Thumn.
THUMN_STARTING_MID_VERSE = frozenset({10, 24, 30, 48, 64, 74, 82, 90, 338, 436, 446, 458})

_SURAH_OFFSETS = (0, *accumulate(WARSH_VERSE_COUNTS))


def _verse_index(surah: int, verse: int) -> int:
    """1-based position of the verse in the whole Mushaf, clamped to the surah."""
    return _SURAH_OFFSETS[surah - 1] + min(max(verse, 1), WARSH_VERSE_COUNTS[surah - 1])


# Thumn edges measured in verses from the start of the Mushaf; verse n occupies [n - 1, n].
_EDGES = tuple(
    _verse_index(surah, verse) - (0.5 if number in THUMN_STARTING_MID_VERSE else 1)
    for number, (surah, verse) in enumerate(THUMN_STARTS, start=1)
) + (float(_SURAH_OFFSETS[-1]),)
_SHARED_VERSES = frozenset(_verse_index(*THUMN_STARTS[number - 1]) for number in THUMN_STARTING_MID_VERSE)


def _thumn_position(edge: float) -> float:
    """How many Thumn lie before this point of the Mushaf, with a fraction for a partial Thumn."""
    index = min(bisect_right(_EDGES, edge) - 1, TOTAL_THUMN - 1)
    return index + (edge - _EDGES[index]) / (_EDGES[index + 1] - _EDGES[index])


def calculate_achievement_thumn(
    from_surah: Optional[int],
    from_verse: Optional[int],
    to_surah: Optional[int],
    to_verse: Optional[int],
) -> float:
    """Thumn covered by an inclusive surah/verse range; a Thumn partly covered counts by its share of verses.

    The range may be written in either direction, since memorisation often runs from the end of the Mushaf.
    A range without a valid surah counts as 0.
    """
    if from_surah is None or to_surah is None or not (1 <= from_surah <= 114 and 1 <= to_surah <= 114):
        return 0.0
    start = _verse_index(from_surah, from_verse or 1)
    end = _verse_index(to_surah, to_verse or WARSH_VERSE_COUNTS[to_surah - 1])
    if end < start:
        start, end = end, start
    # A range that begins or stops on a shared verse begins or stops at the Thumn mark inside it.
    split = start != end
    start_edge = start - (0.5 if split and start in _SHARED_VERSES else 1.0)
    end_edge = end - (0.5 if split and end in _SHARED_VERSES else 0.0)
    return round(_thumn_position(end_edge) - _thumn_position(start_edge), 4)


def rank_students_by_thumn(rows, limit: int) -> list[dict]:
    """Rows of (student_id, firstname, lastname, from_surah, from_verse, to_surah, to_verse) -> best students first."""
    students: dict[int, dict] = {}
    for student_id, firstname, lastname, *verse_range in rows:
        entry = students.setdefault(student_id, {"student": f"{firstname} {lastname}".strip(), "thumn": 0.0})
        entry["thumn"] += calculate_achievement_thumn(*verse_range)
    ranked = sorted(students.values(), key=lambda s: (-s["thumn"], s["student"]))[:limit]
    return [{"student": s["student"], "thumn": round(s["thumn"], 2), "rank": i} for i, s in enumerate(ranked, start=1)]
