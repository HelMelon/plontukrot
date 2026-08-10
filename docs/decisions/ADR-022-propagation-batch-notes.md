# ADR-022: Propagation batch journal notes

## Status

Accepted

## Context

Adult plants have a journal (`users/{uid}/plants/{plantId}/notes`) with shared UI (section «Журнал», add/edit sheets, tiles). Propagation batches only supported optional one-line notes on `stageHistory` rows. Users needed the same journal experience on a batch, with notes retained when the batch is archived.

## Decision

1. Store journal notes under the batch: `users/{uid}/propagations/{propagationId}/notes/{noteId}` with the same fields as plant notes (`text`, `createdAt`, `expiresAt` +183 days, `updatedAt` on edit).

2. Extend `NoteService` with `NoteParent` (`plant` | `propagation`) so one service and the existing note widgets serve both owners. Widget file names stay plant-prefixed; they take `NoteParent` instead of a raw plant id.

3. Archive remains **in-place** on the propagation document. Notes are not copied or moved; they stay under the same batch and are therefore archived with it. Event annotations on `stageHistory.note` are unchanged.

4. Hard delete of a batch (`deletePropagation`, including start-stage delete) also deletes the `notes` subcollection. Plant subtree delete removes each related propagation’s `notes` as well as `stageHistory`.

## Implementation

- Service: `NoteParent` / `NoteParentKind` in `note_service.dart`; dual Firestore path.
- UI: parameterized `PlantNotesSection`, `PlantNoteTile`, `AddNoteSheet`, `UpdateNoteSheet`; plant call sites updated; journal block added to `PropagationDetailsSheet` (scrollable body).
- Cascade: `PropagationService.deletePropagation`, `PlantService._deletePlantSubtree`.

## Behavior

- From batch details (active or archived), the user sees «Журнал» with add/edit/delete matching the plant journal.
- Archiving a batch (alive → 0) keeps journal notes with the batch document.
- Deleting a batch removes its journal notes.

## Consequences

- Firestore rules catch-all already allows owner read/write under `propagations/.../notes/...`; no rules deploy required for this feature.
- `expiresAt` on notes is stored like plant notes and is not client-enforced; batch archive retention remains 365 days on the propagation document.

## Verification

- `flutter analyze` on touched Dart files.
- Manual device checks of add/edit/delete on active and archived batches were not run in the implementation session.
