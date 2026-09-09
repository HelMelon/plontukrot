# ADR-053: Fix plant photo crop infinite loading

## Status

Accepted

## Context

On plant create (and other pick→crop flows), the crop screen could show the
progress indicator forever after choosing a gallery/camera photo. Confirm
stayed disabled or spinning with no recovery.

Root cause: `crop_your_image` parses bytes with the Dart `image` package.
Camera/gallery sometimes yields HEIC or other formats that fail to decode
(or are mis-detected as PNG). The package's load path has no error callback,
so `CropStatus` never reaches `ready` and `progressIndicator` stays visible.

## Decision

1. Before opening `PlantImageCropPage`, re-encode picker bytes to PNG via
   Flutter's `instantiateImageCodec` (`normalizeImageBytesForCrop`).
2. If normalization fails, show a snackbar and abort — do not open the crop UI.
3. Push the crop route with `rootNavigator: true` and `fullscreenDialog: true`
   so it is not constrained by the create/edit bottom sheet.
4. On the crop page: enable confirm only after `CropStatus.ready`; cancel with
   an error snackbar if ready never arrives within 20 seconds.
5. Keep 1:1 crop with interactive pan/zoom and fixed crop rect.

## Implementation

- `pick_and_crop_plant_photo.dart` — normalize + root navigator push
- `plant_image_crop_page.dart` — ready gate, timeout, `initialRectBuilder`
- l10n: `plantCropLoadFailed` (ru/en/de/fr)

## Behavior

- Supported images open the crop editor after a short prepare step.
- Unsupported/corrupt images show an error and return to the previous sheet.
- Stuck loading after open self-dismisses after the timeout.

## Consequences

- Extra decode/encode before crop (CPU/memory), capped at ~1280px width.
- Formats Flutter cannot decode still fail, but with a clear error instead of
  an infinite spinner.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched Dart files
- Device UI not run in this session
