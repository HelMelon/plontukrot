# ADR-005: Plant leaf growth events

## Status

Accepted

## Context

Plant care already tracks watering, fertilizing, repotting, and propagation. Users also need growth activity metrics — especially new leaves over time under different conditions. Removals must update the on-screen leaf count without erasing growth history used for statistics, and record *why* a leaf left (cut for rooting, eaten, dried).

## Decision

1. **Separate events** under `users/{uid}/plants/{plantId}/growthEvents/{id}` with types `newLeaf`, `leafRemoved`, plus care types `watering`, `fertilizing`, `repotting`, `trimming`, `pinching`. Removals are new documents, not deletes of prior `newLeaf` rows. Care types are written when the corresponding care action succeeds; they are not shown in the vine/stats UI yet.

2. **Removal reason** on `leafRemoved`: optional field `reason` with values `cutForRooting`, `eaten`, `dried` (`LeafRemovalReason`). Legacy events without `reason` still count as removed. On `cutForRooting`, the app writes the removal first, then opens `AddPropagationSheet`; cancelling the sheet does not undo the removal.

3. **Baseline on Plant:** `initialLeafCount` (int, default `0`) stores how many leaves the plant already had before tracking. Changing it does not write growth events and does not affect monthly stats.

4. **Display count:** `initialLeafCount + count(newLeaf) − count(leafRemoved)`, clamped at `0`. Decrement is a no-op when the display count is already `0`.

5. **Statistics:** three calendar months starting from the current month (newest first). Each line shows **прибыло** (`newLeaf`) and **убыло** (`leafRemoved`) for that month. Care events and removal reasons do not change the monthly totals (reasons are not broken down in the UI).

6. **Retention:** each event stores `expiresAt = createdAt + 730 days`. Client `purgeExpired` runs when opening plant details. Plant delete also batch-deletes `growthEvents`.

7. **UI:** snake vine under the photo using `HugeIcons.strokeRoundedLeaf01` with `[−] count [+]`. Minus opens a reason chooser. Anchor under the counter scrolls to the growth stats block. Baseline is edited in `UpdatePlantSheet`.

## Implementation

- Models: `GrowthEvent`, `GrowthEventType`, `LeafRemovalReason`; `Plant.initialLeafCount`; `MonthlyLeafStat` with `newLeafCount` + `removedLeafCount`; helper `leafStatsByMonth`.
- Service: `GrowthEventService` (`watchGrowthEvents`, `addNewLeaf`, `removeLeaf(reason:)`, `purgeExpired`); `PlantService.updatePlant` / `addPlant` / `_deletePlantSubtree`.
- UI: vine/counter/stats; `leaf_removal_reason_sheet.dart`; wired in `plant_details_page.dart` and `plant_info_card.dart`.
- Localization: leaf counter, removal reasons, gained/lost stats strings.
- Tests: `test/growth_event_test.dart`.
- Layers unchanged: features → models/services.

## Behavior

- Setting initial leaf count to 5 shows 5 leaves and `прибыло 0, убыло 0` for each of the three months until `+` / `−` is used.
- Tapping `+` writes one `newLeaf` and increments the counter and the current-month «прибыло».
- Tapping `−` opens a chooser; each choice writes `leafRemoved` with `reason`. Current-month «убыло» increments. `cutForRooting` then opens the propagation sheet.
- Watering / fertilizing / repotting also append matching `growthEvents` (not displayed in leaf stats).
- Events older than 2 years are removed on the next details open via `purgeExpired`.

## Consequences

- Pros: growth stays measurable after cuts; reasons support rooting workflow; baseline does not pollute stats.
- Cons: client-only TTL; vine caps visible glyphs; no per-reason breakdown in monthly stats yet.
- Future types (e.g. flowering) can extend `GrowthEventType` without changing the collection path.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched files
- `flutter test test/growth_event_test.dart`
- Device UI not fully re-run in every session; risk: chooser + propagation sheet stacking on small screens
