# ADR-029: Fertilizing reminders

## Status

Accepted

## Context

Users need automated fertilizing reminders based on plant growth stage and seasonal
boundaries. The app had `lastFertilizedAt` on plants but no notification
infrastructure, no fertilizing frequency on the plant document, and no configurable
season settings.

## Decision

### Plant fields

- `fertilizingFrequencyDays` (`int?`) — interval in days; `null` means STOP (do not
  fertilize).
- `isFertilizingFrequencyCustom` (`bool`, default `false`) — when `true`, auto
  recalculation on stage or season change must not overwrite the value.

### Season settings (user profile)

Stored on `users/{uid}` and cached locally (same pattern as locale/currency):

- `fertilizingSeasonMode`: `northern` | `southern` | `custom`
- `fertilizingSpringStartMonth` / `fertilizingSpringEndMonth` (1–12)

Default northern active season: April–September (months 4–9). Southern swaps
boundaries. Custom uses explicit month range. All frequency lookups use these
settings — never hardcoded hemisphere.

### Auto frequency table

Single source of truth: `fertilizingPeriodDays(stage, season)` in
`lib/models/fertilizing_frequency.dart`.

| Stage | Spring/Summer | Autumn/Winter |
|-------|---------------|---------------|
| Start (1) | 21 days | STOP (`null`) |
| Baby (2) | 14 | 28 |
| Juvenile (3) | 14 | 24 |
| Adult (4) | 18 | 28 |

Stage `0` is treated as Start for legacy data.

### Override rules

- On plant **create** and **update**: if `isFertilizingFrequencyCustom == false`,
  frequency is recomputed from stage + current season settings.
- Manual edit or STOP checkbox sets `isFertilizingFrequencyCustom = true`.
- «Reset to automatic» clears custom flag and recomputes.
- Season settings change triggers batch recalculation for non-custom plants and
  notification reschedule for all active plants.

### Groups

For `Plant.isGroup` (≥2 members), stage and frequency live on the group plant
document only; member stages are ignored.

### Notifications

Dependencies: `flutter_local_notifications`, `timezone`, `flutter_timezone`.

Two scheduled local notifications per plant (when frequency is not STOP):

1. **Eve** — day before feeding at **19:00**, localized
   «Завтра подкормка {stage genitive}».
2. **Day** — feeding day at **08:00**, `fullScreenIntent` on Android, action
   «Принято» → sets `lastFertilizedAt` to today, cancels current cycle, schedules
   next.

Reschedule (cancel + plan) when `fertilizingFrequencyDays`, `stage`,
`lastFertilizedAt`, or season settings change.

Permission requested at app bootstrap (splash phase) and from profile settings.

## Implementation

- Models: `fertilizing_growth_season.dart`, `fertilizing_frequency.dart`; Plant
  serialization extended.
- Controller: `FertilizingSeasonController` (`lib/core/season/`).
- Service: `FertilizingNotificationService` (`zonedSchedule`, accept action).
- UI: `FertilizingFrequencyField` in add/update plant sheets; season + notification
  controls on profile page.
- `PlantService` resolves auto frequency on create/update/merge, recalculates on
  season change, reschedules notifications after plant mutations.
- Android: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, boot receivers,
  `USE_FULL_SCREEN_INTENT`.

## Behavior

- New plants get auto frequency from stage and current season unless user overrides.
- STOP (`null` frequency) suppresses all fertilizing notifications for that plant.
- Accept on feeding-day notification records fertilizing for today without opening
  the fertilizing history sheet.

## Consequences

- Exact alarms on Android 12+ may require user allowance for `SCHEDULE_EXACT_ALARM`.
- Notification copy for accept action is resolved at schedule time from current
  locale preference.
- Fertilizing history entries are not created by notification accept (only
  denormalized `lastFertilizedAt`).

## Verification

- `flutter analyze`
- `flutter test test/fertilizing_frequency_test.dart`
- Manual: profile season switch, add plant with auto/custom frequency, permission
  prompt (not run on device in this session).
