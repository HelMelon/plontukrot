# ADR-075: Ask whether to transfer propagations when merging plants

## Status

Accepted

## Context

Merging 2–3 plants of the same genus creates one new group and archives every selected plant with reason `merged`. Propagation batches stay linked to those archived plants through `parent_plant_id`. The active plant page then no longer shows them, because it only lists batches whose parent is that plant.

## Decision

On save in `MergePlantSheet`, if any selected plant has propagation batches, ask once whether to move them onto the new group.

- The question is `showAppDialog` (`AlertDialog`). It is not a silent default.
- **Перенести** reassigns those batches onto the new group.
- **Не переносить** leaves `parent_plant_id`, `parent_plant_name`, and `parent_plant_family` unchanged. Merge does not delete batches.
- Dismissing the dialog (barrier tap or Esc) cancels the save. The plants are not merged.
- If no selected plant has a batch, the dialog is not shown.
- Batches of every status are included, including archived ones. The link is `parent_plant_id`, the same field used when a batch is created.
- If the propagations feature is off, or the list request is forbidden, the dialog is skipped and batches stay on the source plants.

Reassignment uses the existing propagation update. It writes `parent_plant_id` to the new group id, `parent_plant_name` to that group's species, and `parent_plant_family` to its family (empty string when the family field is blank). That matches `AddPropagationSheet` / the plant card, which store species and family on the batch. The propagations board still resolves the live label from the plant document.

## Implementation

- `MergePlantSheet` loads batches for the selected plants, shows the dialog, calls the existing `PlantService.mergePlants`, then `PropagationService.reassignParentPlants` when the user confirms.
- `PropagationService.fetchForParentPlants` and `reassignParentPlant` reuse the current list and patch endpoints. No new API and no new layer.
- Which batches belong to the sources, and the decline path (transfer nothing), live in `merge_propagation_transfer.dart`.
- Copy is in the ru, en, de, and fr arb files.

If the group is created and the reassignment then fails, the sheet stays open. Saving again retries the transfer and does not create a second group.

## Behavior

Two Hoya are merged into a group. One has an active cutting and a sold batch. The dialog asks whether to transfer them. Confirm: both batches show the new group as parent, and the active cutting appears on the group's plant page. Decline: both batches still point at the archived source plants, and the new group has no propagations. Merging plants that have no batches does not ask.

## Consequences

- Active batches can follow the pot that remains in the collection.
- Declining keeps history on the original plant, including after that plant is archived.
- A partial failure can move only some batches if a later patch fails. Closing the sheet after that error does not ask again.
- Parent name stored on the batch is the group's species, not the nickname. The board nickname still comes from the live plant.

## Verification

- `flutter gen-l10n`
- `flutter analyze` on the merge sheet, propagation service, transfer helper, generated l10n, and the new test — no issues
- `flutter test test/merge_propagation_transfer_test.dart` — 6 tests passed
- The dialog was not opened on a device
