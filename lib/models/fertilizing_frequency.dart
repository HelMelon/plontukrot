import 'fertilizing_growth_season.dart';
import 'quarantine.dart';

/// Stored value meaning «do not fertilize».
const fertilizingFrequencyStop = 0;

/// Whether fertilizing reminders and scheduling should run.
bool isFertilizingActive(int? frequencyDays) =>
    frequencyDays != null && frequencyDays > 0;

/// Maps table STOP (`null`) and legacy empty values to [fertilizingFrequencyStop].
int normalizeFertilizingFrequencyDays(int? days) {
  if (days == null || days <= 0) return fertilizingFrequencyStop;
  return days;
}

/// Recommended fertilizing interval in days for a plant stage and season.
///
/// Returns `null` when fertilizing should stop (СТОП).
int? fertilizingPeriodDays({
  required int stage,
  required FertilizingGrowthSeason season,
}) {
  final normalizedStage = _normalizeStage(stage);
  return switch (season) {
    FertilizingGrowthSeason.springSummer => switch (normalizedStage) {
        1 => 21,
        2 => 14,
        3 => 14,
        4 => 18,
        _ => null,
      },
    FertilizingGrowthSeason.autumnWinter => switch (normalizedStage) {
        1 => null,
        2 => 28,
        3 => 24,
        4 => 28,
        _ => null,
      },
  };
}

/// Auto frequency from current season settings; respects custom override flag.
int? resolveFertilizingFrequencyDays({
  required int stage,
  required FertilizingSeasonSettings seasonSettings,
  required bool isCustom,
  int? currentFrequencyDays,
  DateTime? when,
}) {
  if (isCustom) {
    return normalizeFertilizingFrequencyDays(currentFrequencyDays);
  }
  final season = seasonSettings.growthSeasonForDate(when ?? DateTime.now());
  return normalizeFertilizingFrequencyDays(
    fertilizingPeriodDays(stage: stage, season: season),
  );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Next calendar date when fertilizing is due.
///
/// [anchor] is [lastFertilizedAt] when present, otherwise [createdAt] or [now].
/// When [quarantineUntil] still constrains the first post-quarantine feed,
/// that date wins over the normal interval.
DateTime? nextFertilizingDate({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
  DateTime? quarantineUntil,
  FertilizingGrowthSeason? quarantineSeason,
}) {
  DateTime? normalNext;
  if (frequencyDays != null && frequencyDays > 0) {
    final clock = now ?? DateTime.now();
    final anchor = lastFertilizedAt ?? createdAt ?? clock;
    final anchorDay = _dateOnly(anchor);
    normalNext = anchorDay.add(Duration(days: frequencyDays));
  }

  final season = quarantineSeason;
  final afterQuarantine = season == null
      ? null
      : firstFertilizingAfterQuarantine(
          quarantineUntil: quarantineUntil,
          lastFertilizedAt: lastFertilizedAt,
          season: season,
        );

  if (afterQuarantine == null) return normalNext;
  if (normalNext == null) return afterQuarantine;
  return afterQuarantine.isAfter(normalNext) ? afterQuarantine : normalNext;
}

/// Whether fertilizing is due today or past due (until recorded again).
bool isFertilizingOverdue({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
  bool isArchived = false,
  DateTime? quarantineUntil,
  FertilizingGrowthSeason? quarantineSeason,
}) {
  if (isArchived) return false;
  final next = nextFertilizingDate(
    frequencyDays: frequencyDays,
    lastFertilizedAt: lastFertilizedAt,
    createdAt: createdAt,
    now: now,
    quarantineUntil: quarantineUntil,
    quarantineSeason: quarantineSeason,
  );
  if (next == null) return false;
  final clock = now ?? DateTime.now();
  return !_dateOnly(next).isAfter(_dateOnly(clock));
}

/// Evening reminder (day before feeding) at 19:00 local time.
DateTime? fertilizingEveNotificationAt({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
  DateTime? quarantineUntil,
  FertilizingGrowthSeason? quarantineSeason,
}) {
  final next = nextFertilizingDate(
    frequencyDays: frequencyDays,
    lastFertilizedAt: lastFertilizedAt,
    createdAt: createdAt,
    now: now,
    quarantineUntil: quarantineUntil,
    quarantineSeason: quarantineSeason,
  );
  if (next == null) return null;
  final eve = next.subtract(const Duration(days: 1));
  final scheduled = DateTime(eve.year, eve.month, eve.day, 19);
  final clock = now ?? DateTime.now();
  if (!scheduled.isAfter(clock)) return null;
  return scheduled;
}

/// Feeding-day confirmation at 08:00 local time.
///
/// When due today or overdue, schedules 08:00 today or soon after [now].
DateTime? fertilizingDayNotificationAt({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
  DateTime? quarantineUntil,
  FertilizingGrowthSeason? quarantineSeason,
}) {
  final next = nextFertilizingDate(
    frequencyDays: frequencyDays,
    lastFertilizedAt: lastFertilizedAt,
    createdAt: createdAt,
    now: now,
    quarantineUntil: quarantineUntil,
    quarantineSeason: quarantineSeason,
  );
  if (next == null) return null;
  final clock = now ?? DateTime.now();
  final today = _dateOnly(clock);
  final nextDay = _dateOnly(next);

  if (!nextDay.isAfter(today)) {
    final todayAt8 = DateTime(today.year, today.month, today.day, 8);
    if (clock.isBefore(todayAt8)) return todayAt8;
    return clock.add(const Duration(seconds: 5));
  }

  final scheduled = DateTime(next.year, next.month, next.day, 8);
  if (!scheduled.isAfter(clock)) return null;
  return scheduled;
}

int _normalizeStage(int stage) {
  if (stage <= 0) return 1;
  if (stage > 4) return 4;
  return stage;
}
