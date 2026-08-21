# ADR-037: Reanimation completion date and status tracking

## Status

Accepted

## Context

Plant reanimation (`rerooting` manipulation type) is an ongoing process that begins on a specific date and ends when the plant develops a healthy root system and returns to active growth. Because the duration cannot be known in advance, users could not record when a reanimation concluded or differentiate between active reanimations and completed ones.

## Decision

1. **Explicit completion date (`endedAt`)**:
   - Extended `ManipulationEntry` and database schema (`plant_manipulations.ended_at`) with an optional `endedAt` timestamp.
   - When creating a reanimation entry, the date selector represents the start date (`appliedAt`).
   - The user can toggle «Реанимация завершена» and pick the end date (`endedAt`), either during creation or later via editing the manipulation entry in history.

2. **History and care status representation**:
   - `ManipulationsHistorySheet`:
     - In-progress reanimation (`endedAt == null`): displays start date + «В процессе».
     - Completed reanimation (`endedAt != null`): displays date range (e.g. `12 мая 2026 – 25 мая 2026`).
   - `PlantInfoCard`:
     - Displays the latest activity date (`endedAt ?? appliedAt`) and indicates in-progress state if reanimation is active.

3. **Backend CRUD support**:
   - Updated `ManipulationCreate`, `ManipulationUpdate`, and `ManipulationOut` schemas in FastAPI with `ended_at` support and camelCase aliases.
   - Added `PATCH /plants/{plant_id}/manipulations/{manipulation_id}` and `DELETE /plants/{plant_id}/manipulations/{manipulation_id}` endpoints.

## Implementation

- **Models**: `lib/models/manipulation_entry.dart` (`endedAt`, serialization to `endedAt` and `ended_at`).
- **Services**: `lib/services/manipulation_service.dart` (`addManipulation`, `updateManipulation` support `endedAt`, history sorted by latest event date).
- **UI**:
  - `lib/features/plants/widgets/sheets/add_manipulation_sheet.dart`: start date label for reanimation, «Реанимация завершена» checkbox and end date picker with date range validation.
  - `lib/features/plants/widgets/sheets/manipulations_history_sheet.dart`: subtitle formatted with date range or in-progress status.
  - `lib/features/plants/widgets/cards/plant_info_card.dart`: label incorporates in-progress state and effective care date.
- **Backend**:
  - `backend/schema.sql`: added `ended_at TIMESTAMPTZ` column.
  - `backend/app/schemas.py`: updated Pydantic schemas.
  - `backend/app/routers/plant_care.py`: added manipulation endpoints (GET, POST, PATCH, DELETE) with `ended_at`.
- **Localization**: Added keys in `app_ru.arb`, `app_en.arb`, `app_de.arb`, `app_fr.arb`.
- **Tests**: `test/manipulation_entry_test.dart`.

## Behavior

- On adding a reanimation manipulation, the user enters the start date and optional initial stage notes.
- If reanimation has finished, the user checks «Реанимация завершена» and selects the completion date (and optionally updates the new plant stage).
- In the manipulation history list, active reanimations are clearly marked as «В процессе», while completed ones show the full date range.

## Consequences

- Reanimation lifecycle is clearly visible to the user without guesswork.
- Full CRUD operations on manipulations are supported on both Flutter and FastAPI backend layers.

## Verification

- `flutter gen-l10n` executed cleanly.
- `flutter test` (all 68 unit/widget tests passed).
- `flutter analyze` completed with 0 errors in application code.
