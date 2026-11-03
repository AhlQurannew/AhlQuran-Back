from app.core.db_url import to_async_url, to_sync_url

NEON = "postgresql://user:p%40ss@ep-x.neon.tech/neondb?sslmode=require&channel_binding=require"


def test_neon_url_is_converted_for_asyncpg():
    assert to_async_url(NEON) == "postgresql+asyncpg://user:p%40ss@ep-x.neon.tech/neondb?ssl=require"


def test_neon_url_is_converted_for_alembic():
    assert to_sync_url(NEON) == "postgresql://user:p%40ss@ep-x.neon.tech/neondb?sslmode=require"


def test_asyncpg_style_url_works_for_both_drivers():
    url = "postgresql+asyncpg://u:p@host/db?ssl=require"
    assert to_async_url(url) == url
    assert to_sync_url(url) == "postgresql://u:p@host/db?sslmode=require"


def test_plain_local_url_is_unchanged_apart_from_driver():
    url = "postgresql+asyncpg://u:p@db:5432/ahlquran_db"
    assert to_async_url(url) == url
    assert to_sync_url(url) == "postgresql://u:p@db:5432/ahlquran_db"


def test_heroku_style_postgres_scheme_is_accepted():
    assert to_async_url("postgres://u:p@host/db") == "postgresql+asyncpg://u:p@host/db"


def test_non_postgres_urls_are_left_alone():
    assert to_async_url("sqlite+aiosqlite:///x.db") == "sqlite+aiosqlite:///x.db"
    assert to_sync_url("sqlite+aiosqlite:///x.db") == "sqlite+aiosqlite:///x.db"
