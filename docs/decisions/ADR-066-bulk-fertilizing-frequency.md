# ADR-066: Bulk fertilizing frequency

## Status

Accepted

## Context

Home multi-select can water, fertilize, repot, add notes, change family, merge, and delete. Fertilizing frequency (`fertilizing_frequency_days`) could be changed only on a single plant's add/edit sheet.

## Decision

The selection bar gains a frequency action (leaf icon, tooltip «Частота подкормки»). It opens a sheet for the selected plants:

- A shared interval of 0 (stop) or 1–180 days is written to every selected plant.
- «Сбросить на авто» writes each plant's stage-and-season interval from `resolveFertilizingFrequencyDays`.
- If the selected plants already share one interval, the field is prefilled. If they differ, the field starts empty and the sheet says so.
- An empty or out-of-range value shows the existing validation message under the field. Saving stays available so the error is visible.
- After a successful save, fertilizing reminders are rescheduled once and selection mode closes.

The phone selection bar scrolls horizontally so each action keeps a full tap target.

## Implementation

- `PlantService.updatePlantsFertilizingFrequency`
- `BulkFertilizingFrequencySheet`
- Home selection app bar action
- l10n `homeFertilizingFrequencyMixed` (ru/en/de/fr)

Logging a fertilizing event stays the separate «Подкормка» action.

## Behavior

Select three plants, open «Частота подкормки», enter 21, save → all three use a 21-day interval. «Сбросить на авто» on a baby and an adult plant restores 14 and 18 days in spring/summer (or the current season table). Entering 200 and pressing save shows the validation error and does not write.

## Consequences

The custom-frequency flag is still not stored on the server. A later automatic season recalculation can overwrite both this bulk value and a single-plant manual value.

## Verification

- `flutter analyze` on the sheet, home page, and `plant_service.dart`
- Device UI was not run
