# ADR-040: Plant archive and group members persistence

## Status

Accepted

## Context

When merging plants into a group (`mergePlants`) or archiving plants (died, sold, gifted), source plants are marked with `archived_at`, `expires_at`, `archive_reason`, `archive_note`, `merged_into_plant_id`, and `gifted_to_uid`. Additionally, group plants store their constituent cultivars in `members` (JSONB).

During the Firebase to FastAPI/PostgreSQL migration, these archive and group fields were missing in the PostgreSQL `plants` table schema, backend Pydantic schemas (`PlantCreate`, `PlantUpdate`, `PlantOut`), and router SQL queries. Consequently, when source plants were merged, the archive patch was ignored by the backend, leaving merged source plants in the active collection rather than moving them into the archive.

## Decision

1. **PostgreSQL Schema & Auto-migration**:
   - Added columns to `plants` table:
     - `members JSONB`
     - `archived_at TIMESTAMPTZ`
     - `expires_at TIMESTAMPTZ`
     - `archive_reason TEXT`
     - `archive_note TEXT`
     - `merged_into_plant_id TEXT`
     - `gifted_to_uid TEXT`
   - Added automatic `ALTER TABLE plants ADD COLUMN IF NOT EXISTS ...` migration in `auto_migrate()`.

2. **Backend Schemas & Router**:
   - Updated `PlantCreate`, `PlantUpdate`, and `PlantOut` models with archive fields and `members`.
   - Updated `_FIELDS` mapping and SQL `SELECT`, `INSERT`, `UPDATE` queries in `backend/app/routers/plants.py` to persist and return archive attributes and `members` (serialized as `JSONB`).

3. **Flutter Service & Model**:
   - `PlantService.addPlant` and `updatePlant` updated to forward `members` payload.
   - `Plant.fromMap` updated with explicit fallback handling for both snake_case and camelCase archive and member fields.

## Implementation

- `backend/schema.sql`: added archive and `members` column definitions to `plants` table.
- `backend/app/db.py`: added auto-migration for `members`, `archived_at`, `expires_at`, `archive_reason`, `archive_note`, `merged_into_plant_id`, `gifted_to_uid`.
- `backend/app/schemas.py`: updated `PlantCreate`, `PlantUpdate`, `PlantOut` schemas.
- `backend/app/routers/plants.py`: updated `_FIELDS`, `create_plant`, `update_plant`, `list_plants`, `get_plant`, and `_row_to_plant`.
- `lib/services/plant_service.dart`: forwarded `members` in `addPlant` and `updatePlant`.
- `lib/models/plant.dart`: updated `Plant.fromMap` for robust snake_case parsing of archive fields.
- `test/plant_photo_model_test.dart`: added unit tests for `Plant` archive and `members` deserialization.

## Behavior

- When 2–3 plants are merged into a group via home multi-select, the source plants are archived with reason `merged` and `mergedIntoPlantId` set to the new group ID.
- The source plants immediately disappear from the active plants list on the home screen and appear in the «Архив» page under the «Растения» tab.
- The new group plant is created with all constituent `members` (cultivars and variegation).

## Consequences

- Plant grouping, merging, and disposition (died / sold / merged) persist correctly to PostgreSQL.
- Active collection filters out archived plants as expected.

## Verification

- Backend Python code verified with `py_compile`.
- Flutter unit tests run: 71 tests passed with `flutter test`.
- Analyzer verified with `flutter analyze` (0 errors in touched files).
