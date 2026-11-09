"""The school day: Algeria is UTC+1 all year, while servers usually run on UTC."""
from datetime import date, datetime, timedelta, timezone

_ALGERIA = timezone(timedelta(hours=1))


def today_algeria() -> date:
    return datetime.now(_ALGERIA).date()
