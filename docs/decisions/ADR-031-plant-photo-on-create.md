# ADR-031: First plant photo on create (and empty-gallery edit)

## Status

Accepted

## Context

Plant photos were added only from the plant details gallery (pick → 1:1 crop →
Storage upload). Creating a plant required saving first, opening details, then
uploading. Users wanted a photo at create time without a preview in the sheet.

## Decision

1. **Create sheet** — user may attach **one** photo (gallery/camera + existing
   crop page). The sheet shows only an icon/status, not the image. Upload runs
   after the plant document is created. Viewing remains on the plant details
   page.

2. **Update sheet** — the same attach control appears **only** when
   `Plant.galleryPhotos` is empty (no gallery images and no legacy cover). If
   the plant already has any photo, edit sheet does not add photos; details
   gallery stays the place for further photos.

3. Reuse pick/crop via `pickAndCropPlantPhoto` (also used by plant details).

## Implementation

- Helper: `lib/features/plants/widgets/common/pick_and_crop_plant_photo.dart`
- Icon control: `plant_pending_photo_control.dart`
- Sheets: `add_plant_sheet.dart`, `update_plant_sheet.dart` (conditional)
- Details: `pickAndUploadImage` calls the shared helper
- Upload: existing `StorageService.uploadPlantPhoto` + `PlantService.addPlantPhoto`

## Behavior

- Tapping the control again replaces the pending local bytes before save.
- If the plant is saved but upload fails, the sheet still closes and an upload
  error snackbar is shown so a second save does not create a duplicate plant.
- No image widget is shown in create/update sheets.

## Consequences

- Create remains limited to one first photo; extra photos stay on details.
- Update cannot replace an existing gallery from the edit sheet.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched files
- Device UI not run in this session
