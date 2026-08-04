# ADR-004: Propagation batch lifecycle

## Status

Accepted

## Context

The propagation feature tracked batches with aggregate counters (`quantityAlive`, `soldQuantity`, `lostQuantity`), a shared batch `stage`, and batch-level `stageHistory`. Requirements called for:

- initial stage rules by propagation method (including a choice for division);
- additional dispositions: gifted and traded (without collapsing the batch into a single fate);
- parent nickname on the global propagations board;
- correct chronological timeline when several stage events share a calendar day.

Introducing per-offspring Firestore documents was rejected: the batch remains the unit of storage and UI.

## Decision

Keep the **batch-centric** model. Extend it minimally:

1. **Initial stage** is resolved by `initialStageFor(method, divisionStage:)`:
   - `offset` (Детка) → stage 2 (Детка);
   - `division` → user chooses stage 2 or 3;
   - all other methods → stage 1 (Старт).
   The chosen value is written as the first `stageHistory` entry and as `Propagation.stage`.

2. **Stage and outcome stay separate.** Outcomes are quantity counters plus optional `outcome` on history rows. Current stage is never replaced by an outcome label. “Alive” remains `quantityAlive > 0` with no synthetic `active` outcome enum value.

3. **Outcomes:** `sold`, `gifted`, `traded`, `lost` via `PropagationOutcome` and counters `soldQuantity` / `giftedQuantity` / `tradedQuantity` / `lostQuantity`. Archive statuses extend `PropagationStatus` with `gifted` and `traded`.

4. **Parent nickname** is resolved live from `Plant` by `parentPlantId` on `PropagationsPage` only (`propagationParentLabel`). Nickname is not denormalized onto the propagation document.

5. **Same-day timeline:** date pickers merge the picked calendar day with the current clock via `dateWithCurrentTime`. History is ordered by `changedAt`, then document id.

6. **Year stats** continue to aggregate batch counters; gifted/traded are included alongside sold/lost.

## Implementation

- Models: `propagation_initial_stage.dart`, `propagation_outcome.dart`, `propagation_parent_label.dart`; extended `Propagation`, `PropagationStatus`, `PropagationStageEntry`, `PropagationYearStats`.
- Service: `PropagationService.addPropagation` uses initial-stage rules; `markOutcome` (+ sell/gift/trade/lost wrappers); archive `whereIn` includes new statuses; history secondary sort.
- UI: create sheet (division stage choice); details sheet (four outcome actions); global propagations page (parent label + stats); date pickers use `dateWithCurrentTime`.
- Tests: `test/propagation_lifecycle_test.dart`.
- Layers unchanged: `features → models/services/core` (no repositories/use cases).

## Behavior

- Creating an offset batch of 3 writes one history event at stage Детка with `quantityAlive: 3`.
- Division shows Детка / Ювенил radios; the selection becomes the first history stage.
- Marking “Подарила” 1 of 10 reduces `quantityAlive`, increments `giftedQuantity`, appends a history row with the **current stage** plus `outcome: gifted`.
- Propagations board shows `Родитель: Hoya carnosa «Бабушка»` when the parent plant has that nickname.
- Two stage changes on 04.08 at 10:00 and 15:00 appear in that order with stages Детка then Ювенил.

## Consequences

- Pros: matches existing UX and Firestore shape; no migration of per-unit documents; stats remain batch aggregates.
- Cons: still no true per-unit stage histories; mixed stages inside one batch are approximated by counters and a single current `stage`.
- Legacy docs without `giftedQuantity`/`tradedQuantity` read as `0`.

## Verification

- `flutter analyze lib test` — no issues.
- `flutter test test/propagation_lifecycle_test.dart test/l10n_test.dart` — all passed.
- Device/UI manual run not performed in this session.
