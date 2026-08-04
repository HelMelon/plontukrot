# ADR-006: Bulk repotting from home selection

## Status

Accepted

## Context

Home selection mode already supports mass watering and fertilizing. Users also need to record the same soil mix and date for several plants at once without opening each plant’s details.

## Decision

1. **Selection AppBar** exposes a repotting action (same icon as plant details / history) next to fertilizing.
2. **Reuse `AddRepottingSheet`** with `plantIds` / `plants` / `title`, matching the fertilizing sheet API. Single-plant and edit flows use `.forPlant` / `.edit`.
3. **Bulk write** goes through `RepottingService.addRepottings`: Firestore batches (chunks of 200), shared soil/components/date/slow-release flag, denormalized `lastRepottedAt` from in-memory plants (no plant doc reads), then one `growthEvents` repotting entry per plant.
4. **UI copy** uses `homeRepotting` / `homeRepotSelectedTitle` (RU/EN/DE/FR). On success the home page exits selection mode.

## Implementation

- Service: `RepottingService.addRepottings`; optional `skipPlantFetch` on single `addRepotting`.
- UI: `AddRepottingSheet` multi-plant API; home `_showRepottingSheet` + selection IconButton.
- Localization: ARB keys above.
- Layers unchanged: features → models/services.

## Behavior

- Select plants on home → tap repotting → sheet with shared date/soil → save creates a repotting history entry (and growth event) for each selected plant.
- Single-plant add/edit from details or history is unchanged.

## Consequences

- Bulk repotting follows the same pattern as fertilizing; future care bulk actions can reuse the same selection + sheet shape.
- Growth events are written sequentially after each batch commit (same as other care bulk paths that append growth events).

## Verification

- `flutter gen-l10n`
- `flutter analyze` on home page, add-repotting sheet, and repotting service: no issues
- Device UI not run in this session; risk: layout of repotting sheet with many selected plants (title only; plant list not shown in sheet)
