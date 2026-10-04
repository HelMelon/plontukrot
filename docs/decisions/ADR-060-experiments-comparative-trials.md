# ADR-060: Experiments (comparative trials)

## Status

Accepted

## Context

The user runs plant experiments by design: the same cultivar in different
substrates, or the same plant kept in different places, and then watches which
arm does better. Nothing in the app expressed this. Plants are independent
entities; propagation batches group cuttings from one parent. A plant can only
be "on the balcony" or not — there is no notion of a comparison group, of a
hypothesis, or of per-arm observations over time.

The user described the feature as not fully formed and asked to help design and
build it. After clarifying questions she chose:

- scope: group + variants + observation log + a comparison screen (no automatic
  sensor metrics in v1);
- participants: both collection plants and propagation batches;
- the variable of the trial: her own free text per experiment (not a fixed
  substrate / place / care enum);
- observation log: note + photo + numbers (height, leaf count, moisture).

## Decision

Introduce a new self-contained domain — **experiments** — with a nested tree:

- **Experiment** — title, optional hypothesis, optional note, start date,
  optional conclusion, completion date, archive date.
- **ExperimentVariant** — label + free-text description + position. The variant
  is what the user compares ("в кокосе" / "в грунте"); its difference is
  described in her words.
- **ExperimentSubject** — a participant, either a `plant` or a `propagation`
  batch, referenced by id with a stored name snapshot.
- **ExperimentObservation** — per subject: observed-at date, note, optional
  photo URL, and nullable `height_cm` / `leaf_count` / `moisture`.

The whole tree lives under the `/experiments` router (`experiments.py`), which
owns its own tables — no other domain attaches to it. Subjects reference plants
and propagations by id with no foreign key, so deleting a plant never silently
destroys an experiment; instead the stored `subject_name` keeps the card
readable.

The feature is gated by the server-driven `experiments` flag (see ADR-055). It
ships **off by default** so it can be enabled per user from the admin panel.

## Implementation

- **Backend model** (`backend/app/db.py`, `auto_migrate`): tables
  `experiments`, `experiment_variants`, `experiment_subjects`,
  `experiment_observations` with `ON DELETE CASCADE` down the tree and indexes
  on `user_id`, `experiment_id`, `variant_id`, `subject_id`.
- **Schemas** (`backend/app/schemas.py`): `ExperimentCreate/Update/Out`,
  `ExperimentVariantCreate/Update/Out`, `ExperimentSubjectIn/Out`,
  `ExperimentObservationCreate/Out`.
- **Router** (`backend/app/routers/experiments.py`):
  - `GET/POST /experiments`, `PATCH/DELETE /experiments/{id}`
  - `POST /experiments/{id}/variants`, `PATCH/DELETE /variants/{id}`
  - `POST /variants/{id}/subjects`, `DELETE /subjects/{id}`
  - `GET/POST /subjects/{id}/observations`, `DELETE /observations/{id}`
  - `POST /subjects/{id}/observations/upload` (photo)
  - The full tree is loaded in four flat queries (`= ANY(...)` + Python
    grouping) instead of one query per variant/subject.
  - Ownership is checked by joining up the tree to `experiments.user_id`.
- **Flag**: `FLAG_EXPERIMENTS` in `feature_flags.py` (default off) + the flag is
  registered in the Flutter `FeatureFlag` enum and in the admin panel catalog
  (`admin-panel/app/feature_flags.py`).
- **Flutter models**: `experiment.dart`, `experiment_variant.dart`,
  `experiment_subject.dart`, `experiment_observation.dart` — plain classes with
  `fromMap`/`toMap` (project convention), enum `ExperimentSubjectType` with a
  `bool` extension per project rules.
- **Service**: `experiment_service.dart` — mirrors `PropagationService`
  (REST + `restPollStream`).
- **UI** (`lib/features/experiments/`):
  - `pages/experiments_page.dart` — hub with experiment cards;
  - `pages/experiment_details_page.dart` — header, variants, participants and
    per-subject observation logs;
  - `widgets/sheets/experiment_form_sheet.dart` — create/edit + inline variant
    editing (existing variants diffed on save: created / patched / deleted);
  - `widgets/sheets/add_subjects_sheet.dart` — picker over plants (archived
    excluded) and active propagation batches, with search and duplicate guard;
  - `widgets/sheets/add_observation_sheet.dart` — date, note, photo (gallery /
    camera + crop), height / leaves / moisture;
  - `widgets/sheets/experiment_compare_sheet.dart` — variants side by side with
    the latest measured height / leaf count / moisture.
  - Entry point: a home-AppBar icon gated by `FeatureFlag.experiments`.
- **Localization**: ~70 keys per locale (`ru`, `en`, `de`, `fr`) plus the
  `homeExperiments` tooltip; plurals for variant / observation counts.

## Behavior

- Create an experiment with a title and one or more variants; participants and
  observations are added afterwards from the details page.
- Each variant holds its own participants. A participant may be a plant or a
  propagation batch; the same target is never offered twice in one variant.
- Every participant has an observation log: log a note and optionally a photo
  and numeric readings. Editing an observation replaces it (delete + re-create),
  so the server-side nested log stays the single source of truth.
- The details AppBar offers **compare** (enabled only when at least one variant
  has a numeric reading) and **edit**; the header offers **mark finished** /
  **reopen** and delete.
- Completing an experiment sets `completed_at`; the conclusion can be written in
  the edit form.

## Consequences

- Experiments are fully independent of plant/propagation lifecycles: archiving or
  deleting a plant does not delete the experiment, it only freezes the stored
  name. This is deliberate — an experiment outlives its subjects.
- No automatic sensor metrics in v1; the moisture field is entered by hand.
  Wiring balcony/sensor readings into observations is a possible later step.
- The flag defaults off, so existing users see no change until it is enabled
  (the owner account is enabled via a DB override written the same way the admin
  panel writes one).
- Editing an observation is delete + re-create: its `id` changes. Acceptable
  because nothing references an observation id across the app.

## Verification

- Backend deployed to `91.149.167.7` (unit `plontukrot` restarted); the new
  endpoints appear in the live `/openapi.json`.
- End-to-end smoke against the production DB: create experiment with two
  variants and two subjects (a plant + a propagation batch), add an observation
  (note, height 12.5, 4 leaves, moisture 47), read the nested tree back
  (observation count and values verified), add a third variant, patch the
  conclusion, delete the experiment, and confirm it is gone — all via REST.
- `flutter analyze lib test` clean; `flutter test` run reported.
- The `experiments` flag was enabled for the owner account and confirmed in
  `GET /features`.
