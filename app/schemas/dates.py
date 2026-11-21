"""Shared date rules for records people enter."""
from datetime import date, datetime, timedelta

from app.core.clock import today_algeria

TEXT_DATE_FORMATS = ("%d-%m-%Y", "%Y-%m-%d")


def not_in_future(day: date) -> date:
    # One day of slack: a browser just past midnight must not be refused.
    if day > today_algeria() + timedelta(days=1):
        raise ValueError("The date cannot be in the future")
    return day


def checked_text_date(value: str | None) -> str | None:
    """Dates stored as text must be real calendar days, written DD-MM-YYYY or YYYY-MM-DD."""
    if value is None or not value.strip():
        return None
    for fmt in TEXT_DATE_FORMATS:
        try:
            parsed = datetime.strptime(value.strip(), fmt).date()
        except ValueError:
            continue
        not_in_future(parsed)
        return value.strip()
    raise ValueError("Invalid date")
