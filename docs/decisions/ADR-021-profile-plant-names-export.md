# ADR-021: Profile plant names export

## Status

Accepted

## Context

Users need a way to export their plant display names (genus, species, cultivar, nickname) from the app, without care history or photos. A CLI tool already exists for the same field set; the profile should expose the same export for the signed-in user.

## Decision

Add an «Export plant names» action on the profile page that:

- loads the current user's active plants via `PlantService().getPlants()`;
- projects each plant to `genus`, `species`, `cultivar` (from `cultivarsDisplay`), and `nickname`;
- groups plants by growth stage (sorted ascending by stage order), with localized name in `stage` via `l10n.stageTitle` (no numeric stage id in the file);
- writes a dated JSON file to a temporary directory;
- opens the system share sheet (`share_plus`) with an in-memory `XFile.fromData` (no `path_provider` temp file — works on web and avoids MissingPluginException);

Empty collections show a snackbar and do not open share. Export uses the existing profile busy overlay.

The CLI tool `tools/export_plants.dart` uses the same grouping shape (English stage names: start/baby/juvenile/adult).

## Implementation

- UI: `ProfilePage` list tile after Friends
- Data: `PlantService` stream (separate subscription from the stats `StreamBuilder`)
- Localization: `profileExportPlants`, `profileExportPlantsEmpty`, `profileExportingPlants` (ru/en/de/fr)
- JSON shape: top-level `stages[]` with `{ stage, count, plants[] }` where `stage` is the display name
- Format aligned with `tools/export_plants.dart` field set (no watering/fertilizing data)

## Behavior

User opens Profile → taps export → receives a shareable `plants-names-YYYY-MM-dd.json` with metadata (`uid`, `exportedAt`, `fields`, `count`) and a `stages` array keyed by stage name. Within each stage, plants are sorted by species then nickname.

## Consequences

- In-app export does not require gcloud/CLI credentials.
- Share availability depends on the platform share sheet (same as WishLeafs).
- Archived plants are not included (same stream as the active collection).

## Verification

- `flutter analyze lib/features/profile/pages/profile_page.dart` — no issues
- Device share flow not run in this session
