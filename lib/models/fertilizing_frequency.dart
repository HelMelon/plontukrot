import 'fertilizing_growth_season.dart';

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

/// Next calendar date when fertilizing is due.
///
/// [anchor] is [lastFertilizedAt] when present, otherwise [createdAt] or [now].
DateTime? nextFertilizingDate({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
}) {
  if (frequencyDays == null || frequencyDays <= 0) return null;
  final clock = now ?? DateTime.now();
  final anchor = lastFertilizedAt ?? createdAt ?? clock;
  final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
  return anchorDay.add(Duration(days: frequencyDays));
}

/// Evening reminder (day before feeding) at 19:00 local time.
DateTime? fertilizingEveNotificationAt({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
}) {
  final next = nextFertilizingDate(
    frequencyDays: frequencyDays,
    lastFertilizedAt: lastFertilizedAt,
    createdAt: createdAt,
    now: now,
  );
  if (next == null) return null;
  final eve = next.subtract(const Duration(days: 1));
  final scheduled = DateTime(eve.year, eve.month, eve.day, 19);
  final clock = now ?? DateTime.now();
  if (!scheduled.isAfter(clock)) return null;
  return scheduled;
}

/// Feeding-day confirmation at 08:00 local time.
DateTime? fertilizingDayNotificationAt({
  required int? frequencyDays,
  DateTime? lastFertilizedAt,
  DateTime? createdAt,
  DateTime? now,
}) {
  final next = nextFertilizingDate(
    frequencyDays: frequencyDays,
    lastFertilizedAt: lastFertilizedAt,
    createdAt: createdAt,
    now: now,
  );
  if (next == null) return null;
  final scheduled = DateTime(next.year, next.month, next.day, 8);
  final clock = now ?? DateTime.now();
  if (!scheduled.isAfter(clock)) return null;
  return scheduled;
}

int _normalizeStage(int stage) {
  if (stage <= 0) return 1;
  if (stage > 4) return 4;
  return stage;
}
