import pytest

from app.core.quran_thumn import (
    THUMN_STARTING_MID_VERSE,
    THUMN_STARTS,
    TOTAL_THUMN,
    WARSH_VERSE_COUNTS,
    calculate_achievement_thumn as thumn,
    rank_students_by_thumn,
)


def test_table_shape():
    assert len(THUMN_STARTS) == TOTAL_THUMN == 480
    assert list(THUMN_STARTS) == sorted(THUMN_STARTS)
    assert sum(WARSH_VERSE_COUNTS) == 6214
    assert len(WARSH_VERSE_COUNTS) == 114


def test_whole_quran_is_60_hizb():
    assert thumn(1, 1, 114, 6) == 480


def thumn_end(number):
    """Last verse of a Thumn: the shared verse if the next one starts inside it, else the verse before the next."""
    surah, verse = THUMN_STARTS[number]
    if number + 1 in THUMN_STARTING_MID_VERSE:
        return surah, verse
    return (surah, verse - 1) if verse > 1 else (surah - 1, WARSH_VERSE_COUNTS[surah - 2])


def test_every_single_thumn_counts_exactly_one():
    for number in range(1, 480):
        assert thumn(*THUMN_STARTS[number - 1], *thumn_end(number)) == pytest.approx(1, abs=0.001), number


def test_first_thumn_runs_from_fatiha_to_baqara_15():
    assert thumn(1, 1, 2, 15) == 1
    assert thumn(1, 1, 2, 16) == pytest.approx(1 + 1 / 9, abs=0.001)  # the next Thumn is 2:16-2:24


def test_partial_thumn_is_a_fraction_of_its_verses():
    assert thumn(2, 16, 2, 16) == pytest.approx(1 / 9, abs=0.001)


def test_range_can_run_backwards():
    assert thumn(114, 6, 106, 1) == thumn(106, 1, 114, 6) == 1


def test_shared_verse_is_split_between_its_two_thumn():
    surah, verse = THUMN_STARTS[9]  # Thumn 10 starts inside 2:84
    assert (surah, verse) == (2, 84)
    assert thumn(2, 84, 2, 84) > 0


def test_old_hafs_verse_number_past_the_end_counts_as_last_verse():
    assert thumn(2, 286, 2, 286) == thumn(2, 285, 2, 285)


@pytest.mark.parametrize("args", [(None, 1, 2, 5), (2, 1, None, 5), (0, 1, 2, 5), (2, 1, 115, 5)])
def test_invalid_range_counts_nothing(args):
    assert thumn(*args) == 0


def test_ranking_sums_and_orders():
    rows = [
        (1, "A", "A", 106, 1, 114, 6),
        (2, "B", "B", 1, 1, 2, 15),
        (2, "B", "B", 2, 16, 2, 24),
        (3, "C", "C", None, None, None, None),
    ]
    assert rank_students_by_thumn(rows, 2) == [
        {"student": "B B", "thumn": 2.0, "rank": 1},
        {"student": "A A", "thumn": 1.0, "rank": 2},
    ]
