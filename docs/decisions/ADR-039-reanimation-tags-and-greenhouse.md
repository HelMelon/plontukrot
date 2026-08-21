# ADR-039: Reanimation variety tags and greenhouse flag

## Status

Accepted

## Context

Plant reanimation (`rerooting` manipulation type) encompasses multiple distinct procedures and recovery conditions. Users need to categorize the specific actions taken during reanimation (such as rerooting, soil flushing, or rot trimming) and record whether the plant was placed into a mini-greenhouse/propagator environment.

## Decision

1. **Reanimation variety tags (`ReanimationTag`)**:
   - Introduced enum `ReanimationTag` with values:
     - `rerooting` (Переукоренение)
     - `soilFlush` (Промывка грунта)
     - `rotTrimming` (Обрезка гнили)
   - Stored on `ManipulationEntry` as `List<ReanimationTag> reanimationTags`.
   - Persisted in PostgreSQL `plant_manipulations.reanimation_tags` as `JSONB`.

2. **Greenhouse condition flag (`isGreenhouse`)**:
   - Added boolean field `isGreenhouse` (default `false`) to `ManipulationEntry`.
   - Persisted in PostgreSQL `plant_manipulations.is_greenhouse` as `BOOLEAN NOT NULL DEFAULT false`.

3. **UI & Accessibility**:
   - `AddManipulationSheet`:
     - Multi-select `FilterChip` tags under «Разновидности реанимации» for selecting any combination of reanimation procedures.
     - «Тепличка» checkbox (`CheckboxListTile`) for toggling greenhouse environment.
     - Full keyboard and screen reader accessibility support.
   - `ManipulationsHistorySheet`:
     - Title for reanimation entries displays the specific reanimation tags (e.g. «Переукоренение», «Переукоренение, Обрезка гнили») without the generic «Реанимация» label. If no tags were selected, it falls back to «Реанимация».
     - Subtitle displays date range / in-progress status, «Тепличка» flag, stage changes, and notes.
   - `PlantInfoCard`:
     - Displays complete reanimation details in the care manipulations card: dates/range (or in-progress status), variety tags, greenhouse flag, stage change, and notes.

## Implementation

- **Models**:
  - `lib/models/reanimation_tag.dart`: enum with serialization codes and parsing helpers.
  - `lib/models/manipulation_entry.dart`: added `reanimationTags` and `isGreenhouse` with camelCase and snake_case parsing/serialization.
- **Services**:
  - `lib/services/manipulation_service.dart`: updated `addManipulation`, `addManipulations`, and `updateManipulation` to forward tags and greenhouse parameters.
- **UI**:
  - `lib/features/plants/widgets/sheets/add_manipulation_sheet.dart`: added tag chips and greenhouse checkbox in `_buildRerootingFields`.
  - `lib/features/plants/widgets/sheets/manipulations_history_sheet.dart`: updated `_titleForEntry` to output reanimation variety names without the generic label, and `_subtitleForEntry` for greenhouse status and dates.
  - `lib/features/plants/widgets/cards/plant_info_card.dart`: updated `manipulationLabel` to format all reanimation details (date range, in-progress state, varieties, greenhouse, stage transitions, notes).
- **Backend**:
  - `backend/schema.sql`: added `reanimation_tags JSONB` and `is_greenhouse BOOLEAN NOT NULL DEFAULT false` to `plant_manipulations`.
  - `backend/app/schemas.py`: updated `ManipulationCreate`, `ManipulationUpdate`, and `ManipulationOut` Pydantic models.
  - `backend/app/routers/plant_care.py`: updated query execution and `jsonb` serialization for manipulations.
- **Localization**:
  - Added strings to `app_ru.arb`, `app_en.arb`, `app_de.arb`, `app_fr.arb`.
  - Added `reanimationTagLabel` extension helper in `lib/core/l10n/app_localizations_x.dart`.
- **Tests**:
  - Added unit tests in `test/manipulation_entry_test.dart` for `ReanimationTag` parsing and `ManipulationEntry` serialization.

## Behavior

- When creating or editing a reanimation manipulation, the user can select one or more procedure tags (Переукоренение, Промывка грунта, Обрезка гнили) and mark whether a greenhouse was used.
- In manipulation history, each reanimation card displays the specific variety as the title (e.g. `Переукоренение, Обрезка гнили`) and date/greenhouse/notes in the subtitle (e.g. `21 авг. 2026 г. · В процессе · Тепличка`).
- On the plant details page (`PlantInfoCard`), the manipulations care card displays the complete reanimation details (e.g. `21 авг. 2026 г. · В процессе · Переукоренение, Промывка грунта · Тепличка`).

## Consequences

- Reanimation records provide complete diagnostic information about the recovery steps taken.
- Future reanimation tags or manipulation categories can easily be extended following the same pattern.

## Verification

- `flutter gen-l10n` generated updated localization classes.
- `flutter analyze` completed with 0 errors.
- `flutter test` passed with all 69 unit/widget tests passing.
