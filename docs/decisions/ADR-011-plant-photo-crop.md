# ADR-011: Plant photo crop before upload

## Status

Accepted

## Context

Plant photos were picked via gallery/camera and uploaded to Firebase Storage without cropping. List cards and many detail layouts use a square (`1:1`) frame with `BoxFit.cover`, so uncropped photos were often framed poorly.

## Decision

1. After `ImagePicker.pickImage` on plant details, open a dedicated crop page before upload.
2. Use `crop_your_image` with a fixed **1:1** aspect ratio (aligned with grid cards; can be revisited later).
3. Crop page returns cropped `Uint8List` on confirm, or `null` on cancel/back — then upload is skipped.
4. `StorageService.uploadPlantImages` and Firestore `updatePlantImage` stay unchanged; they still receive final bytes only.
5. Interactive zoom/pan is enabled on the crop editor for better framing of large photos.

## Implementation

- Dependency: `crop_your_image` in `pubspec.yaml`.
- UI: `PlantImageCropPage` under `lib/features/plants/pages/`.
- Flow: `PlantDetailsPage.pickAndUploadImage` — pick → crop → upload.
- Copy: `plantCropTitle`, `plantCropConfirm`, `plantCropError` in l10n ARBs.

## Behavior

- User taps plant photo → chooses camera/gallery → crops to square → confirms → full + thumb upload as before.
- Back/cancel on crop screen leaves the existing plant image unchanged.

## Consequences

- Pros: better framing for square cards without changing storage paths or model fields.
- Cons: one extra screen in the upload flow; 1:1 may crop more aggressively than the wide details layout (`aspectRatio: 0.75`).

## Verification

- `flutter pub add crop_your_image`
- `flutter gen-l10n`
- `flutter analyze` on `plant_image_crop_page.dart` and `plant_details_page.dart` — no issues
- Device UI not run in this session
