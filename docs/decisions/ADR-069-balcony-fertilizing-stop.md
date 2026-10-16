# ADR-069: Balcony plants stop fertilizing

## Status

Accepted

## Context

Plants on the balcony should not be fertilized. The interval had to be set by hand, and a later season recalculation could put an automatic interval back while the plant was still outside.

## Decision

`on_balcony` and fertilizing frequency move together.

- Sending a plant to the balcony writes `fertilizing_frequency_days` = 0 (STOP).
- Bringing it inside writes the automatic interval for its current stage and season. A manual interval from before the balcony is not restored.
- Plants already on the balcony are set to 0 on the next automatic frequency pass (app start and the profile season action). That pass does not replace 0 with a seasonal interval while `on_balcony` is true.
- Saving a plant that is still on the balcony keeps frequency 0, even if the edit form contains another number.
- Bulk fertilizing-frequency change skips plants that are on the balcony.

## Implementation

- `PlantService.setOnBalcony` and `setPlantsOnBalcony` write the frequency and reschedule fertilizing reminders. The bulk path reschedules once.
- `recalculateAutoFertilizingFrequencies` forces STOP for balcony plants and skips them for the seasonal table.
- `updatePlant` forces STOP when the stored plant is on the balcony.
- `updatePlantsFertilizingFrequency` skips balcony plants.
- The edit sheet shows 0 for a balcony plant and does not replace it when the stage changes.

The single-plant toggle and the home «На балкон» action both go through `setOnBalcony`. There is still no bulk action to bring plants inside.

## Behavior

A plant with a 14-day interval is sent to the balcony. Its frequency becomes 0 and fertilizing reminders stop. When the details toggle brings it inside, the frequency becomes the stage-and-season default (for example 14 or 28), not the number it had before. Plants that were already outside get 0 the next time the app recalculates automatic frequencies.

## Consequences

A custom interval is discarded when the plant returns indoors, because only the numeric days are stored and the request is to restore the default. Editing the frequency field while the plant is on the balcony does not stick: the next save writes 0 again.

## Verification

- `flutter analyze` on `lib/services/plant_service.dart` and `lib/features/plants/widgets/sheets/update_plant_sheet.dart`: no issues
- Device UI was not run
