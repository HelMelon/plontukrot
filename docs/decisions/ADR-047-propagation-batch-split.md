# ADR-047: Propagation batch split

## Status

Accepted

## Context

Propagation batches (`Propagation`) group plants originating from the same parent and rooting method. As plants grow at different rates, individual specimens within a batch may reach advanced stages (e.g., Juvenile or Adult) while others remain Babies. 

Previously, changing the stage of a batch while adjusting `quantityAlive` implicitly treated the difference as lost plants (`lostQuantity`), which could inadvertently mark remaining healthy plants as lost and trigger unintended batch archive upon sale. Users needed a way to separate one or more advanced plants into their own batch without affecting or discarding the remaining plants.

## Decision

Introduce explicit **batch splitting** (`splitPropagation`):
1. Any active propagation batch with `quantityAlive > 1` can be split.
2. Users specify how many plants to split (`1` to `quantityAlive - 1`), the new stage for the separated plants (Start, Baby, Juvenile, or Adult), the event date, and an optional note.
3. The source batch decreases its `quantity` and `quantityAlive` by the split amount without incrementing `lostQuantity`. A stage history entry is appended to the source batch noting the split count and destination stage.
4. A new active batch is created containing the split count at the specified new stage, retaining the source batch's parent plant info, rooting method, and original `startedAt` date. A stage history entry is added to the new batch referencing the origin.

## Implementation

- **Service layer**: `PropagationService.splitPropagation` performs the atomic reduction on the source batch and creates the new batch with its initial history entry.
- **Backend API & Schema**: Updated `backend/app/schemas.py` (`StageHistoryCreate`) and `backend/app/routers/propagations.py` (`add_stage_history`) to support custom `changed_at` timestamps.
- **Presentation layer**:
  - `SplitPropagationSheet` (`lib/features/plants/widgets/sheets/split_propagation_sheet.dart`) provides the input form with stage selector, quantity validator, date picker, and note field.
  - `PropagationDetailsSheet` (`lib/features/plants/widgets/sheets/propagation_details_sheet.dart`) surfaces the «Отделить» action for active batches with `quantityAlive > 1`.
- **Localization**: Added keys `propagationSplit`, `propagationSplitTitle`, `propagationSplitQuantity`, `propagationSplitQuantityMin`, `propagationSplitQuantityMax`, `propagationSplitNewStage`, `propagationSplitSourceNote`, `propagationSplitNewBatchNote`, and `propagationSplitSuccess` across `ru`, `en`, `de`, and `fr`.
- **Testing**: Added test cases in `test/propagation_lifecycle_test.dart` verifying batch splitting quantity conservation and zero lost-count behavior.

## Behavior

- On the propagation details sheet of an active batch with multiple living plants, an «Отделить» button is displayed.
- Tapping «Отделить» opens a modal sheet allowing the user to choose how many plants to separate and select their new stage.
- Upon saving, the source batch count is reduced and its timeline records the split (e.g. `Отделено 1 шт. (Взрослое)`).
- A new active propagation card appears on the board representing the separated plant(s), ready for independent stage progression, sale, gifting, trading, or loss tracking.

## Consequences

- Resolves the bug where users were unable to sell advanced plants without sacrificing the rest of the batch.
- Preserves batch aggregates and year stats integrity: total started count across split batches equals the original started count.
- Avoids complex multi-stage counters inside a single document while giving users complete per-stage lifecycle freedom.

## Verification

- Code inspection across `lib/services/propagation_service.dart`, `lib/features/plants/widgets/sheets/split_propagation_sheet.dart`, and `lib/features/plants/widgets/sheets/propagation_details_sheet.dart`.
- Unit tests in `test/propagation_lifecycle_test.dart` covering split quantity math and year stats preservation.
- Theme tokens, a11y semantics, and multi-language localizations verified.
