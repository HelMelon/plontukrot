import 'fertilizing_growth_season.dart';
import 'quarantine_reason.dart';

/// Fixed quarantine length after purchase, manual enable, or repotting.
const quarantineDurationDays = 14;

/// Days after quarantine ends before the first fertilizing is due.
int quarantineFertilizingDelayDays(FertilizingGrowthSeason season) {
  return switch (season) {
    FertilizingGrowthSeason.springSummer => 14,
    FertilizingGrowthSeason.autumnWinter => 21,
  };
}

/// Calendar day of [value] in local time.
DateTime quarantineCalendarDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime quarantineEndDate(DateTime startedAt) {
  return quarantineCalendarDay(startedAt)
      .add(const Duration(days: quarantineDurationDays));
}

/// Start day implied by a stored end (`until` minus 14 days).
DateTime quarantineStartDate(DateTime until) => quarantineCalendarDay(until)
    .subtract(const Duration(days: quarantineDurationDays));

bool isSameQuarantineDay(DateTime a, DateTime b) =>
    quarantineCalendarDay(a) == quarantineCalendarDay(b);

/// Today. A future start is not stored separately: only `quarantine_until`
/// exists, so a start after today would already look active.
DateTime latestQuarantineStart(DateTime now) => quarantineCalendarDay(now);

/// Earliest start that is still inside the 14-day window at [now].
DateTime earliestActiveQuarantineStart(DateTime now) =>
    latestQuarantineStart(now).subtract(
      const Duration(days: quarantineDurationDays - 1),
    );

bool isPlantInQuarantine({
  DateTime? quarantineUntil,
  DateTime? now,
}) {
  final until = quarantineUntil;
  if (until == null) return false;
  final clock = now ?? DateTime.now();
  return until.isAfter(clock);
}

/// First fertilizing calendar day after quarantine, or `null` when quarantine
/// does not constrain the schedule (no until, or already fertilized after it).
DateTime? firstFertilizingAfterQuarantine({
  DateTime? quarantineUntil,
  DateTime? lastFertilizedAt,
  required FertilizingGrowthSeason season,
}) {
  final until = quarantineUntil;
  if (until == null) return null;
  final untilDay = DateTime(until.year, until.month, until.day);
  final last = lastFertilizedAt;
  if (last != null) {
    final lastDay = DateTime(last.year, last.month, last.day);
    if (lastDay.isAfter(untilDay)) return null;
  }
  return untilDay.add(
    Duration(days: quarantineFertilizingDelayDays(season)),
  );
}

QuarantineReason? parseQuarantineReason(String? raw) =>
    QuarantineReason.tryParse(raw);
