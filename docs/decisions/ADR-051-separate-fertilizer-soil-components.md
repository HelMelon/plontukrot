# ADR-051: Separate fertilizer and soil component catalogs

## Status

Accepted

## Context

After the Firebase → FastAPI migration (ADR-033), soil components and
fertilizer ingredients temporarily shared one `components` catalog for v1
simplicity. Default soil ingredients (vermiculite, coco coir, perlite, etc.)
therefore appeared in fertilizing mix builders, making fertilizer recipes
unusable.

The Postgres schema already had a separate `fertilizer_components` table and
the migrator already copied Firebase `fertilizerComponents` into it, but no
API routed to that table.

## Decision

Keep two distinct per-user catalogs:

- `components` via `/components` — soil / substrate ingredients
- `fertilizer_components` via `/fertilizer-components` — fertilizer mix
  ingredients

`ComponentService` continues to use `/components`.
`FertilizeService` ingredient CRUD uses `/fertilizer-components` only.

No default fertilizer ingredients are seeded; users add NPK / products as
needed. Soil defaults remain only on the soil side.

## Implementation

- Backend `catalogs` router: full list/create/update/delete for
  `/fertilizer-components`; PATCH also added for `/components` (client already
  called it).
- Flutter `FertilizeService`: all ingredient endpoints switched to
  `/fertilizer-components`.
- Finance “also add to fertilizer catalog” continues to call
  `ensureIngredient`, which now writes to the correct table.

## Behavior

- Repotting / soil composition pickers show soil components only.
- Fertilizing mix / manage-ingredients sheets show fertilizer ingredients only.
- Users who already had `fertilizerComponents` migrated from Firebase see those
  names again once the new API is deployed.
- Names that were incorrectly created under shared `/components` after migration
  stay in the soil catalog and are not auto-moved; they can be re-added under
  fertilizer ingredients if needed.

## Consequences

- Fertilizer mixes can be built without substrate noise.
- Slightly more API surface than the shared-catalog v1 approach.
- No automatic cleanup of soil-catalog rows that users may have treated as
  fertilizer ingredients during the shared period.

## Verification

- `python -m py_compile backend/app/routers/catalogs.py`
- `flutter analyze lib/services/fertilize_service.dart`
- Device UI not run in this change set
