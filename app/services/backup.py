"""Full platform backup and restore.

A backup is a ZIP file holding ``data.json`` (every table, row by row) and ``uploads/`` (images and
attachments stored on disk). Restoring replaces ALL current data with the backup's content, in one
transaction: either everything is restored or nothing changes.
"""
from __future__ import annotations

import base64
import io
import json
import zipfile
from datetime import date, datetime, time, timezone
from decimal import Decimal
from pathlib import Path, PurePosixPath
from typing import Any, Callable

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncConnection

FORMAT = "ahlquran-backup"
FORMAT_VERSION = 1
SKIP_TABLES = {"alembic_version"}
MAX_UNPACKED_BYTES = 1024 * 1024 * 1024  # refuse archives that would expand past 1 GB
INSERT_CHUNK = 500
# Versions whose tables and columns are identical (only indexes differ): their backups restore as is.
SAME_TABLES_AS = {"021": {"020"}}


class BackupError(ValueError):
    """The file is not a backup this server can restore."""


async def _tables(conn: AsyncConnection) -> list[sa.Table]:
    metadata = sa.MetaData()
    await conn.run_sync(lambda sync_conn: metadata.reflect(sync_conn))
    return [table for table in metadata.sorted_tables if table.name not in SKIP_TABLES]


async def _schema_version(conn: AsyncConnection) -> str | None:
    return (await conn.execute(sa.text("SELECT version_num FROM alembic_version"))).scalar()


def _encode(value: Any) -> Any:
    if isinstance(value, (datetime, date, time)):
        return value.isoformat()
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, (bytes, memoryview)):
        return base64.b64encode(bytes(value)).decode("ascii")
    if hasattr(value, "value") and not isinstance(value, (int, float, str, bool)):
        return value.value  # enum
    return value


def _decoder(column: sa.Column) -> Callable[[Any], Any]:
    kind = column.type
    if isinstance(kind, sa.DateTime):
        return datetime.fromisoformat
    if isinstance(kind, sa.Date):
        return date.fromisoformat
    if isinstance(kind, sa.Time):
        return time.fromisoformat
    if isinstance(kind, sa.Float):
        return float
    if isinstance(kind, sa.Numeric):
        return lambda value: Decimal(str(value))
    if isinstance(kind, sa.LargeBinary):
        return base64.b64decode
    return lambda value: value


async def build_backup(conn: AsyncConnection, upload_dir: str) -> bytes:
    tables = await _tables(conn)
    data = {
        "format": FORMAT,
        "format_version": FORMAT_VERSION,
        "schema_version": await _schema_version(conn),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "tables": {},
    }
    for table in tables:
        order = list(table.primary_key.columns) or list(table.columns)
        rows = (await conn.execute(sa.select(table).order_by(*order))).mappings().all()
        data["tables"][table.name] = [{key: _encode(value) for key, value in row.items()} for row in rows]

    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("data.json", json.dumps(data, ensure_ascii=False))
        root = Path(upload_dir)
        if root.is_dir():
            for path in sorted(root.rglob("*")):
                if path.is_file():
                    archive.write(path, "uploads/" + path.relative_to(root).as_posix())
    return buffer.getvalue()


def read_backup(raw: bytes) -> tuple[dict, dict[str, bytes]]:
    """Return (data, files) from a backup ZIP, or from a bare data.json."""
    files: dict[str, bytes] = {}
    try:
        if raw[:2] == b"PK":
            with zipfile.ZipFile(io.BytesIO(raw)) as archive:
                if sum(info.file_size for info in archive.infolist()) > MAX_UNPACKED_BYTES:
                    raise BackupError("The backup is too large")
                data = json.loads(archive.read("data.json"))
                for info in archive.infolist():
                    if info.is_dir() or not info.filename.startswith("uploads/"):
                        continue
                    relative = PurePosixPath(info.filename[len("uploads/"):])
                    if relative.is_absolute() or ".." in relative.parts or not relative.parts:
                        raise BackupError("The backup contains an unsafe file path")
                    files[relative.as_posix()] = archive.read(info)
        else:
            data = json.loads(raw)
    except (zipfile.BadZipFile, KeyError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise BackupError("This file is not a valid backup") from exc
    if not isinstance(data, dict) or data.get("format") != FORMAT or not isinstance(data.get("tables"), dict):
        raise BackupError("This file is not a valid backup")
    if data.get("format_version") != FORMAT_VERSION:
        raise BackupError("This backup format is not supported")
    return data, files


async def restore_backup(conn: AsyncConnection, data: dict) -> dict[str, int]:
    """Replace every table's content with the backup's. Runs inside the caller's transaction."""
    current = await _schema_version(conn)
    if data.get("schema_version") != current and data.get("schema_version") not in SAME_TABLES_AS.get(current, set()):
        raise BackupError(f"This backup was made with database version {data.get('schema_version')}; the server is at {current}")
    tables = await _tables(conn)
    by_name = {table.name: table for table in tables}
    unknown = set(data["tables"]) - set(by_name)
    if unknown:
        raise BackupError(f"Unknown tables in the backup: {', '.join(sorted(unknown))}")

    quote = conn.dialect.identifier_preparer.quote
    await conn.execute(sa.text("SET LOCAL lock_timeout = '20s'"))
    await conn.execute(sa.text(f"TRUNCATE {', '.join(quote(t.name) for t in tables)} RESTART IDENTITY CASCADE"))

    counts: dict[str, int] = {}
    for table in tables:
        rows = data["tables"].get(table.name) or []
        counts[table.name] = len(rows)
        if not rows:
            continue
        decoders = {column.name: _decoder(column) for column in table.columns}
        keys = sorted({key for row in rows for key in row})
        extra = set(keys) - set(decoders)
        if extra:
            raise BackupError(f"Unknown columns in {table.name}: {', '.join(sorted(extra))}")
        prepared = [{key: (None if row.get(key) is None else decoders[key](row[key])) for key in keys} for row in rows]

        # A row may point to another row of the same table (an admin created by an admin):
        # insert those links empty, then fill them once every row exists.
        self_links = [fk.parent.name for fk in table.foreign_keys if fk.column.table is table and fk.parent.name in keys]
        pk = [column.name for column in table.primary_key.columns]
        later = []
        if self_links:
            for row in prepared:
                links = {name: row[name] for name in self_links if row[name] is not None}
                if links:
                    later.append(({name: row[name] for name in pk}, links))
                    for name in links:
                        row[name] = None
        for start in range(0, len(prepared), INSERT_CHUNK):
            await conn.execute(table.insert(), prepared[start:start + INSERT_CHUNK])
        for key, links in later:
            await conn.execute(table.update().where(*[table.c[name] == value for name, value in key.items()]).values(**links))

        # Next ids continue after the restored ones.
        for column in table.primary_key.columns:
            if isinstance(column.type, sa.Integer):
                await conn.execute(sa.text(
                    f"SELECT setval(pg_get_serial_sequence(:table, :column), "
                    f"COALESCE((SELECT MAX({quote(column.name)}) FROM {quote(table.name)}), 0) + 1, false)"
                ), {"table": table.name, "column": column.name})
    return counts


def write_files(upload_dir: str, files: dict[str, bytes]) -> int:
    root = Path(upload_dir).resolve()
    for relative, content in files.items():
        destination = (root / relative).resolve()
        if root not in destination.parents:
            continue
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(content)
    return len(files)
