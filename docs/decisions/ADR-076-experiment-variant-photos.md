# ADR-076: Experiment variant photos

## Status

Accepted

## Context

An experiment variant is one arm of a comparative trial (a pot, a substrate, a
place). Observations already store an optional photo, but the variant itself
had only a label and a free-text description. The user needs a photo of the
arm — what the setup looks like — before any observation is logged.

Variants created together on `POST /experiments` do not have ids while the
form is still open, so the photo cannot be uploaded under a variant id.

## Decision

A variant may store one optional photo URL in `experiment_variants.image_url`.
The photo belongs to the arm, not to an observation.

The file is uploaded first and the returned URL is saved on the row, the same
way an observation photo works. Because the row may not exist yet, the upload
does not take a variant id. The file is stored under the signed-in user:

`photos/experiments/variants/{user_id}/{photo_id}{ext}`

`ExperimentVariantCreate` and `ExperimentVariantUpdate` accept `image_url`
(`imageUrl` alias). A blank string is stored as NULL. Omitting the field on
update leaves the current URL unchanged; sending JSON `null` clears it.

Observation photos stay on `POST /subjects/{id}/observations/upload` under
`photos/experiments/{experiment_id}/`. This change does not alter that path.

## Implementation

- **Database** (`backend/app/db.py`): nullable `image_url TEXT` on
  `experiment_variants`, both in the create-table statement and via
  `ADD COLUMN IF NOT EXISTS` so existing databases gain the column on the
  next auto-migrate.
- **API** (`backend/app/schemas.py`, `backend/app/routers/experiments.py`):
  create, add, update, and the nested tree load read and write `image_url`.
  `POST /experiments/variants/photo` accepts the same image extensions as an
  observation upload and returns `{ "image_url": ... }`. Both uploads share
  `_store_uploaded_photo` (extension check, chunked write, generated name).
- **Flutter model and service**: `ExperimentVariant.imageUrl`;
  `ExperimentService.uploadVariantPhoto`, plus `imageUrl` on add and an
  explicit `updateImage` flag on update so a cleared photo is sent as null.
  The form sets that flag only when this sheet changed the photo
  (`pickedBytes != null || imageCleared`), so an edit that leaves the photo
  alone does not rewrite `image_url` — a photo saved from another device while
  the form was open survives.
- **Form**: each variant draft can pick and crop with `pickAndCropPlantPhoto`,
  preview the result, or clear it. Bytes stay on the draft until save. Save
  uploads first, then sends the URL with the variant create or update.
  Label and description behavior, including the form's existing text-restore
  on rebuild, is unchanged.
- **Details**: the variant card shows the photo with `PlantImage` when
  `image_url` is non-empty. The compare sheet does not.
- **Copy**: ru, en, de, fr. The preview size is `photoPreview` on the shared
  dimension tokens.

## Behavior

On create or edit, the user taps the photo box on a variant, crops a picture,
and saves. The card on the experiment page shows that picture under the
variant name. Clearing the photo and saving removes it. A variant with no
photo looks as it did before.

Example: experiment «Ёмкости для платиков», variant «подвесной горшок
сетчатый» can have a photo of the mesh pot even when its description is empty
and it has no observations yet.

Replacing or clearing a photo, or deleting the variant, does not delete the
file on disk. A failed save after a successful upload can leave an unreferenced
file. That matches observation photos.

## Consequences

- Existing variants load with `image_url` null until the user adds a photo.
- The live server must run auto-migrate before the client can save a photo.
  This change does not deploy that migration.
- Variant photos and observation photos are independent. Logging an
  observation does not copy the variant photo.
- The compare screen still shows labels and numeric readings only.

## Verification

- `python -m py_compile` on `backend/app/db.py`, `backend/app/schemas.py`,
  and `backend/app/routers/experiments.py`.
- `flutter analyze` on the touched Dart files: no issues.
- `flutter test test/experiment_test.dart`: all tests passed, including
  snake_case `image_url` parsing on `ExperimentVariant`.
- The form and details screen were not opened on a device or in a browser.
