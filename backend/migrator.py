#!/usr/bin/env python3
"""Migrate Firebase export (users.json) into the Postgres schema.

Reads ONLY ``exports/all_users_backup/users.json``. Does not talk to Firebase.

Usage::

    DATABASE_URL=postgresql://… python backend/migrator.py          # dry-run (rollback)
    DATABASE_URL=postgresql://… python backend/migrator.py --commit # persist

Temporary passwords for migrated users are written to
``backend/migrated_users.txt`` (email:password) only on ``--commit``.

Enum string→int mappings follow Dart enum declaration order in
``lib/models/`` (index).
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import secrets
import string
import sys
import uuid
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

import bcrypt
import psycopg
from psycopg.rows import dict_row
from psycopg.types.json import Json

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
BACKEND_DIR = Path(__file__).resolve().parent
REPO_ROOT = BACKEND_DIR.parent
DEFAULT_EXPORT = REPO_ROOT / "exports" / "all_users_backup" / "users.json"
PASSWORDS_FILE = BACKEND_DIR / "migrated_users.txt"
UNMAPPED_FILE = BACKEND_DIR / "migrated_unmapped.json"

logging.basicConfig(
    level=logging.INFO,
    format="%(levelname)s %(message)s",
)
log = logging.getLogger("migrator")

# ---------------------------------------------------------------------------
# Enum maps (Dart enum index order)
# ---------------------------------------------------------------------------
VARIEGATION = {
    "none": 0,
    "aurea": 1,
    "alba": 2,
    "pink": 3,
    "splash": 4,
    "mint": 5,
    "multicolor": 6,
    "tricolor": 7,
    "unknown": 8,
}
GROWTH_EVENT_TYPE = {
    "newLeaf": 0,
    "leafRemoved": 1,
    "watering": 2,
    "fertilizing": 3,
    "repotting": 4,
    "trimming": 5,
    "pinching": 6,
}
PROPAGATION_METHOD = {
    "leaf": 0,
    "leafFragment": 1,
    "rhizome": 2,
    "tuber": 3,
    "division": 4,
    "offset": 5,
    "cutting": 6,
    "microcloning": 7,
}
PROPAGATION_STATUS = {
    "active": 0,
    "sold": 1,
    "gifted": 2,
    "traded": 3,
    "lost": 4,
}
FRIEND_REQUEST_STATUS = {
    "pending": 0,
    "accepted": 1,
    "declined": 2,
}
GIFT_STATUS = {
    "pending": 0,
    "accepted": 1,
    "declined": 2,
    "cancelled": 3,
}
FINANCE_TYPE = {
    "income": 0,
    "expense": 1,
}

# Plant fields present in export but absent from plants table columns.
# Preserved in migrated_unmapped.json so nothing is silently dropped.
PLANT_UNMAPPED_KEYS = {
    "archiveNote",
    "archiveReason",
    "archivedAt",
    "expiresAt",
    "giftedToUid",
    "isFertilizingFrequencyCustom",
    "lastFertilizerName",
    "members",
    "mergedIntoPlantId",
    # Photos handled separately:
    "images",
    "imageUrl",
    "imageThumbUrl",
    # Typo key handled as wateringFrequency:
    "wateringFrequency ",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def hash_password(password: str) -> str:
    """Same bcrypt scheme as ``app.security.hash_password``."""
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def gen_password(length: int = 16) -> str:
    """Generate a temporary random password."""
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def parse_dt(value: Any, *, context: str) -> datetime | None:
    """Parse an ISO-8601 / Firestore-like timestamp string to aware UTC datetime."""
    if value is None or value == "":
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if not isinstance(value, str):
        log.warning("Bad date type in %s: %r", context, value)
        return None
    text = value.strip()
    if text.endswith("Z"):
        text = text[:-1] + "+00:00"
    try:
        dt = datetime.fromisoformat(text)
    except ValueError:
        log.warning("Unparseable date in %s: %r", context, value)
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt


def enum_int(mapping: dict[str, int], value: Any, *, default: int, context: str) -> int:
    """Map a Firestore string enum (or int) to schema INT."""
    if value is None:
        return default
    if isinstance(value, int):
        return value
    if isinstance(value, str):
        key = value.strip()
        if key in mapping:
            return mapping[key]
        log.warning("Unknown enum %r in %s — using default %s", value, context, default)
        return default
    log.warning("Bad enum type in %s: %r — using default %s", context, value, default)
    return default


def fields_of(doc: dict[str, Any]) -> dict[str, Any]:
    """Return the Firestore ``fields`` map from an export document."""
    return doc.get("fields") or {}


def doc_id(doc: dict[str, Any]) -> str:
    """Return the Firestore document id."""
    return str(doc["id"])


def as_jsonb(value: Any) -> Json | None:
    """Wrap a Python value for a JSONB column, or None."""
    if value is None:
        return None
    return Json(value)


def photo_row_id(plant_id: str, image_id: str) -> str:
    """Globally unique plant_photos.id (``legacy`` repeats across plants)."""
    return f"{plant_id}__{image_id}"


# ---------------------------------------------------------------------------
# Counters / skip log
# ---------------------------------------------------------------------------
class Stats:
    """Insertion / skip counters for the final report."""

    def __init__(self) -> None:
        self.inserted: Counter[str] = Counter()
        self.skipped_existing: Counter[str] = Counter()
        self.warnings: list[str] = []
        self.unmapped: dict[str, Any] = {"plants": {}, "notes": []}

    def warn(self, msg: str) -> None:
        log.warning(msg)
        self.warnings.append(msg)


# ---------------------------------------------------------------------------
# Upsert helpers
# ---------------------------------------------------------------------------
def exists(conn: psycopg.Connection, table: str, id_value: str) -> bool:
    """Return True if a row with primary key ``id`` already exists."""
    row = conn.execute(
        f"SELECT 1 FROM {table} WHERE id = %s",  # noqa: S608 — table name is internal
        (id_value,),
    ).fetchone()
    return row is not None


def insert_row(
    conn: psycopg.Connection,
    table: str,
    columns: list[str],
    values: tuple[Any, ...],
    stats: Stats,
) -> bool:
    """INSERT … ON CONFLICT (id) DO NOTHING. Returns True if a row was inserted."""
    placeholders = ", ".join(["%s"] * len(columns))
    cols = ", ".join(columns)
    cur = conn.execute(
        f"INSERT INTO {table} ({cols}) VALUES ({placeholders}) "
        f"ON CONFLICT (id) DO NOTHING",  # noqa: S608
        values,
    )
    if cur.rowcount and cur.rowcount > 0:
        stats.inserted[table] += 1
        return True
    stats.skipped_existing[table] += 1
    return False


# ---------------------------------------------------------------------------
# Per-entity migrators
# ---------------------------------------------------------------------------
def ensure_user_uuid(
    conn: psycopg.Connection,
    firebase_uid: str,
    uid_map: dict[str, uuid.UUID],
    stats: Stats,
    *,
    placeholder: bool = False,
) -> uuid.UUID | None:
    """Resolve firebase_uid → UUID, creating a placeholder user if needed."""
    if firebase_uid in uid_map:
        return uid_map[firebase_uid]

    row = conn.execute(
        "SELECT id FROM users WHERE firebase_uid = %s",
        (firebase_uid,),
    ).fetchone()
    if row:
        uid_map[firebase_uid] = row["id"]
        return row["id"]

    if not placeholder:
        return None

    # Placeholder for social FKs pointing at users outside this export.
    new_id = uuid.uuid4()
    email = f"placeholder+{firebase_uid[:12]}@migrated.invalid"
    password = gen_password()
    insert_row(
        conn,
        "users",
        [
            "id",
            "firebase_uid",
            "email",
            "password_hash",
            "name",
            "locale_code",
            "currency_code",
            "collection_visibility",
        ],
        (
            new_id,
            firebase_uid,
            email,
            hash_password(password),
            f"[placeholder {firebase_uid[:8]}]",
            "ru",
            "BYN",
            "friends",
        ),
        stats,
    )
    uid_map[firebase_uid] = new_id
    stats.warn(
        f"Created placeholder user for unknown firebase_uid={firebase_uid} "
        f"email={email}"
    )
    return new_id


def migrate_user(
    conn: psycopg.Connection,
    firebase_uid: str,
    profile_doc: dict[str, Any],
    uid_map: dict[str, uuid.UUID],
    passwords: list[tuple[str, str]],
    stats: Stats,
) -> uuid.UUID | None:
    """Insert (or reuse) a users row; return the new UUID."""
    f = fields_of(profile_doc)
    email = (f.get("email") or "").strip().lower()
    if not email:
        stats.warn(f"User {firebase_uid}: no email — skipped")
        return None

    existing = conn.execute(
        "SELECT id, email FROM users WHERE firebase_uid = %s OR email = %s",
        (firebase_uid, email),
    ).fetchone()
    if existing:
        uid_map[firebase_uid] = existing["id"]
        stats.skipped_existing["users"] += 1
        log.info("User exists firebase_uid=%s → %s", firebase_uid, existing["id"])
        return existing["id"]

    new_id = uuid.uuid4()
    password = gen_password()
    passwords.append((email, password))

    ok = insert_row(
        conn,
        "users",
        [
            "id",
            "firebase_uid",
            "email",
            "password_hash",
            "name",
            "locale_code",
            "currency_code",
            "collection_visibility",
            "personal_data_consent_at",
            "created_at",
        ],
        (
            new_id,
            firebase_uid,
            email,
            hash_password(password),
            f.get("name"),
            f.get("localeCode") or "ru",
            f.get("currencyCode") or "BYN",
            f.get("collectionVisibility") or "friends",
            parse_dt(f.get("personalDataConsentAt"), context=f"user[{firebase_uid}].consent"),
            parse_dt(f.get("createdAt"), context=f"user[{firebase_uid}].createdAt")
            or datetime.now(timezone.utc),
        ),
        stats,
    )
    if ok:
        uid_map[firebase_uid] = new_id
        log.info("Inserted user %s → %s (%s)", firebase_uid, new_id, email)
        return new_id
    # Race / conflict — re-read
    row = conn.execute(
        "SELECT id FROM users WHERE firebase_uid = %s OR email = %s",
        (firebase_uid, email),
    ).fetchone()
    if row:
        uid_map[firebase_uid] = row["id"]
        return row["id"]
    stats.warn(f"Failed to insert user {firebase_uid}")
    return None


def migrate_plant_photos(
    conn: psycopg.Connection,
    plant_id: str,
    fields: dict[str, Any],
    stats: Stats,
) -> None:
    """Insert gallery images and/or a legacy cover into plant_photos."""
    images = fields.get("images")
    if isinstance(images, list) and images:
        for im in images:
            if not isinstance(im, dict):
                continue
            image_url = im.get("imageUrl")
            if not image_url:
                stats.warn(f"plant {plant_id}: photo without imageUrl skipped")
                continue
            image_id = str(im.get("id") or "unknown")
            is_legacy = image_id == "legacy"
            insert_row(
                conn,
                "plant_photos",
                [
                    "id",
                    "plant_id",
                    "image_url",
                    "image_thumb_url",
                    "added_at",
                    "is_legacy",
                ],
                (
                    photo_row_id(plant_id, image_id),
                    plant_id,
                    image_url,
                    im.get("imageThumbUrl"),
                    parse_dt(im.get("addedAt"), context=f"photo[{plant_id}/{image_id}]")
                    or datetime.now(timezone.utc),
                    is_legacy,
                ),
                stats,
            )
        return

    # Legacy single cover (no gallery array, or empty gallery).
    image_url = fields.get("imageUrl")
    if image_url:
        insert_row(
            conn,
            "plant_photos",
            [
                "id",
                "plant_id",
                "image_url",
                "image_thumb_url",
                "added_at",
                "is_legacy",
            ],
            (
                photo_row_id(plant_id, "legacy"),
                plant_id,
                image_url,
                fields.get("imageThumbUrl"),
                parse_dt(fields.get("createdAt"), context=f"legacy-photo[{plant_id}]")
                or datetime.now(timezone.utc),
                True,
            ),
            stats,
        )


def migrate_plant(
    conn: psycopg.Connection,
    user_id: uuid.UUID,
    doc: dict[str, Any],
    stats: Stats,
) -> None:
    """Insert one plants row + its photos; stash unmapped fields."""
    plant_id = doc_id(doc)
    f = fields_of(doc)

    # Preserve archive / misc fields outside the schema.
    extra = {k: f[k] for k in PLANT_UNMAPPED_KEYS if k in f and k not in {
        "images", "imageUrl", "imageThumbUrl", "wateringFrequency ",
    }}
    if extra:
        stats.unmapped["plants"][plant_id] = extra

    # Typo key with trailing space seen in export.
    watering_freq = f.get("wateringFrequency")
    if watering_freq is None and "wateringFrequency " in f:
        watering_freq = f.get("wateringFrequency ")
        stats.warn(f"plant {plant_id}: used typo key 'wateringFrequency '")

    variegation = f.get("variegation")
    variegation_int: int | None
    if variegation is None or variegation == "":
        variegation_int = None
    else:
        variegation_int = enum_int(
            VARIEGATION, variegation, default=8, context=f"plant[{plant_id}].variegation"
        )

    created_at = parse_dt(f.get("createdAt"), context=f"plant[{plant_id}].createdAt")

    insert_row(
        conn,
        "plants",
        [
            "id",
            "user_id",
            "genus",
            "species",
            "cultivar",
            "trading_name",
            "plant_family",
            "nickname",
            "stage",
            "variegation",
            "watering_frequency",
            "fertilizing_frequency_days",
            "initial_leaf_count",
            "last_watered_at",
            "last_fertilized_at",
            "last_repotted_at",
            "created_at",
        ],
        (
            plant_id,
            user_id,
            f.get("genus"),
            f.get("species"),
            f.get("cultivar"),
            f.get("tradingName"),
            f.get("plantFamily"),
            f.get("nickname"),
            int(f.get("stage") or 0),
            variegation_int,
            watering_freq,
            f.get("fertilizingFrequencyDays"),
            int(f.get("initialLeafCount") or 0),
            parse_dt(f.get("lastWateredAt"), context=f"plant[{plant_id}].lastWateredAt"),
            parse_dt(f.get("lastFertilizedAt"), context=f"plant[{plant_id}].lastFertilizedAt"),
            parse_dt(f.get("lastRepottedAt"), context=f"plant[{plant_id}].lastRepottedAt"),
            created_at or datetime.now(timezone.utc),
        ),
        stats,
    )
    migrate_plant_photos(conn, plant_id, f, stats)


def migrate_plant_notes(
    conn: psycopg.Connection, plant_id: str, docs: list[dict], stats: Stats
) -> None:
    """Insert plant_notes rows."""
    for doc in docs:
        f = fields_of(doc)
        text = f.get("text")
        if not text:
            stats.warn(f"plant_notes {doc_id(doc)}: empty text — skipped")
            continue
        insert_row(
            conn,
            "plant_notes",
            ["id", "plant_id", "text", "created_at", "updated_at", "expires_at"],
            (
                doc_id(doc),
                plant_id,
                text,
                parse_dt(f.get("createdAt"), context=f"note[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
                parse_dt(f.get("updatedAt"), context=f"note[{doc_id(doc)}].updated")
                or datetime.now(timezone.utc),
                parse_dt(f.get("expiresAt"), context=f"note[{doc_id(doc)}].expires"),
            ),
            stats,
        )


def migrate_growth_events(
    conn: psycopg.Connection, plant_id: str, docs: list[dict], stats: Stats
) -> None:
    """Insert plant_growth_events. ``reason`` (leafRemoved) has no column — logged."""
    for doc in docs:
        f = fields_of(doc)
        if f.get("reason") is not None:
            stats.unmapped["notes"].append(
                {
                    "table": "plant_growth_events",
                    "id": doc_id(doc),
                    "reason": f.get("reason"),
                }
            )
        insert_row(
            conn,
            "plant_growth_events",
            ["id", "plant_id", "type", "created_at", "expires_at"],
            (
                doc_id(doc),
                plant_id,
                enum_int(
                    GROWTH_EVENT_TYPE,
                    f.get("type"),
                    default=0,
                    context=f"growth[{doc_id(doc)}]",
                ),
                parse_dt(f.get("createdAt"), context=f"growth[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
                parse_dt(f.get("expiresAt"), context=f"growth[{doc_id(doc)}].expires"),
            ),
            stats,
        )


def migrate_waterings(
    conn: psycopg.Connection, plant_id: str, docs: list[dict], stats: Stats
) -> None:
    """Insert plant_waterings rows."""
    for doc in docs:
        f = fields_of(doc)
        insert_row(
            conn,
            "plant_waterings",
            ["id", "plant_id", "watered_at", "next_watering", "created_at"],
            (
                doc_id(doc),
                plant_id,
                parse_dt(f.get("wateredAt"), context=f"watering[{doc_id(doc)}]"),
                parse_dt(f.get("nextWatering"), context=f"watering[{doc_id(doc)}].next"),
                parse_dt(f.get("createdAt"), context=f"watering[{doc_id(doc)}].created")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_fertilizings(
    conn: psycopg.Connection, plant_id: str, docs: list[dict], stats: Stats
) -> None:
    """Insert plant_fertilizings rows."""
    for doc in docs:
        f = fields_of(doc)
        applied = parse_dt(f.get("appliedAt"), context=f"fert[{doc_id(doc)}].applied")
        if applied is None:
            stats.warn(f"fertilizing {doc_id(doc)}: missing appliedAt — skipped")
            continue
        insert_row(
            conn,
            "plant_fertilizings",
            [
                "id",
                "plant_id",
                "fertilizer_id",
                "fertilizer_name",
                "application_method",
                "components",
                "water_ml",
                "applied_at",
                "next_fertilizing",
                "created_at",
            ],
            (
                doc_id(doc),
                plant_id,
                f.get("fertilizerId"),
                f.get("fertilizerName"),
                f.get("applicationMethod"),
                as_jsonb(f.get("components")),
                f.get("waterMl"),
                applied,
                parse_dt(f.get("nextFertilizing"), context=f"fert[{doc_id(doc)}].next"),
                parse_dt(f.get("createdAt"), context=f"fert[{doc_id(doc)}].created")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_repottings(
    conn: psycopg.Connection, plant_id: str, docs: list[dict], stats: Stats
) -> None:
    """Insert plant_repottings rows."""
    for doc in docs:
        f = fields_of(doc)
        repotted = parse_dt(f.get("repottedAt"), context=f"repot[{doc_id(doc)}]")
        if repotted is None:
            stats.warn(f"repotting {doc_id(doc)}: missing repottedAt — skipped")
            continue
        insert_row(
            conn,
            "plant_repottings",
            [
                "id",
                "plant_id",
                "soil_id",
                "soil_name",
                "components",
                "slow_release_fertilizer",
                "repotted_at",
                "created_at",
            ],
            (
                doc_id(doc),
                plant_id,
                f.get("soilId"),
                f.get("soilName"),
                as_jsonb(f.get("components")),
                bool(f.get("slowReleaseFertilizer") or False),
                repotted,
                parse_dt(f.get("createdAt"), context=f"repot[{doc_id(doc)}].created")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_manipulations(
    conn: psycopg.Connection, plant_id: str, docs: list[dict], stats: Stats
) -> None:
    """Insert plant_manipulations (export may be empty)."""
    # ManipulationType in Dart: pinching, rerooting, stimulator → indices 0,1,2
    manip_type = {"pinching": 0, "rerooting": 1, "stimulator": 2}
    for doc in docs:
        f = fields_of(doc)
        applied = parse_dt(f.get("appliedAt"), context=f"manip[{doc_id(doc)}]")
        if applied is None:
            stats.warn(f"manipulation {doc_id(doc)}: missing appliedAt — skipped")
            continue
        type_val = f.get("type")
        if isinstance(type_val, str):
            type_int = enum_int(
                manip_type, type_val, default=0, context=f"manip[{doc_id(doc)}]"
            )
        else:
            type_int = int(type_val or 0)
        insert_row(
            conn,
            "plant_manipulations",
            [
                "id",
                "plant_id",
                "type",
                "applied_at",
                "note",
                "stage_before",
                "stage_after",
                "stimulator_id",
                "stimulator_name",
                "dosage",
                "created_at",
            ],
            (
                doc_id(doc),
                plant_id,
                type_int,
                applied,
                f.get("note"),
                f.get("stageBefore"),
                f.get("stageAfter"),
                f.get("stimulatorId"),
                f.get("stimulatorName"),
                f.get("dosage"),
                parse_dt(f.get("createdAt"), context=f"manip[{doc_id(doc)}].created")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_plant_nested(
    conn: psycopg.Connection, user_blob: dict[str, Any], stats: Stats
) -> None:
    """Migrate plants_<id> nested collections for one user."""
    for key, blob in user_blob.items():
        if not key.startswith("plants_") or not isinstance(blob, dict):
            continue
        plant_id = key[len("plants_") :]
        if not exists(conn, "plants", plant_id):
            stats.warn(
                f"Nested data for missing plant {plant_id} — skipped "
                f"(notes/growth/care)"
            )
            continue
        migrate_plant_notes(conn, plant_id, blob.get("notes") or [], stats)
        migrate_growth_events(conn, plant_id, blob.get("growthEvents") or [], stats)
        migrate_waterings(conn, plant_id, blob.get("watering") or [], stats)
        migrate_fertilizings(conn, plant_id, blob.get("fertilizing") or [], stats)
        migrate_repottings(conn, plant_id, blob.get("repotting") or [], stats)
        migrate_manipulations(conn, plant_id, blob.get("manipulations") or [], stats)
        unknown = set(blob.keys()) - {
            "notes",
            "growthEvents",
            "watering",
            "fertilizing",
            "repotting",
            "manipulations",
        }
        if unknown:
            stats.warn(f"plant {plant_id}: unknown nested keys {sorted(unknown)}")


def migrate_propagation(
    conn: psycopg.Connection,
    user_id: uuid.UUID,
    doc: dict[str, Any],
    stats: Stats,
) -> None:
    """Insert one propagations row."""
    f = fields_of(doc)
    started = parse_dt(f.get("startedAt"), context=f"prop[{doc_id(doc)}].started")
    if started is None:
        stats.warn(f"propagation {doc_id(doc)}: missing startedAt — skipped")
        return
    insert_row(
        conn,
        "propagations",
        [
            "id",
            "user_id",
            "parent_plant_id",
            "parent_plant_name",
            "parent_plant_family",
            "method",
            "stage",
            "status",
            "quantity",
            "quantity_alive",
            "gifted_quantity",
            "sold_quantity",
            "traded_quantity",
            "lost_quantity",
            "started_at",
            "sold_at",
            "created_at",
        ],
        (
            doc_id(doc),
            user_id,
            f.get("parentPlantId"),
            f.get("parentPlantName"),
            f.get("parentPlantFamily"),
            enum_int(
                PROPAGATION_METHOD,
                f.get("method"),
                default=0,
                context=f"prop[{doc_id(doc)}].method",
            ),
            int(f.get("stage") or 0),
            enum_int(
                PROPAGATION_STATUS,
                f.get("status"),
                default=0,
                context=f"prop[{doc_id(doc)}].status",
            ),
            int(f.get("quantity") or 0),
            int(f.get("quantityAlive") or 0),
            int(f.get("giftedQuantity") or 0),
            int(f.get("soldQuantity") or 0),
            int(f.get("tradedQuantity") or 0),
            int(f.get("lostQuantity") or 0),
            started,
            parse_dt(f.get("soldAt"), context=f"prop[{doc_id(doc)}].soldAt"),
            parse_dt(f.get("createdAt"), context=f"prop[{doc_id(doc)}].created")
            or datetime.now(timezone.utc),
        ),
        stats,
    )


def migrate_propagation_nested(
    conn: psycopg.Connection, user_blob: dict[str, Any], stats: Stats
) -> None:
    """Migrate propagations_<id> notes + stageHistory."""
    for key, blob in user_blob.items():
        if not key.startswith("propagations_") or not isinstance(blob, dict):
            continue
        prop_id = key[len("propagations_") :]
        if not exists(conn, "propagations", prop_id):
            stats.warn(f"Nested data for missing propagation {prop_id} — skipped")
            continue
        for doc in blob.get("notes") or []:
            f = fields_of(doc)
            text = f.get("text")
            if not text:
                stats.warn(f"propagation_notes {doc_id(doc)}: empty text — skipped")
                continue
            insert_row(
                conn,
                "propagation_notes",
                [
                    "id",
                    "propagation_id",
                    "text",
                    "created_at",
                    "updated_at",
                    "expires_at",
                ],
                (
                    doc_id(doc),
                    prop_id,
                    text,
                    parse_dt(f.get("createdAt"), context=f"pnote[{doc_id(doc)}]")
                    or datetime.now(timezone.utc),
                    parse_dt(f.get("updatedAt"), context=f"pnote[{doc_id(doc)}].upd")
                    or datetime.now(timezone.utc),
                    parse_dt(f.get("expiresAt"), context=f"pnote[{doc_id(doc)}].exp"),
                ),
                stats,
            )
        for doc in blob.get("stageHistory") or []:
            f = fields_of(doc)
            insert_row(
                conn,
                "propagation_stage_history",
                [
                    "id",
                    "propagation_id",
                    "stage",
                    "quantity_alive",
                    "outcome",
                    "note",
                    "changed_at",
                ],
                (
                    doc_id(doc),
                    prop_id,
                    int(f.get("stage") or 0),
                    int(f.get("quantityAlive") or 0),
                    f.get("outcome"),
                    f.get("note"),
                    parse_dt(f.get("changedAt"), context=f"stageHist[{doc_id(doc)}]")
                    or datetime.now(timezone.utc),
                ),
                stats,
            )


def migrate_simple_catalog(
    conn: psycopg.Connection,
    user_id: uuid.UUID,
    docs: list[dict],
    table: str,
    name_key: str,
    stats: Stats,
) -> None:
    """Insert fertilizer_components / components style rows (id, user_id, name, created_at)."""
    for doc in docs:
        f = fields_of(doc)
        name = f.get(name_key) or f.get("name")
        if not name:
            stats.warn(f"{table} {doc_id(doc)}: no name — skipped")
            continue
        insert_row(
            conn,
            table,
            ["id", "user_id", "name", "created_at"],
            (
                doc_id(doc),
                user_id,
                name,
                parse_dt(f.get("createdAt"), context=f"{table}[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_soils(
    conn: psycopg.Connection, user_id: uuid.UUID, docs: list[dict], stats: Stats
) -> None:
    """Insert soils with JSONB components."""
    for doc in docs:
        f = fields_of(doc)
        name = f.get("name")
        if not name:
            stats.warn(f"soil {doc_id(doc)}: no name — skipped")
            continue
        insert_row(
            conn,
            "soils",
            ["id", "user_id", "name", "components", "created_at"],
            (
                doc_id(doc),
                user_id,
                name,
                as_jsonb(f.get("components")),
                parse_dt(f.get("createdAt"), context=f"soil[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_wish_list(
    conn: psycopg.Connection, user_id: uuid.UUID, docs: list[dict], stats: Stats
) -> None:
    """Insert wish_list_items."""
    for doc in docs:
        f = fields_of(doc)
        name_en = f.get("nameEn")
        if not name_en:
            stats.warn(f"wish_list {doc_id(doc)}: no nameEn — skipped")
            continue
        insert_row(
            conn,
            "wish_list_items",
            ["id", "user_id", "name_en", "name_alt", "created_at", "updated_at"],
            (
                doc_id(doc),
                user_id,
                name_en,
                f.get("nameAlt"),
                parse_dt(f.get("createdAt"), context=f"wish[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
                parse_dt(f.get("updatedAt"), context=f"wish[{doc_id(doc)}].upd")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_finance(
    conn: psycopg.Connection, user_id: uuid.UUID, docs: list[dict], stats: Stats
) -> None:
    """Insert finance_entries. ``source`` stays TEXT; type is mapped to INT."""
    for doc in docs:
        f = fields_of(doc)
        title = f.get("title")
        amount = f.get("amount")
        date = parse_dt(f.get("date"), context=f"finance[{doc_id(doc)}].date")
        if not title or amount is None or date is None:
            stats.warn(f"finance {doc_id(doc)}: missing title/amount/date — skipped")
            continue
        insert_row(
            conn,
            "finance_entries",
            [
                "id",
                "user_id",
                "title",
                "amount",
                "type",
                "source",
                "date",
                "wish_list_item_id",
                "created_at",
                "updated_at",
            ],
            (
                doc_id(doc),
                user_id,
                title,
                amount,
                enum_int(
                    FINANCE_TYPE,
                    f.get("type"),
                    default=1,
                    context=f"finance[{doc_id(doc)}].type",
                ),
                f.get("source"),
                date,
                f.get("wishListItemId"),
                parse_dt(f.get("createdAt"), context=f"finance[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
                parse_dt(f.get("updatedAt"), context=f"finance[{doc_id(doc)}].upd")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_friend_requests(
    conn: psycopg.Connection,
    docs: list[dict],
    uid_map: dict[str, uuid.UUID],
    stats: Stats,
) -> None:
    """Insert friend_requests; map fromUid/toUid via firebase_uid map."""
    for doc in docs:
        f = fields_of(doc)
        from_fb = f.get("fromUid")
        to_fb = f.get("toUid")
        if not from_fb or not to_fb:
            stats.warn(f"friend_request {doc_id(doc)}: missing from/to — skipped")
            continue
        from_uuid = ensure_user_uuid(
            conn, from_fb, uid_map, stats, placeholder=True
        )
        to_uuid = ensure_user_uuid(conn, to_fb, uid_map, stats, placeholder=True)
        if from_uuid is None or to_uuid is None:
            stats.warn(f"friend_request {doc_id(doc)}: could not resolve UIDs — skipped")
            continue
        insert_row(
            conn,
            "friend_requests",
            [
                "id",
                "from_uid",
                "to_uid",
                "from_display_name",
                "from_photo_url",
                "status",
                "created_at",
            ],
            (
                doc_id(doc),
                from_uuid,
                to_uuid,
                f.get("fromDisplayName"),
                f.get("fromPhotoUrl"),
                enum_int(
                    FRIEND_REQUEST_STATUS,
                    f.get("status"),
                    default=0,
                    context=f"fr[{doc_id(doc)}]",
                ),
                parse_dt(f.get("createdAt"), context=f"fr[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_incoming_gifts(
    conn: psycopg.Connection,
    owner_fb: str,
    docs: list[dict],
    uid_map: dict[str, uuid.UUID],
    stats: Stats,
) -> None:
    """Insert incoming_gifts. Owner of the collection is to_uid."""
    to_uuid = uid_map.get(owner_fb)
    if to_uuid is None:
        return
    for doc in docs:
        f = fields_of(doc)
        from_fb = f.get("fromUid")
        if not from_fb:
            stats.warn(f"incoming_gift {doc_id(doc)}: no fromUid — skipped")
            continue
        from_uuid = ensure_user_uuid(
            conn, from_fb, uid_map, stats, placeholder=True
        )
        if from_uuid is None:
            continue
        # Export has no archivedAt on incoming; schema has no archived_at either.
        # Extra keys (none expected beyond mapped) are fine.
        insert_row(
            conn,
            "incoming_gifts",
            [
                "id",
                "to_uid",
                "from_uid",
                "from_display_name",
                "from_plant_id",
                "plant_snapshot",
                "status",
                "created_at",
            ],
            (
                doc_id(doc),
                to_uuid,
                from_uuid,
                f.get("fromDisplayName"),
                f.get("fromPlantId"),
                as_jsonb(f.get("plantSnapshot")),
                enum_int(
                    GIFT_STATUS,
                    f.get("status"),
                    default=0,
                    context=f"ig[{doc_id(doc)}]",
                ),
                parse_dt(f.get("createdAt"), context=f"ig[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


def migrate_outgoing_gifts(
    conn: psycopg.Connection,
    owner_fb: str,
    docs: list[dict],
    uid_map: dict[str, uuid.UUID],
    stats: Stats,
) -> None:
    """Insert outgoing_gifts. Owner is from_uid; recipientUid → to_uid.

    Export fields ``archivedAt`` have no column in outgoing_gifts — preserved
    in unmapped sidecar.
    """
    from_uuid = uid_map.get(owner_fb)
    if from_uuid is None:
        return
    for doc in docs:
        f = fields_of(doc)
        to_fb = f.get("recipientUid")
        if not to_fb:
            stats.warn(f"outgoing_gift {doc_id(doc)}: no recipientUid — skipped")
            continue
        to_uuid = ensure_user_uuid(conn, to_fb, uid_map, stats, placeholder=True)
        if to_uuid is None:
            continue
        if f.get("archivedAt") is not None:
            stats.unmapped.setdefault("outgoing_gifts", {})[doc_id(doc)] = {
                "archivedAt": f.get("archivedAt"),
            }
        insert_row(
            conn,
            "outgoing_gifts",
            [
                "id",
                "from_uid",
                "to_uid",
                "from_display_name",
                "from_plant_id",
                "plant_snapshot",
                "status",
                "created_at",
            ],
            (
                doc_id(doc),
                from_uuid,
                to_uuid,
                None,  # not in outgoing export
                f.get("plantId"),
                None,  # snapshot lives on incoming side
                enum_int(
                    GIFT_STATUS,
                    f.get("status"),
                    default=0,
                    context=f"og[{doc_id(doc)}]",
                ),
                parse_dt(f.get("createdAt"), context=f"og[{doc_id(doc)}]")
                or datetime.now(timezone.utc),
            ),
            stats,
        )


# ---------------------------------------------------------------------------
# Inventory (pre-flight)
# ---------------------------------------------------------------------------
def inventory(data: dict[str, Any]) -> dict[str, int]:
    """Count export entities before touching the DB."""
    counts: Counter[str] = Counter()
    counts["users"] = len(data)
    for u in data.values():
        counts["plants"] += len(u.get("plants") or [])
        counts["propagations"] += len(u.get("propagations") or [])
        counts["fertilizer_components"] += len(u.get("fertilizerComponents") or [])
        counts["soils"] += len(u.get("soils") or [])
        counts["components"] += len(u.get("components") or [])
        counts["wish_list_items"] += len(u.get("wishList") or [])
        counts["finance_entries"] += len(u.get("financeEntries") or [])
        counts["friend_requests"] += len(u.get("friendRequests") or [])
        counts["incoming_gifts"] += len(u.get("incomingGifts") or [])
        counts["outgoing_gifts"] += len(u.get("outgoingGifts") or [])
        for key, blob in u.items():
            if key.startswith("plants_") and isinstance(blob, dict):
                counts["plant_notes"] += len(blob.get("notes") or [])
                counts["plant_growth_events"] += len(blob.get("growthEvents") or [])
                counts["plant_waterings"] += len(blob.get("watering") or [])
                counts["plant_fertilizings"] += len(blob.get("fertilizing") or [])
                counts["plant_repottings"] += len(blob.get("repotting") or [])
                counts["plant_manipulations"] += len(blob.get("manipulations") or [])
            if key.startswith("propagations_") and isinstance(blob, dict):
                counts["propagation_notes"] += len(blob.get("notes") or [])
                counts["propagation_stage_history"] += len(
                    blob.get("stageHistory") or []
                )
        for plant in u.get("plants") or []:
            f = fields_of(plant)
            imgs = f.get("images") or []
            if imgs:
                counts["plant_photos"] += sum(
                    1 for im in imgs if isinstance(im, dict) and im.get("imageUrl")
                )
            elif f.get("imageUrl"):
                counts["plant_photos"] += 1
    return dict(counts)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def run(export_path: Path, database_url: str, *, commit: bool) -> int:
    """Execute the migration. Returns process exit code."""
    if not export_path.is_file():
        log.error("Export file not found: %s", export_path)
        return 1

    with export_path.open(encoding="utf-8") as fh:
        data: dict[str, Any] = json.load(fh)

    inv = inventory(data)
    log.info("=== INVENTORY (from %s) ===", export_path)
    for table, n in sorted(inv.items()):
        log.info("  %-28s %5d", table, n)
    log.info(
        "plant_species / fertilizers / stimulators / friends: "
        "NOT in this export — skipped (reserved)"
    )

    stats = Stats()
    uid_map: dict[str, uuid.UUID] = {}
    passwords: list[tuple[str, str]] = []

    mode = "COMMIT" if commit else "DRY-RUN (will ROLLBACK)"
    log.info("=== CONNECTING (%s) ===", mode)

    try:
        conn_cm = psycopg.connect(database_url, row_factory=dict_row)
    except psycopg.OperationalError as exc:
        log.error("Cannot connect to database: %s", exc)
        log.error(
            "Inventory above is what WOULD be migrated. "
            "Fix DATABASE_URL / network / auth and re-run."
        )
        return 1

    with conn_cm as conn:
        conn.execute("BEGIN")
        try:
            # Pass 1: all users (needed before social FK mapping).
            for firebase_uid, blob in data.items():
                profile = blob.get("profile")
                if not isinstance(profile, dict):
                    stats.warn(f"{firebase_uid}: no profile — skipped")
                    continue
                migrate_user(
                    conn, firebase_uid, profile, uid_map, passwords, stats
                )

            # Pass 2: owned data per user.
            for firebase_uid, blob in data.items():
                user_id = uid_map.get(firebase_uid)
                if user_id is None:
                    continue

                for doc in blob.get("plants") or []:
                    migrate_plant(conn, user_id, doc, stats)
                migrate_plant_nested(conn, blob, stats)

                for doc in blob.get("propagations") or []:
                    migrate_propagation(conn, user_id, doc, stats)
                migrate_propagation_nested(conn, blob, stats)

                migrate_simple_catalog(
                    conn,
                    user_id,
                    blob.get("fertilizerComponents") or [],
                    "fertilizer_components",
                    "name",
                    stats,
                )
                migrate_soils(conn, user_id, blob.get("soils") or [], stats)
                migrate_simple_catalog(
                    conn,
                    user_id,
                    blob.get("components") or [],
                    "components",
                    "name",
                    stats,
                )
                migrate_wish_list(conn, user_id, blob.get("wishList") or [], stats)
                migrate_finance(
                    conn, user_id, blob.get("financeEntries") or [], stats
                )

                migrate_friend_requests(
                    conn, blob.get("friendRequests") or [], uid_map, stats
                )
                migrate_incoming_gifts(
                    conn,
                    firebase_uid,
                    blob.get("incomingGifts") or [],
                    uid_map,
                    stats,
                )
                migrate_outgoing_gifts(
                    conn,
                    firebase_uid,
                    blob.get("outgoingGifts") or [],
                    uid_map,
                    stats,
                )

            # Final DB counts inside the transaction.
            log.info("=== RESULT COUNTERS (inserted / skipped-existing) ===")
            all_tables = sorted(
                set(stats.inserted) | set(stats.skipped_existing) | set(inv)
            )
            for table in all_tables:
                log.info(
                    "  %-28s inserted=%5d  skipped_existing=%5d  inventory=%5d",
                    table,
                    stats.inserted.get(table, 0),
                    stats.skipped_existing.get(table, 0),
                    inv.get(table, 0),
                )

            log.info("=== UID MAP (firebase_uid → uuid) ===")
            for fb, uid in sorted(uid_map.items()):
                log.info("  %s → %s", fb, uid)

            if stats.warnings:
                log.info("=== WARNINGS (%d) ===", len(stats.warnings))
                for w in stats.warnings:
                    log.info("  - %s", w)

            if commit:
                conn.execute("COMMIT")
                log.info("COMMITTED.")
                if passwords:
                    with PASSWORDS_FILE.open("a", encoding="utf-8") as pf:
                        pf.write(
                            f"# migrated {datetime.now(timezone.utc).isoformat()}\n"
                        )
                        for email, pwd in passwords:
                            pf.write(f"{email}:{pwd}\n")
                    log.info(
                        "Wrote %d temporary passwords to %s",
                        len(passwords),
                        PASSWORDS_FILE,
                    )
                if stats.unmapped["plants"] or stats.unmapped.get("notes") or stats.unmapped.get(
                    "outgoing_gifts"
                ):
                    with UNMAPPED_FILE.open("w", encoding="utf-8") as uf:
                        json.dump(stats.unmapped, uf, ensure_ascii=False, indent=2)
                    log.info("Wrote unmapped fields to %s", UNMAPPED_FILE)
            else:
                conn.execute("ROLLBACK")
                log.info(
                    "ROLLED BACK (dry-run). Re-run with --commit to persist. "
                    "Passwords NOT written."
                )
                if passwords:
                    log.info(
                        "Would create %d new user passwords (email list): %s",
                        len(passwords),
                        ", ".join(e for e, _ in passwords),
                    )
                unmapped_plants = len(stats.unmapped.get("plants") or {})
                log.info(
                    "Unmapped plant docs that would be saved to %s: %d",
                    UNMAPPED_FILE.name,
                    unmapped_plants,
                )
        except Exception:
            conn.execute("ROLLBACK")
            log.exception("Migration failed — rolled back")
            return 1

    return 0


def main(argv: list[str] | None = None) -> int:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description="Migrate users.json → Postgres")
    parser.add_argument(
        "--export",
        type=Path,
        default=DEFAULT_EXPORT,
        help=f"Path to users.json (default: {DEFAULT_EXPORT})",
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--dry-run",
        action="store_true",
        default=True,
        help="Run inside a transaction and ROLLBACK (default)",
    )
    group.add_argument(
        "--commit",
        action="store_true",
        help="Persist changes (writes migrated_users.txt)",
    )
    args = parser.parse_args(argv)

    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        log.error(
            "DATABASE_URL is required (do not rely on config defaults). "
            "Example: DATABASE_URL=postgresql://user:pass@host:5432/db"
        )
        return 1

    commit = bool(args.commit)
    return run(args.export, database_url, commit=commit)


if __name__ == "__main__":
    sys.exit(main())
