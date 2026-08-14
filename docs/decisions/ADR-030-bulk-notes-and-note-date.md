# ADR-030: Bulk plant notes and editable note date

## Status

Accepted

## Context

Journal notes existed per plant and per propagation batch (`users/{uid}/…/notes`)
with `text`, `createdAt`, and `expiresAt` (+183 days). Users could add a note only
from a single plant/batch screen, and could not change the note date after
creation. Home already supports multi-select bulk watering, fertilizing, and
repotting.

## Decision

1. **Bulk add** — from Home selection mode, add the same journal text and date to
   every selected plant via `NoteService.addNotes`. Propagation batches are not
   included in this Home action.

2. **Editable date** — add and edit note sheets expose a date picker. The stored
   journal date is `createdAt`. Changing the date also recomputes
   `expiresAt = createdAt + 183 days`. Future dates are not allowed.

3. Keep a single `AddNoteSheet` for one or many `NoteParent`s. Existing plant and
   propagation add-note entry points pass a one-element list.

## Implementation

- `NoteService.addNote` / `addNotes` / `updateNote` accept optional `createdAt`.
- UI: date `ListTile` + `a11ySelectDate` on add and update sheets; empty text
  uses `InputDecoration.errorText` (`notesCannotBeEmpty`).
- Home selection AppBar: notes action next to repotting.

## Behavior

- Bulk save writes one note document per selected plant with identical text and
  date.
- Editing a note can change both text and date; the list remains ordered by
  `createdAt` descending.
- Single-plant and batch add still work; date defaults to today.

## Consequences

- Retention (`expiresAt`) follows the chosen journal date, not the edit time.
- Home bulk notes do not apply to propagation batches.

## Verification

- `flutter analyze` on touched files
- `flutter gen-l10n`
- Device UI not run in this session
