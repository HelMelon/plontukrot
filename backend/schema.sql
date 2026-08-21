-- plontukrot backend schema (PostgreSQL)
-- Mirrors the Firebase data model exported to users.json.
-- Photos are stored as URLs (either S3 or public); files live on disk / S3.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================= GLOBAL =============================
-- Shared botanical catalog (was Firestore collection `plantSpecies`).
CREATE TABLE IF NOT EXISTS plant_species (
    id          TEXT PRIMARY KEY,           -- species normalized / slug
    species     TEXT NOT NULL,
    genus       TEXT,
    plant_family TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================= AUTH / USERS =======================
-- Replaces Firestore `users/{uid}` profile.
CREATE TABLE IF NOT EXISTS users (
    id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid          TEXT UNIQUE,       -- kept from migration, nullable
    email                 TEXT UNIQUE NOT NULL,
    password_hash         TEXT NOT NULL,
    name                  TEXT,
    locale_code           TEXT DEFAULT 'ru',
    currency_code         TEXT DEFAULT 'BYN',
    collection_visibility TEXT DEFAULT 'friends',
    personal_data_consent_at TIMESTAMPTZ,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================= PLANTS =============================
CREATE TABLE IF NOT EXISTS plants (
    id                       TEXT PRIMARY KEY,   -- keep Firestore doc id
    user_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    genus                    TEXT,
    species                  TEXT,
    cultivar                 TEXT,
    trading_name             TEXT,
    plant_family             TEXT,
    nickname                 TEXT,
    stage                    INT NOT NULL DEFAULT 0,
    variegation              INT,                 -- enum; see model
    watering_frequency       INT,                 -- days, nullable
    fertilizing_frequency_days INT,
    initial_leaf_count       INT NOT NULL DEFAULT 0,
    last_watered_at          TIMESTAMPTZ,
    last_fertilized_at       TIMESTAMPTZ,
    last_repotted_at         TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Photos: gallery images. `is_legacy` flags the single legacy cover.
CREATE TABLE IF NOT EXISTS plant_photos (
    id            TEXT PRIMARY KEY,
    plant_id      TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    image_url     TEXT NOT NULL,
    image_thumb_url TEXT,
    added_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_legacy     BOOLEAN NOT NULL DEFAULT false
);

-- Plant notes (was plants/{id}/notes).
CREATE TABLE IF NOT EXISTS plant_notes (
    id          TEXT PRIMARY KEY,
    plant_id    TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    text        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ
);

-- Plant growth events (plants/{id}/growthEvents).
CREATE TABLE IF NOT EXISTS plant_growth_events (
    id          TEXT PRIMARY KEY,
    plant_id    TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    type        INT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ
);

-- Watering history (plants/{id}/watering).
CREATE TABLE IF NOT EXISTS plant_waterings (
    id           TEXT PRIMARY KEY,
    plant_id     TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    watered_at   TIMESTAMPTZ,
    next_watering TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Fertilizing history (plants/{id}/fertilizing).
CREATE TABLE IF NOT EXISTS plant_fertilizings (
    id                 TEXT PRIMARY KEY,
    plant_id           TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    fertilizer_id      TEXT,
    fertilizer_name    TEXT,
    application_method TEXT,
    components         JSONB,
    water_ml           INT,
    applied_at         TIMESTAMPTZ NOT NULL,
    next_fertilizing   TIMESTAMPTZ,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Repotting history (plants/{id}/repotting).
CREATE TABLE IF NOT EXISTS plant_repottings (
    id                      TEXT PRIMARY KEY,
    plant_id                TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    soil_id                 TEXT,
    soil_name               TEXT,
    components              JSONB,
    slow_release_fertilizer BOOLEAN NOT NULL DEFAULT false,
    repotted_at             TIMESTAMPTZ NOT NULL,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Manipulations (plants/{id}/manipulations).
CREATE TABLE IF NOT EXISTS plant_manipulations (
    id            TEXT PRIMARY KEY,
    plant_id      TEXT NOT NULL REFERENCES plants(id) ON DELETE CASCADE,
    type          INT NOT NULL,
    applied_at    TIMESTAMPTZ NOT NULL,
    ended_at      TIMESTAMPTZ,
    note          TEXT,
    stage_before  INT,
    stage_after   INT,
    stimulator_id TEXT,
    stimulator_name TEXT,
    dosage        TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================= PROPAGATIONS =============================
CREATE TABLE IF NOT EXISTS propagations (
    id                   TEXT PRIMARY KEY,
    user_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_plant_id      TEXT,
    parent_plant_name    TEXT,
    parent_plant_family  TEXT,
    method               INT NOT NULL DEFAULT 0,
    stage                INT NOT NULL DEFAULT 0,
    status               INT NOT NULL DEFAULT 0,
    quantity             INT NOT NULL DEFAULT 0,
    quantity_alive       INT NOT NULL DEFAULT 0,
    gifted_quantity      INT NOT NULL DEFAULT 0,
    sold_quantity        INT NOT NULL DEFAULT 0,
    traded_quantity      INT NOT NULL DEFAULT 0,
    lost_quantity        INT NOT NULL DEFAULT 0,
    started_at           TIMESTAMPTZ NOT NULL,
    sold_at              TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS propagation_notes (
    id          TEXT PRIMARY KEY,
    propagation_id TEXT NOT NULL REFERENCES propagations(id) ON DELETE CASCADE,
    text        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at  TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS propagation_stage_history (
    id              TEXT PRIMARY KEY,
    propagation_id  TEXT NOT NULL REFERENCES propagations(id) ON DELETE CASCADE,
    stage           INT NOT NULL,
    quantity_alive  INT NOT NULL DEFAULT 0,
    outcome         TEXT,
    note            TEXT,
    changed_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================= CATALOGS (per-user) =============================
CREATE TABLE IF NOT EXISTS fertilizers (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    kind        INT NOT NULL DEFAULT 0,
    water_ml    INT NOT NULL DEFAULT 0,
    components  JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fertilizer_components (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS stimulators (
    id            TEXT PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name          TEXT NOT NULL,
    default_dosage TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS soils (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    components  JSONB,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS components (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS wish_list_items (
    id          TEXT PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name_en     TEXT NOT NULL,
    name_alt    TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS finance_entries (
    id                TEXT PRIMARY KEY,
    user_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title             TEXT NOT NULL,
    amount            NUMERIC(12,2) NOT NULL,
    type              INT NOT NULL DEFAULT 0,
    source            TEXT,
    date              TIMESTAMPTZ NOT NULL,
    wish_list_item_id TEXT,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================= SOCIAL =============================
CREATE TABLE IF NOT EXISTS friends (
    id          TEXT PRIMARY KEY,
    user_a      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_a, user_b)
);

CREATE TABLE IF NOT EXISTS friend_requests (
    id                TEXT PRIMARY KEY,
    from_uid          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_uid            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_display_name TEXT,
    from_photo_url    TEXT,
    status            INT NOT NULL DEFAULT 0,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS incoming_gifts (
    id               TEXT PRIMARY KEY,
    to_uid           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_uid         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_display_name TEXT,
    from_plant_id    TEXT,
    plant_snapshot   JSONB,
    status           INT NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS outgoing_gifts (
    id               TEXT PRIMARY KEY,
    from_uid         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    to_uid           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    from_display_name TEXT,
    from_plant_id    TEXT,
    plant_snapshot   JSONB,
    status           INT NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
