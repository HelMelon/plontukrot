# ADR-079: Icon-only quarantine badge on the home grid

## Status

Accepted

## Context

The home grid card draws the quarantine mark as an overlay on the thumbnail,
top-left, stacked under the moisture badge. With a two-column phone grid the
thumbnail is about 200 pt wide, so the labeled pill («Карантин» plus a shield
icon) covers a large part of the photo and crowds the moisture reading right
next to it. The same card type is used elsewhere — friend collections, genus
and stage lists, the family sheet — and the gallery card
(`plant_image_card.dart`) has its own overlay, where the labeled pill still
reads well.

## Decision

`QuarantineBadge` takes an `iconOnly` flag, off by default, and the home grid
sets it to `true`. There the badge becomes a yellow clock with no visible word;
elsewhere the pill keeps its icon and label.

The word is not lost: the badge keeps the `a11yPlantQuarantine` semantics label
in both variants, and the icon-only form adds a `Tooltip` with the same text,
excluded from semantics so screen readers do not announce it twice.

## Implementation

- `QuarantineBadge.iconOnly` — one `DecoratedBox`; the variant only swaps the
  child (icon, or icon + label) and wraps the icon-only form in a `Tooltip`.
- `PlantCard.iconOnlyQuarantineBadge` (default `false`) forwards the flag to the
  badge on the photo overlay.
- `home_page.dart` passes `true`; every other `PlantCard` caller keeps the
  labeled pill.
- Icon token `clock` (`Icons.access_time_outlined`) added to `AppIconTokens`,
  including `copyWith`.

## Behavior

A quarantined plant in the home grid shows a small yellow clock on the photo.
Tapping or long-pressing the card is unchanged. On every other screen the badge
still reads «Карантин». Screen readers announce the quarantine state in both
places.

## Consequences

- The home thumbnail keeps more of its picture and the moisture badge keeps its
  space.
- Two visual variants of one badge now exist, so a change to the badge has to
  be checked on both forms.
- The home grid no longer states the word in text, only on hover/long-press
  (tooltip) and in the accessibility label.

## Verification

- `flutter analyze` — no issues in the touched Dart files.
- `flutter test test/plant_card_image_test.dart` — 3 tests passed, with the card
  rendered at the geometry the home grid computes for both the phone cell and
  the wide landscape cell.
- Not checked on a device: the tooltip on a touch screen and the exact clock
  size against the moisture badge.
