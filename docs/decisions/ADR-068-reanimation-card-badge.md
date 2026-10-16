# ADR-068: Reanimation badge on plant cards

## Status

Accepted

## Context

An active reanimation is a rerooting manipulation without an end date. The home filter can show those plants, but the card itself gave no sign that a plant was in reanimation.

## Decision

While reanimation is active, the plant photo shows a red bandage badge (error color) in the top-right corner, the same spot as the overdue-fertilizing mark. If both apply, the bandage sits above that mark. While the card is selected, the check stays top-right and the badges move to the bottom-right, as the fertilizing mark already did. The badge uses the same active-rerooting set as the home filter.

The badge is on:

- the home grid
- the genus page grid
- the plant list opened from the family page

It is hidden when the manipulation has an end date. Quarantine stays top-left.

## Implementation

- `PlantCard.inReanimation`
- Home, genus page, and family plant sheet pass ids from `ManipulationService.watchActiveRerootingPlantIds`
- Icon token `bandage` (`Icons.healing`)
- l10n `a11yPlantReanimation` (ru/en/de/fr)

## Behavior

Start reanimation on a plant. Its card on home, in its genus, and in the family plant list shows the bandage. Finish reanimation and the badge disappears.

## Consequences

Stage grids and a friend's collection do not show the badge.

## Verification

- `flutter analyze` on the card, home page, genus page, family sheet, and icon tokens
- Device UI was not run
