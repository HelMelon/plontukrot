# ADR-005: Plant leaf growth events

## Status

Accepted

## Context

Plant care already tracks watering, fertilizing, repotting, and propagation. Users also need growth activity metrics — especially new leaves over time under different conditions. Removals (cut leaves) must update the on-screen leaf count without erasing growth history used for statistics.

## Decision

1. **Separate events** under `users/{uid}/plants/{plantId}/growthEvents/{id}` with types `newLeaf`, `leafRemoved`, plus care types `watering`, `fertilizing`, `repotting`, `trimming`, `pinching`. Removals are new documents, not deletes of prior `newLeaf` rows. Care types are written when the corresponding care action succeeds; they are not shown in the vine/stats UI yet.

2. **Baseline on Plant:** `initialLeafCount` (int, default `0`) stores how many leaves the plant already had before tracking. Changing it does not write growth events and does not affect the 3-month growth statistic.

3. **Display count:** `initialLeafCount + count(newLeaf) − count(leafRemoved)`, clamped at `0`. Decrement controls are no-ops when the display count is already `0`.

4. **Statistics:** three calendar months starting from the current month (newest first). Each line counts only `newLeaf` events whose `createdAt` falls in that month. Removals and care events do not affect these counts.

5. **Retention:** each event stores `expiresAt = createdAt + 730 days`. Client `purgeExpired` runs when opening plant details. Plant delete also batch-deletes `growthEvents`.

6. **UI:** snake vine under the photo using `HugeIcons.strokeRoundedLeaf01` (max 8 leaves per row, alternating above/below, wrap downward L→R / R→L) with `[−] count [+]`. Anchor under the counter scrolls to a growth stats block below botanical data. Baseline is edited in `UpdatePlantSheet`.

## Implementation

- Models: `GrowthEvent`, `GrowthEventType`; `Plant.initialLeafCount`.
- Service: `GrowthEventService` (`watchGrowthEvents`, `addNewLeaf`, `removeLeaf`, `purgeExpired`); `PlantService.updatePlant` / `addPlant` / `_deletePlantSubtree`.
- UI: `plant_vine_painter.dart`, `plant_leaf_counter.dart`, `plant_growth_stats_section.dart`; wired in `plant_details_page.dart` and `plant_info_card.dart`.
- Localization: leaf counter, stats, and initial-count strings in ARB files.
- Tests: `test/growth_event_test.dart` for display and stats formulas.
- Layers unchanged: features → models/services (no repositories/use cases).

## Behavior

- Setting initial leaf count to 5 in edit sheet shows 5 leaves on the vine and `0` for each of the three month lines until `+` is used.
- Tapping `+` writes one `newLeaf` (timestamp now) and increments the counter and the current-month stats line.
- Tapping `−` writes one `leafRemoved` when count > 0; monthly new-leaf stats stay unchanged.
- Watering / fertilizing / repotting writes also append matching `growthEvents` (not displayed yet). Trimming/pinching helpers exist on `GrowthEventService` for future UI.
- Events older than 2 years are removed on the next details open via `purgeExpired`.

## Consequences

- Pros: growth activity stays measurable after cuts; baseline does not pollute stats; matches existing subcollection patterns.
- Cons: client-only TTL (no Cloud Functions / Firestore TTL); vine strip caps visible leaf glyphs at 24; no monthly charts yet.
- Future types (e.g. flowering) can extend `GrowthEventType` without changing the collection path.

## Verification

- `flutter analyze lib` — no issues.
- `flutter test test/growth_event_test.dart` — all 5 tests passed.
- Device/UI manual run not performed in this session; layout risks: horizontal vine density at high leaf counts, wide vs narrow column width.
