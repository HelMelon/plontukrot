# ADR-070: Rooms, with the balcony as a system place

## Status

Accepted

## Context

Plants needed a place (гостиная, подоконник, and so on) that can be filtered and edited like the soil and fertilizer catalogs. The balcony already exists and must stay tied to the temperature sensor, while still appearing in that same list. No other rooms should be created up front.

## Decision

Rooms are a per-user catalog of names. The balcony is one of those rows, with the reserved id `balcony`, until the user deletes it.

- A plant has at most one room. `null` means it is not placed.
- Putting a plant on the balcony (details toggle, bulk «На балкон», or the room picker) sets `on_balcony`, stores the cold-tolerance band, sets `room_id` to `balcony`, and stops fertilizing. If the balcony row was deleted, that action creates it again as «Балкон».
- Taking it off the balcony clears that room unless another room is chosen in the same action, and restores the automatic fertilizing interval.
- The balcony can be renamed and deleted like any other room. Deleting it clears `room_id`, turns `on_balcony` off, removes its sensor, and the next fertilizing recalculation restores the automatic interval. It is not created again until a plant is sent outside.
- The home filter «Помещение» lists the catalog, including the balcony under its current name. Chips wrap. Management opens from that section and from the plant's room picker.
- A new account sees only Балкон. No other rooms are seeded.

## Implementation

- Table `rooms` and `plants.room_id` (schema and startup migration). Catalog routes `/rooms`.
- `RoomService`, `Plant.effectiveRoomId`, `PlantService.setPlantRoom`.
- `PlantService.setOnBalcony` writes the room together with the sensor flag and fertilizing frequency.
- Manage sheet follows the soil-component sheet: list, add, rename, delete. The balcony row has the same actions. `rooms` is keyed by `(user_id, id)`. `removed_system_rooms` remembers a deleted balcony so the list does not recreate it.
- Plant details show the current room and open the picker. The balcony toggle stays for the sensor band and history.
- Filter criteria store `roomId`. Plants already marked `on_balcony` match Балкон even before `room_id` is backfilled.

## Behavior

Open filters: the room section shows Балкон and a manage button. Add «Гостиная» there, then on a plant choose that room. The home filter chip «Помещение: Гостиная» shows only those plants. Choosing Балкон for a plant turns the sensor flag on and sets fertilizing frequency to 0. Choosing «Не выбрано» or another room brings it back inside and restores the automatic interval. Rename Балкон to «Лоджия» and the picker, filter, and admin section use that name. Delete it and it disappears; plants that were there come inside. Send a plant outside again and «Балкон» returns.

## Consequences

The sensor monitor still reads `on_balcony`, not the rooms table. A custom interval from before the balcony is not restored. The client stores `room_id` only after the backend with this column is running.

## Verification

- `flutter analyze` on the touched Dart files: no issues
- `python -m py_compile` on the touched backend modules and the admin-panel flag module: passed
- Device UI was not run
