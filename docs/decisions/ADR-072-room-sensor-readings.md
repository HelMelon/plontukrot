# ADR-072: Room placement card and per-room sensors

## Status

Accepted

## Context

The plant card had a balcony switch («В помещении» / «На балконе», cold-tolerance line, history, toggle) gated by the static `balcony` feature flag. Rooms can now carry their own Yandex device id, so that switch and that flag no longer match how a plant is placed.

## Decision

The card shows the room the plant is in. Tapping the name or the chevron opens the room picker. There is no switch and no cold-band line on the card.

- A sensor icon is shown only when that room has a saved device id. It uses `colors.success`. Tapping it opens the device's current Yandex properties (temperature, humidity, and any other reported property).
- The static `balcony` flag is removed from the backend catalog, the Flutter enum, and the admin panel. Per-room `room_sensor_{id}` flags remain the switch for a room's sensor.
- A stored device id matches a Yandex id when the full id is equal or the part before `:` is equal.
- The wintering pass reads every enabled room sensor for the owner account. `BALCONY_SENSOR_ID` is used only when the balcony room's sensor flag is on and no device id is saved on that room. Plants in that room (and plants still marked `on_balcony` for the balcony room) are compared with their stored cold band. The season window is unchanged: 1 August–30 April.
- Sending a plant to the balcony room still stops fertilizing. Bringing it into another room restores the automatic interval.

## Implementation

- `PlantRoomField` is the placement card. `BalconyToggle` is removed.
- `GET /room-sensors/{room_id}/reading` returns the device properties. It is not gated by the old balcony flag.
- `climate_scan` replaces the single-sensor balcony status used by the home banner and the background alert.
- Bulk «На балкон» and the cold banner are no longer hidden behind `FeatureFlag.balcony`.

## Behavior

A plant in «Коридорная теплица» shows that name on the card. With no device id there is no sensor icon. After a device id is saved, the green sensor icon opens the current readings. The same card is the room picker. A room whose `room_sensor_` flag is off does not return readings and is skipped by the wintering pass.

## Consequences

The three-day balcony history sheet is no longer opened from the plant card. History is still recorded for the balcony sensor during the wintering season. A custom cold band is still stored only when a plant is sent to the balcony room; other rooms do not set it. The Yandex OAuth token stays a server setting.

## Verification

- `flutter gen-l10n` and `flutter analyze` on the touched Dart files: no issues
- `python -m py_compile` on the touched backend modules and the admin-panel flag module: passed
- Device UI was not run

Flags registered: static `balcony` removed — backend ✓ / Flutter ✓ / admin-panel applied
