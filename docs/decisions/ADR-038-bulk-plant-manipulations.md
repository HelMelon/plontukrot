# ADR-038: Bulk manipulations on Home multi-selection

## Status

Accepted

## Context

Users can select multiple plants on the home page to perform bulk actions such as watering, fertilizing, repotting, adding notes, editing families, merging, or deleting. Manipulations (pinching, reanimation, and stimulator treatments) were previously only available per single plant from the plant details care sheet. Users requested making manipulations available as a bulk action when multiple plants are selected on the home page.

## Decision

1. **`AddManipulationSheet` multi-plant support**:
   - Refactored `AddManipulationSheet` to accept `List<String> plantIds`, `List<Plant> plants`, and an optional `title` parameter, consistent with `AddFertilizingSheet` and `AddRepottingSheet`.
   - In bulk mode (`isBulk == true`):
     - For pinching and stimulators, the entry is applied to all selected plants.
     - For rerooting/reanimation, the initial stage label is omitted (as stages may vary across plants), while optional stage update (`stageAfter`), status, dates, and notes are applied to all selected plants.
   - On save, `Navigator.pop(context, true)` signals success so the home selection mode can automatically exit.

2. **`ManipulationService.addManipulations`**:
   - Added `addManipulations` helper in `ManipulationService` to sequentially apply manipulation records across all selected plant IDs.

3. **Home multi-selection AppBar**:
   - Added an action button with the manipulation semantic icon (`_icons.rerooting`) and tooltip `homeManipulations` («Манипуляции»).
   - Integrated `_showManipulationsSheet` flow which opens `AddManipulationSheet` with selected plants and automatically exits selection mode upon completion.

4. **Localization**:
   - Added `homeManipulations` and `homeManipulateSelectedTitle` keys across Russian, English, German, and French locale files.

## Implementation

- `lib/services/manipulation_service.dart`: added `addManipulations(plantIds: ...)`.
- `lib/features/plants/widgets/sheets/add_manipulation_sheet.dart`: multi-plant constructor support and bulk save handling.
- `lib/features/home/pages/home_page.dart`: `_showManipulationsSheet` and action button in `_buildSelectionAppBar`.
- `lib/l10n/`: added localization strings in `app_ru.arb`, `app_en.arb`, `app_de.arb`, `app_fr.arb`.

## Behavior

- Selecting multiple plants on the main screen shows the manipulations icon in the selection AppBar.
- Tapping it opens the manipulation form with the title «Манипуляции для выбранных растений».
- Saving the form creates a manipulation entry for each selected plant and closes selection mode.

## Consequences

- Streamlines batch care routines (e.g. mass stimulator spraying or pinching).
- Retains single-plant editing and creation workflows without regression.

## Verification

- `flutter gen-l10n` ran successfully.
- `flutter test` passed all 68 tests.
- `flutter analyze` clean with 0 issues in application code.
