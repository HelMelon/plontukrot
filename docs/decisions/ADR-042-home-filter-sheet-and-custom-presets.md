# ADR-042: Home Filter Sheet and Custom Presets

## Status

Accepted

## Context

On the main collection screen, filtering options were previously rendered as multiple rows of `FilterChip` widgets directly in the main layout (status chips, family chips, genus chips, and stage chips). As a collection grew with multiple botanical families, genera, and stages, these chips consumed significant vertical and horizontal screen real estate and pushed plant cards below the fold. Users also lacked the ability to save frequently used filter combinations (e.g. "My Monsteras in Propagation").

## Decision

1. Consolidate home plant filters into a single compact button in the top action bar with an active filter badge counter (`homeFilterActiveBadge`).
2. Implement a dedicated `PlantFilterSheet` bottom modal for configuring all filter dimensions:
   - Quick statuses (propagating, groups, rerooting);
   - Botanical parameters (family, genus, cultivar, stage);
   - Custom filter presets (saving, loading, applying, and deleting user-defined filter presets).
3. Introduce `PlantFilterCriteria` model to encapsulate filter state, counting, serialization, and plant matching logic.
4. Introduce `PlantFilterPreset` model and `PlantFilterPresetService` to persist custom filter presets in `SharedPreferences`.
5. Display an active filters tag row directly on the home page when filters are active, allowing one-tap removal of individual filter dimensions or a complete reset.

## Implementation

- **Models**:
  - `lib/models/plant_filter_criteria.dart`: Contains `PlantFilterCriteria` with matching logic (`matches`), active property counts (`activeCount`), and `PlantFilterPreset` data structure.
- **Services**:
  - `lib/services/plant_filter_preset_service.dart`: Handles local CRUD persistence of `PlantFilterPreset` instances via `SharedPreferences`.
- **UI / Presentation**:
  - `lib/features/home/widgets/sheets/plant_filter_sheet.dart`: Accessible modal sheet using `SheetDragHandle`, `FilterChip` components, real-time matching counter on primary button, and custom preset management with `showPromptTextDialog`.
  - `lib/features/home/pages/home_page.dart`: Replaced inline filter rows with a compact "Filters" button and active filter strip with dismissible tag chips.
- **Localization**:
  - Added filter strings (`homeFilters`, `homeFilterReset`, `homeFilterResetAll`, `homeFilterApply`, `homeFilterBotanical`, `homeFilterFamily`, `homeFilterGenus`, `homeFilterCultivar`, `homeFilterStage`, `homeFilterStatuses`, `homeFilterCustomPresets`, `homeFilterSaveAsPreset`, etc.) across `ru`, `en`, `de`, `fr` localizations.

## Behavior

- When no filters are active, a compact "Фильтры" button is displayed next to the sorting control.
- Tapping the button opens `PlantFilterSheet` displaying status toggles, botanical filters (family, genus, cultivar, stage), and saved presets.
- Users can save the current active filter combination as a preset by tapping "+ Сохранить как пресет" and giving it a name. Saved presets can be applied with one tap or deleted with long press / confirmation.
- Applying filters updates the home page plant stream, displays the count on the filter button badge, and renders active filter chips that can be individually removed.

## Consequences

- Significantly cleaner and more compact home page layout on both mobile and large screens.
- Flexible multi-criteria filtering including cultivar-level filtering.
- Reusable preset mechanism stored locally without requiring backend schema migrations.

## Verification

- `flutter analyze lib/` passed with 0 issues.
- `flutter test` ran and passed all 75 unit/widget tests, including new tests in `test/plant_filter_criteria_test.dart`.
