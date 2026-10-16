# ADR-073: Bulk move plants to a room

## Status

Accepted

## Context

Home multi-select still had «На балкон». Placement is a room, and the balcony is one room in that list, so the selection bar should move plants into a chosen room.

## Decision

The selection action opens the same room picker as the plant card, with nothing preselected. The chosen room, including «Не выбрано», is applied to every selected plant through `PlantService.setPlantRoom`.

- Moving into the balcony room still sets `on_balcony`, stores the cold-tolerance band, and stops fertilizing.
- Moving out of the balcony restores the automatic fertilizing interval.
- Any other room only changes `room_id`.
- Selection mode closes after a successful update. A failure shows a snackbar and keeps the selection.

## Implementation

- Home selection button uses the room icon and `homeMoveToRoom`.
- `showSelectPlantRoomSheet(indicateCurrent: false)` so a mixed selection does not look already placed.
- `PlantService.setPlantsOnBalcony` is removed. ADR-067 is superseded.

## Behavior

Select three plants and tap «В помещение». Choose «Коридорная теплица». All three get that room. Choose «Не выбрано» and the room is cleared. Choose «Балкон» and those plants stop being fertilized, the same as a single move onto the balcony.

## Consequences

The action is always available. It is not gated by a feature flag.

## Verification

- `flutter gen-l10n` and `flutter analyze` on the home page, room picker, and plant service
- Device UI was not run
