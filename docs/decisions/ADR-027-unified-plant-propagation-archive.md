# ADR-027: Unified plant and propagation archive

## Status

Accepted

## Context

Archived plants lived on `PlantArchivePage` (Home → Archive). Archived propagation batches lived on a second tab of `PropagationsPage`. Users expected one archive place for both finished plants and finished propagation batches.

## Decision

1. **Single archive hub:** `PlantArchivePage` (Home → Archive) with two tabs: **Plants** and **Propagations**.
2. **Plants tab:** unchanged — `PlantService.watchArchivedPlants()`, details → `PlantDetailsPage`, purge expired plant archives on open.
3. **Propagations tab:** `PropagationService.watchArchivedPropagations()`; tap opens `PropagationDetailsSheet`. Parent labels resolve from active + archived plants.
4. **`PropagationsPage`:** active list + year stats only (stats still include archived batches for yearly totals). Archive tab removed.
5. **No data-model merge:** plants keep 730-day retention; propagations keep status-based archive and 365-day visibility. Firestore collections stay separate.

## Implementation

- UI: `plant_archive_page.dart` (TabBar), `propagations_page.dart` (no archive tab)
- l10n: `plantArchivePlantsTab`, `plantArchivePropagationsTab`; title shortened to «Архив» / Archive

## Behavior

- Home → Archive → Растения | Размножение.
- Propagation hub shows only active batches; finished ones appear under Archive → Размножение.

## Consequences

- Pros: one discoverable archive; less duplicate chrome.
- Cons: propagation archive is one more tap from the propagation hub (intentional).

## Verification

- `flutter gen-l10n`
- `flutter analyze` on archive and propagations pages
