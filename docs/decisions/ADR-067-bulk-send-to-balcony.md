# ADR-067: Bulk send plants to the balcony

## Status

Superseded by ADR-073. The selection action now moves plants into a chosen room.

## Context

A plant can be marked on the balcony from its details page. The balcony monitor then uses that plant's cold-tolerance band. Home multi-select had no way to send several plants outside at once.

## Decision

When the `balcony` feature flag is enabled, the home selection bar shows «На балкон». It sets `on_balcony` for every selected plant and stores a cold-tolerance band with the same resolution as the single-plant toggle:

1. the plant's stored band, if it already has one;
2. the built-in genus table;
3. the cached genus care guide minimum temperature;
4. moderate (+10°C).

The action only sends plants out. Bringing a plant back inside stays on the details toggle. Selection mode closes after a successful update. The button is absent while the balcony flag is off.

## Implementation

- `PlantService.setPlantsOnBalcony`
- Home selection action, gated by `FeatureFlag.balcony`
- Icon token `balcony` (`Icons.landscape`)
- l10n `homeSendToBalcony` (ru/en/de/fr)

## Behavior

Select three plants and tap «На балкон». Each is marked on the balcony with its own band. A plant that already has a stored band keeps that band. If the request fails, a snackbar is shown and the selection stays.

## Consequences

Unknown genera may wait on the care-guide lookup, one plant after another. The home cards do not show the balcony state; it remains visible on the plant details toggle and in the temperature alert.

## Verification

- `flutter analyze` on the home page, `plant_service.dart`, and icon tokens
- Device UI was not run
