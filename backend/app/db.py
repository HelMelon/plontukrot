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


def auto_migrate() -> None:
    """Ensure newly introduced columns exist in the PostgreSQL database."""
    try:
        with get_pool().connection() as conn:
            conn.execute("""
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS last_watered_at TIMESTAMPTZ;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS last_fertilized_at TIMESTAMPTZ;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS last_repotted_at TIMESTAMPTZ;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS last_manipulation_at TIMESTAMPTZ;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS initial_leaf_count INT NOT NULL DEFAULT 0;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS fertilizing_frequency_days INT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS watering_frequency INT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS variegation INT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS stage INT NOT NULL DEFAULT 0;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS nickname TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS plant_family TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS trading_name TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS cultivar TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS species TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS genus TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS members JSONB;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS archive_reason TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS archive_note TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS merged_into_plant_id TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS gifted_to_uid TEXT;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS on_balcony BOOLEAN NOT NULL DEFAULT false;
                ALTER TABLE plants ADD COLUMN IF NOT EXISTS balcony_band INT;

                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS reanimation_tags JSONB;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS is_greenhouse BOOLEAN NOT NULL DEFAULT false;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS note TEXT;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS stage_before INT;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS stage_after INT;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS stimulator_id TEXT;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS stimulator_name TEXT;
                ALTER TABLE plant_manipulations ADD COLUMN IF NOT EXISTS dosage TEXT;

                CREATE TABLE IF NOT EXISTS sensor_readings (
                    id BIGSERIAL PRIMARY KEY,
                    pot INT NOT NULL,
                    moisture DOUBLE PRECISION NOT NULL,
                    raw INT,
                    read_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
                CREATE INDEX IF NOT EXISTS idx_sensor_readings_pot
                    ON sensor_readings (pot, read_at DESC);

                CREATE TABLE IF NOT EXISTS sensor_names (
                    pot INT PRIMARY KEY,
                    name TEXT NOT NULL,
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );

                CREATE TABLE IF NOT EXISTS telegram_links (
                    user_id TEXT PRIMARY KEY,
                    chat_id TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );

                CREATE TABLE IF NOT EXISTS telegram_link_codes (
                    code TEXT PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    expires_at TIMESTAMPTZ NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_telegram_link_codes_user
                    ON telegram_link_codes (user_id);

                CREATE TABLE IF NOT EXISTS plant_sensor_bindings (
                    plant_id TEXT PRIMARY KEY,
                    pot INT NOT NULL,
                    user_id TEXT NOT NULL,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
                CREATE INDEX IF NOT EXISTS idx_plant_sensor_bindings_user
                    ON plant_sensor_bindings (user_id);

                CREATE TABLE IF NOT EXISTS balcony_temp_readings (
                    id BIGSERIAL PRIMARY KEY,
                    user_id TEXT NOT NULL,
                    temp_c DOUBLE PRECISION NOT NULL,
                    read_at TIMESTAMPTZ NOT NULL DEFAULT now()
                );
                CREATE INDEX IF NOT EXISTS idx_balcony_temp_readings_user_time
                    ON balcony_temp_readings (user_id, read_at DESC);

                CREATE TABLE IF NOT EXISTS genus_care_guides (
                    genus TEXT NOT NULL,
                    locale TEXT NOT NULL DEFAULT 'ru',
                    genus_name TEXT NOT NULL,
                    origin TEXT,
                    light TEXT,
                    watering TEXT,
                    fertilizing TEXT,
                    soil TEXT,
                    humidity TEXT,
                    toxicity TEXT,
                    min_temp_c DOUBLE PRECISION,
                    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                    PRIMARY KEY (genus, locale)
                );

                ALTER TABLE genus_care_guides
                    ADD COLUMN IF NOT EXISTS min_temp_c DOUBLE PRECISION;

                ALTER TABLE genus_care_guides
                    ADD COLUMN IF NOT EXISTS locale TEXT NOT NULL DEFAULT 'ru';

                ALTER TABLE users ADD COLUMN IF NOT EXISTS photo_url TEXT;
            """)
            conn.execute("""
                DO $genus_care_locale_pk$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1
                        FROM information_schema.table_constraints tc
                        JOIN information_schema.key_column_usage kcu
                          ON tc.constraint_name = kcu.constraint_name
                         AND tc.table_schema = kcu.table_schema
                        WHERE tc.table_name = 'genus_care_guides'
                          AND tc.constraint_type = 'PRIMARY KEY'
                          AND kcu.column_name = 'locale'
                    ) THEN
                        ALTER TABLE genus_care_guides
                            DROP CONSTRAINT IF EXISTS genus_care_guides_pkey;
                        ALTER TABLE genus_care_guides
                            ADD PRIMARY KEY (genus, locale);
                    END IF;
                END $genus_care_locale_pk$;
            """)
    except Exception:
        pass
