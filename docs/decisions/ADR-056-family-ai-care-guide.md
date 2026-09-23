# ADR-056: Family AI Care Guide Pages

## Status

Accepted

## Context

Users already have genus reference pages with AI care guides (`PlantGenusDetailsPage`, ADR-043/044/046). Botanical family (`plantFamily`) is shown on plant details but was plain text with no reference surface. Users need the same AI overview for families, while listing collection plants in a bottom sheet rather than an inline grid (families are broader and collections can be large).

## Decision

1. **Backend contract**
   - `GET /families/{family}/care-guide?locale=` returns structured JSON (`family`, `origin`, `light`, `watering`, `fertilizing`, `soil`, `humidity`, `toxicity`, `min_temp_c`).
   - `POST /families/{family}/care-guide/refresh` forces regeneration.
   - Guides are cached in PostgreSQL table `family_care_guides` keyed by `(family, locale)`.
   - AI generation reuses the provider chain in `ai_care.py` with family-specific prompts (`generate_family_care_guide`).
   - Access is gated by the existing `genus_care` feature flag (no separate `family_care` flag).

2. **Flutter client**
   - Model `FamilyCareGuide`, service `FamilyCareService` (`/families/...`), offline disk cache `FamilyCareDiskCache`.
   - Page `PlantFamilyDetailsPage`: AI card + button «Растения семейства».
   - Plants open via `showFamilyPlantsSheet` / `FamilyPlantsSheet` (grid of `PlantCard` filtered by `plantFamily`).
   - Plant details botanical row: family name is a tappable link to the family page (same pattern as genus).

3. **Localization**
   - Family-specific title/badge/a11y/empty/button strings; care section labels reuse `genusCareLight` and siblings.

## Implementation

- Backend: `routers/families.py`, `FamilyCareGuideOut`, `family_care_guides` table in `db.py` / `schema.sql`, family prompts in `ai_care.py`.
- Models/services: `family_care_guide.dart`, `family_care_service.dart`, `family_care_disk_cache.dart`.
- UI: `plant_family_details_page.dart`, `family_care_guide_card.dart`, `family_plants_sheet.dart`, link in `plant_info_card.dart`.
- Startup warms family disk cache alongside genus cache in `main.dart`.
- Tests: `family_care_guide_test.dart`, `family_care_disk_cache_test.dart`.

## Behavior

- Tap family on plant details → family page with AI care card (when `genus_care` is enabled).
- Tap «Растения семейства» → bottom sheet with collection plants of that family (or empty-state copy).
- Offline: last successful guide is served from disk/memory cache.

## Consequences

- Family and genus care share one feature flag and the same care-field schema.
- Family care advice is broader than genus advice; prompts ask for family-level guidance.
- Friend plant details still show family as plain text (unchanged).

## Verification

- `flutter gen-l10n`
- `flutter analyze` on touched Dart files — no issues
- `flutter test` for family care model and disk cache — passed
- Device UI flow not run in this session
