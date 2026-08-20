"""PostgreSQL connection pool via psycopg."""
import json

import psycopg
from psycopg.rows import dict_row
from psycopg_pool import ConnectionPool

from .config import settings

_pool: ConnectionPool | None = None


def jsonb(value):
    """Serialize a Python value for a JSONB column (None stays NULL)."""
    return None if value is None else json.dumps(value, ensure_ascii=False)


def get_pool() -> ConnectionPool:
    """Return the shared connection pool, creating it on first use."""
    global _pool
    if _pool is None:
        _pool = ConnectionPool(
            conninfo=settings.database_url,
            min_size=1,
            max_size=10,
            open=False,
            kwargs={"row_factory": dict_row},
        )
        _pool.open()
    return _pool


async def ping() -> None:
    """Cheap health check that runs `SELECT 1` against the pool."""
    with get_pool().connection() as conn:
        conn.execute("SELECT 1")
