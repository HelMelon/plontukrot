# ADR-020: Plant photo load fallback and image tests

## Status

Accepted

## Context

Plant photos were failing silently in lists and details: `CachedNetworkImage` errors mapped to the same placeholder as “no photo”. Lists prefer thumb URLs (`listImageUrl`); a broken thumb with a valid full URL still looked empty. There were no automated tests around photo models or card wiring. Full Firebase Emulator E2E was out of scope for this change.

## Decision

1. Introduce `PlantNetworkImage` — primary URL with optional fallback (thumb → full on lists; full → thumb on gallery), debug logging of load failures.
2. Use it in Home cards, details gallery, search, archive, and friend plant details.
3. Keep Storage download-URL loading (no SDK read path rewrite).
4. Add unit tests for `Plant.listImageUrl` / `galleryPhotos` / `PlantPhoto.fromMap` and a widget test for `PlantCard` image wiring.
5. Re-confirm Storage rules deploy and apply bucket CORS from repo `cors.json`.

## Implementation

- Widget: `lib/features/plants/widgets/common/plant_network_image.dart`
- Call sites: `plant_card.dart`, `plant_image_card.dart`, `plant_search_delegate.dart`, `plant_archive_page.dart`, `friend_plant_details_page.dart`
- Tests: `test/plant_photo_model_test.dart`, `test/plant_card_image_test.dart`
- Docs: `docs/development/testing.md`

## Behavior

- List thumb fails → retry full cover URL once → then placeholder.
- Gallery full fails → retry thumb once → then placeholder.
- Debug builds print failed URL + error to the console.
- Missing Storage objects (404) still show placeholder; fallback cannot invent files.

## Consequences

- Pros: fewer false “empty” photos; diagnosable failures; regression coverage without Firebase.
- Cons: not a full E2E suite; CORS/ops must stay applied on the bucket for web.

## Verification

- `flutter test test/plant_photo_model_test.dart test/plant_card_image_test.dart` — passed
- `flutter analyze` on touched files
- `firebase deploy --only storage` — rules already up to date
- `gsutil cors set cors.json` on `gs://plant-logger-e0677.firebasestorage.app`
