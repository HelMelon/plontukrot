# ADR-077: Link from a participant to its experiment

## Status

Accepted

## Context

An experiment participant is not a separate page. It is a plant on
`PlantDetailsPage`, or a propagation batch opened in `PropagationDetailsSheet`
(from the propagations hub, from the plant's propagation section, or from the
archive). The experiment itself is `ExperimentDetailsPage(experimentId)`.

From the participant, the only way back to the trial was the home experiments
icon. The user asked for a distinct block on the participant's own page that
opens the experiment they are in.

## Decision

When `FeatureFlag.experiments` is on, the plant card and the propagation
details sheet show one section titled with the existing experiments heading.
Inside it, one tappable card per experiment that includes this subject. The
card shows the experiment title, the variant label (several labels joined when
the same subject sits in more than one variant of that trial), and the active
or finished status. Tapping the card pushes `ExperimentDetailsPage`.

The section is absent when the flag is off, while the list is still loading,
when the fetch has not yet succeeded, and when this subject is in no
experiment. The flag-off case never calls `GET /experiments` (that route
requires the flag).

Membership is a pure lookup, `membershipsForSubject`: match
`subject_type` and `subject_id` together, keep the incoming experiment order,
and keep finished and archived experiments. An empty id matches nothing. A
plant and a propagation batch that happen to share an id do not match each
other.

## Implementation

- **Lookup** (`lib/models/experiment.dart`): `ExperimentSubjectMembership` and
  `membershipsForSubject`. No new service method; the UI watches
  `ExperimentService.watchExperiments()` and filters locally.
- **UI** (`lib/features/experiments/widgets/subject_experiments_section.dart`):
  the section. Plant info card places it between propagations and the journal.
  The propagation details sheet places it between the batch header and the
  timeline. Visuals use card and spacing tokens; the section title reuses
  `experimentsTitle`.
- **Copy**: `experimentsParticipantVariant` in `ru`, `en`, `de`, `fr`. Status
  and the section title reuse existing experiment strings.
- **Accessibility**: each card is a button. Its label is the visible title,
  then the variant line and status. The chevron is excluded from semantics.

## Behavior

- A plant that is a subject of two experiments shows two cards. Each opens
  that experiment.
- A plant in both arms of one experiment shows one card, with both variant
  labels.
- A batch that is not a subject shows no experiments block, and the sheet
  layout is unchanged.
- Users without the experiments flag never see the block.
- Opening the card from the propagation sheet pushes the experiment page above
  the sheet. Popping it returns to the sheet.

## Consequences

- While a flagged user's plant page or propagation sheet is open, the app
  polls the experiments list the same way the experiments hub does, even if
  this subject is in none. The section stays hidden until a match exists, so
  non-participants do not see a spinner.
- A failed first fetch hides the section until a later poll succeeds. The
  plant page does not show an experiments error of its own.
- Archived and finished trials stay linked, because the participant is still
  recorded on them. There is no separate "archived" status label; a finished
  trial shows the existing finished status, and an archived trial that is not
  finished shows the active status.

## Verification

- `flutter analyze` on the touched Dart files: no issues.
- `flutter test test/experiment_test.dart`: passed, including
  `membershipsForSubject` (several experiments, several variants, plant versus
  propagation id, empty id, finished and archived kept).
- The screen was not opened on a device or in a browser.
