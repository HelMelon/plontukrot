# ADR-010: Plant groups, plant archive, and disposition

## Status

Accepted

## Context

Users sometimes grow up to three cultivars in one pot and need a single collection card for that group. Separately, removing a plant from the active collection must preserve history for two years (death note or sale income) rather than hard-deleting from the plant details screen. Propagation already had a 365-day archive; plants had none.

## Decision

1. **Group plants** are regular `Plant` documents with `members` (2–3 `PlantMember` entries: cultivar, variegation, optional `sourcePlantId`). `isGroup` is `members.length >= 2`. Single plants keep top-level `cultivar` / `variegation`.

2. **Merge** from home multi-select: only **2–3** plants with the **same genus**. Opens `MergePlantSheet` prefilled with genus and, when shared, species and plant family. Member cultivars start from sources and remain editable; nickname, trading name, and stage are filled manually. On save, sources are archived with reason `merged` and `mergedIntoPlantId`, and one new group plant is created.

3. **Home filter «Группы»** shows only `isGroup` plants (same chip pattern as «Размножение»).

4. **Plant archive** fields: `archivedAt`, `expiresAt` (= archivedAt + **730 days**), `archiveReason` (`merged` | `died` | `sold`), optional `archiveNote`, optional `mergedIntoPlantId`. Active lists exclude archived plants. Visible archive hides expired items; opening the archive page runs `purgeExpiredArchived` (hard-delete subtree). UI hub is shared with archived propagations (see ADR-027).

5. **Disposition from plant details** via `ArchivePlantSheet`:
   - **Died** — required cause text → `archiveNote` + journal note, then archive.
   - **Sold** — amount (+ optional note) → `FinanceEntry` income with `source: plantSale` and `plantId`, then archive.
   - Button hidden when already archived.

6. **Hard delete** from home multi-select remains unchanged.

## Implementation

- Models: `plant_member.dart`, `plant_archive_reason.dart`; extended `Plant`, `FinanceEntry` (`plantSale`, `plantId`).
- Service: `PlantService` — filter active plants, `mergePlants`, `archivePlant`, `watchArchivedPlants`, `purgeExpiredArchived`, `updatePlant(members:)`.
- UI: `MergePlantSheet`, `ArchivePlantSheet`, `PlantArchivePage`; home merge action + groups filter + archive nav; details dispose action; group-aware card/info/search/update.

## Behavior

- Selecting two Hoya of the same genus → Merge → form with genus/species/family and two cultivar slots → save → sources disappear from home into archive; new group appears and is listed under «Группы».
- Disposing as sold writes an income line on Finances and moves the plant to archive for two years.
- Disposing as died requires a cause text kept on the plant document (and as a note).

## Consequences

- Pros: multi-cultivar pots without separate entities; soft archive aligned with finances; no architectural layers added.
- Cons: Firestore `orderBy(archivedAt)` / `expiresAt` queries only cover docs with those fields; group plants do not copy care history from sources; bulk home delete still permanently destroys data.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on changed model/service/UI files — no issues
- Device UI not run in this session
