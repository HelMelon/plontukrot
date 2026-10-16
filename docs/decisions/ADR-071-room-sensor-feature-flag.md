# ADR-071: A feature flag per room sensor

## Status

Accepted

## Context

A temperature sensor can be attached to any room, including the balcony. Each such room needs its own switch in the admin panel. The static flag list cannot name rooms that the user creates later.

## Decision

Saving a Yandex device id on a room creates a feature flag. Removing the id removes the flag.

- Key: `room_sensor_` plus the room id (`room_sensor_balcony` or `room_sensor_` plus the catalog id).
- Label: `Помещение с датчиком: {название}`. Renaming the room updates the label. The key stays.
- Group: its own admin section, titled with the label. It is not a row inside the shared IoT table.
- The balcony section is present while that room still exists, even before a device id is saved. Deleting the room removes the section. The label uses the room's current name.
- Default: on. An admin override can turn that room off.
- The user enters only the device UUID. The account OAuth token stays the server setting `YANDEX_IOT_TOKEN`.
- These keys are not members of the static `ALL_FLAGS` catalog. They are included in `GET /features` and in the admin user flag list only while a sensor row exists.

## Implementation

- Table `room_sensors` (`user_id`, `room_id`, `device_id`), including room id `balcony`.
- `PUT` and `DELETE /room-sensors/{room_id}`. Deleting a user room also deletes its sensor.
- `list_room_sensor_flags` in the app backend and in the admin panel.
- The manage-rooms sheet has a sensor button on every room, including the balcony. The icon uses `colors.success` when a device id is saved and `colors.error` when it is not. An empty field removes the sensor.
- Flutter `FeatureFlagsController.isRoomSensorEnabled` reads the dynamic key.
- The admin IoT table includes rows whose `group` is `iot`, so the new rows sit with the other sensors.

## Behavior

Attach `bf56b858-16fa-4a59-a807-72615cdeb438` to «Гостиная». The admin IoT table gains «Помещение с датчиком: Гостиная», on by default. Turning it off keeps the device id but `isRoomSensorEnabled` is false. Clearing the field removes the row.

## Consequences

The balcony wintering monitor still reads `BALCONY_SENSOR_ID` from the server environment. A device id stored on a room does not yet drive that monitor. The flag is the switch; temperature polling per room is not wired.

## Verification

- `flutter analyze` on the room sheet, room service, feature-flag controller, and icon tokens: no issues
- `flutter test test/room_sensor_flag_test.dart`: passed
- `python -m py_compile` on the app backend and admin-panel flag modules: passed
- Device UI was not run

Flags registered: backend dynamic keys (not in `ALL_FLAGS`) ✓ / Flutter prefix `room_sensor_` ✓ / admin-panel applied
