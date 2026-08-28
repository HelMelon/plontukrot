# ADR-043: Botanical Overview and Genus AI Care Guide

## Status

Accepted

## Context

Users want quick botanical and care guidance (origin, watering, fertilizing, lighting, soil, humidity, toxicity) when viewing plants belonging to a specific genus (`PlantGenusDetailsPage`).
Directly querying LLMs from the mobile client has several drawbacks: API key exposure in client binaries, repeated token costs, higher latency for common genera, and potential regional API blocks.
Centralizing generation on the backend with database caching allows all users to share care guides instantly with zero redundant AI token expenditure.

## Decision

1. **Backend Contract**:
   - Endpoint `GET /genera/{genus}/care-guide` returning structured JSON containing botanical overview (`origin`) and care requirements (`light`, `watering`, `fertilizing`, `soil`, `humidity`, `toxicity`).
   - The backend checks existing cached records first and falls back to LLM JSON generation when a genus is requested for the first time.

2. **Domain Model (`GenusCareGuide`)**:
   - Resides in `lib/models/genus_care_guide.dart`.
   - Handles structured fields with empty checks and serialization helpers.

3. **Service Layer (`GenusCareService`)**:
   - Resides in `lib/services/genus_care_service.dart`.
   - Communicates with `ApiClient` and maintains an in-memory session cache to avoid repeated HTTP calls during app navigation.

4. **UI Card & Genus Details (`GenusCareGuideCard` & `PlantGenusDetailsPage`)**:
   - Located at `lib/features/plants/widgets/cards/genus_care_guide_card.dart` and `lib/features/plants/pages/plant_genus_details_page.dart`.
   - Integrated into `PlantGenusDetailsPage` via `CustomScrollView` (scrolling seamlessly above the plant cards grid).
   - Features collapsible care chips with high-contrast semantics, loading indicators (`AccessibleProgressIndicator`), retry capabilities, and strict theme token adherence (`AppTheme`, `context.colors`, `context.spacing`, `context.typography`, `context.icons`).

## Implementation

- **Models**: `lib/models/genus_care_guide.dart`.
- **Services**: `lib/services/genus_care_service.dart`.
- **UI & Widgets**:
  - `lib/features/plants/widgets/cards/genus_care_guide_card.dart`
  - `lib/features/plants/pages/plant_genus_details_page.dart`
- **Theme Tokens**:
  - `lib/core/theme/tokens/app_icon_tokens.dart` (added `light`, `humidity`, `toxicity`, `aiCare`).
- **Localization**:
  - `lib/l10n/app_ru.arb`, `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_fr.arb` and corresponding Dart localization files.

## Behavior

- Opening a genus page fetches the care guide for that genus.
- An informational card displays at the top of the page with the genus origin and key care parameters (light, watering, soil, fertilizing, humidity, and animal toxicity warnings).
- The user can expand or collapse the care details.
- If the guide is loading or fails due to network, accessible indicators and retry options are displayed without obstructing the plant cards collection.

## Consequences

- Zero client-side API key management or LLM token overhead.
- Cached genus information is shared among all app users.
- Clean integration with existing theme tokens, typography, and accessibility conventions.

## Verification

- Created `test/genus_care_guide_test.dart` validating serialization and model invariants.
- Inspected all touched files for lint, type safety, theme token adherence, and localized string completeness across all 4 supported locales (RU, EN, DE, FR).
