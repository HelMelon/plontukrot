# ADR-058: Plant catalog fields and journal export

## Status

Accepted

## Context

Profile export previously always wrote genus, species, cultivar, and nickname. Users need to choose which identity fields go into the catalog file, and each plant needs its own care journal export.

## Decision

Catalog export (profile) opens a field sheet before sharing. The only selectable fields, in this fixed file order, are:

1. `createdAt` — date added (`yyyy-MM-dd`, or `null`)
2. `family`
3. `genus`
4. `species`
5. `cultivar` (group cultivars joined with ` · `)
6. `stage` — localized stage title
7. `nickname`

All seven start checked. Export with none selected shows an error and stays on the sheet. Unchecked keys are omitted; remaining keys keep this order. Plants stay grouped by stage. Watering frequency, leaf counts, last-care dates, photos, quarantine, and balcony are not part of this export.

Each plant page has a journal export. The file header uses all seven identity fields. Below that, events are grouped by local calendar day, oldest day first. Empty days are omitted. A day lists, in this order: watering, fertilizing (fertilizer name), repotting (soil name), manipulation, note text, propagation.

Propagation is also summarized as `propagationBatchCount`: every batch whose parent is this plant, including archived batches still returned by the API. Each batch appears on its `startedAt` day as a `propagation` event. Manipulations use the localized type plus the details already shown in history (note, stimulator, dosage, reanimation tags, greenhouse, end date, stage change).

Journal history is loaded in full, not capped by the on-screen history page size. Notes without a date or text are skipped. Event type codes stay English in JSON; display strings follow the app locale.

Both exports ask for a format before sharing. JSON is the default. Markdown uses the same data: catalog headings by stage and plant, journal headings by calendar day. Markdown file names end in `.md`. Empty identity values are omitted from Markdown and kept as empty strings in JSON.

## Implementation

- Payload builders: `lib/features/plants/export/plant_export.dart`
- Field sheet: `lib/features/plants/widgets/sheets/export_plant_fields_sheet.dart`
- Profile action shares `plants-YYYY-MM-dd.json` or `plants-YYYY-MM-dd.md`
- Plant details share icon asks for the format, then shares `plant-journal-YYYY-MM-dd.json` or `.md`
- Full-history fetchers on watering, fertilizing, repotting, manipulation, note, and propagation services

## Behavior

Profile → «Экспорт растений» → check fields, choose JSON or Markdown → system share sheet. An empty collection shows a snackbar and does not share.

Plant page → share icon → choose JSON or Markdown → journal file. Example: two batches started on 1 June produce `propagationBatchCount: 2` and two `propagation` events on `2025-06-01`, alongside any watering or note from that day. The Markdown file uses the same days as headings and localized event labels.

## Consequences

- Catalog files no longer always contain the old four-name shape; `fields` lists what was selected.
- Archived propagation batches that the API has already dropped are absent.
- Notes past retention are absent, same as the journal on screen.
- The plant action row has one more icon, so controls are narrower on small phones.

## Verification

- `flutter analyze` on the touched Dart files — no issues
- `flutter test test/plant_export_test.dart` — passed (field order, omitted fields, day grouping, markdown labels)
- Share sheet and small-screen layout were not run on a device
