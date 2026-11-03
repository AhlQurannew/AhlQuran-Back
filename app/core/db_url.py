"""Normalize PostgreSQL connection strings between what hosts hand out and what each driver accepts.

Hosts such as Neon give `postgresql://…?sslmode=require&channel_binding=require`.
The app uses asyncpg (wants `postgresql+asyncpg://` and `ssl=require`) while Alembic uses
psycopg2 (wants `postgresql://` and `sslmode=require`), so both are derived from one URL.
"""
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

_UNSUPPORTED_PARAMS = {"channel_binding"}  # rejected by asyncpg, optional for psycopg2


def _rewrite(url: str, scheme: str, ssl_key: str) -> str:
    parts = urlsplit(url)
    query = []
    for key, value in parse_qsl(parts.query, keep_blank_values=True):
        if key in _UNSUPPORTED_PARAMS:
            continue
        query.append((ssl_key if key in {"ssl", "sslmode"} else key, value))
    return urlunsplit((scheme, parts.netloc, parts.path, urlencode(query), parts.fragment))


def _is_postgres(url: str) -> bool:
    return urlsplit(url).scheme in {"postgres", "postgresql", "postgresql+asyncpg", "postgresql+psycopg2"}


def to_async_url(url: str) -> str:
    """URL for SQLAlchemy's asyncpg engine."""
    return _rewrite(url, "postgresql+asyncpg", "ssl") if _is_postgres(url) else url


def to_sync_url(url: str) -> str:
    """URL for Alembic (psycopg2)."""
    return _rewrite(url, "postgresql", "sslmode") if _is_postgres(url) else url
