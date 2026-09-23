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

DateTime quarantineEndDate(DateTime startedAt) {
  final day = DateTime(startedAt.year, startedAt.month, startedAt.day);
  return day.add(const Duration(days: quarantineDurationDays));
}

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
