# ADR-032: Plant manipulations journal

## Status

Accepted

## Context

Users track watering, fertilizing, and repotting per plant. They also need a journal for other care actions: pinching, plant reanimation (rerooting after root loss — not propagation), and stimulator applications. These entries must support add, edit, and delete in history. Stimulators should reuse a user catalog (like fertilizers) with optional default dosage.

Existing `growthEvents` includes a `pinching` type but is append-only, has no CRUD UI, and uses a 730-day TTL — unsuitable as the primary store for this feature.

## Decision

1. **Plant-level subcollection** `users/{uid}/plants/{plantId}/manipulations/{id}` with unified entries distinguished by `type`: `pinching`, `rerooting`, `stimulator`.

2. **Rerooting = reanimation**, not propagation. No link to `propagations` or `AddPropagationSheet`. Optional `stageBefore` (snapshot on create) and `stageAfter`; when `stageAfter` is set on save, update `plants/{plantId}.stage`.

3. **Stimulator catalog** at `users/{uid}/stimulators/{id}` (`name`, optional `defaultDosage`). History stores denormalized `stimulatorName` (+ optional `stimulatorId`, `dosage`).

4. **Denormalized** `lastManipulationAt` on the plant document, synced on add/update/delete (like `lastWateredAt`).

5. **Do not sync** manipulations to `growthEvents` in MVP (avoids edit/delete drift).

6. **UI:** one row «Манипуляции» in `PlantInfoCard` care block → `ManipulationsHistorySheet` → `AddManipulationSheet`; stimulator catalog via `ManageStimulatorsSheet`.

## Implementation

- Models: `ManipulationType`, `ManipulationEntry`, `Stimulator`; `Plant.lastManipulationAt`.
- Services: `ManipulationService`, `StimulatorService`; `PlantService._deletePlantSubtree` deletes `manipulations`.
- UI sheets under `lib/features/plants/widgets/sheets/`.
- l10n: Russian primary; `manipulationTypeRerooting` labeled «Реанимация».
- Tests: `test/manipulation_entry_test.dart`.

## Behavior

- **Pinching:** date + optional note.
- **Rerooting (reanimation):** date + note; optional new stage updates plant; history shows «стадия X → Y» when both stages stored.
- **Stimulator:** pick from catalog or enter name manually; optional dosage; date + note.
- Delete rerooting entry does **not** roll back `plant.stage`.
- Plant delete removes all manipulation documents.

## Consequences

- Pros: consistent with existing care history pattern; full CRUD; stimulator catalog reuse; clear separation from propagation.
- Cons: no link to leaf counter or growth analytics yet; AppBar on plant details has no quick action (InfoCard only).
- Future: optional mirror pinching to `growthEvents`; type filters in history; reminders.

## Verification

- `flutter gen-l10n`
- `flutter analyze`
- `flutter test test/manipulation_entry_test.dart`
- Manual UI checklist not run on device in this session; layout follows existing history sheets.
