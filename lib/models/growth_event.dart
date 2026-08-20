import 'model_helpers.dart';

enum GrowthEventType {
  newLeaf,
  leafRemoved,
  watering,
  fertilizing,
  repotting,
  trimming,
  pinching;

  String get code => name;

  static GrowthEventType fromCode(dynamic code) {
    return readEnum(code, GrowthEventType.values, GrowthEventType.newLeaf);
  }
}

/// Why a leaf was removed. Stored on `leafRemoved` events as `reason`.
enum LeafRemovalReason {
  cutForRooting,
  eaten,
  dried;

  String get code => name;

  static LeafRemovalReason? fromCode(String? code) {
    if (code == null) return null;
    for (final reason in LeafRemovalReason.values) {
      if (reason.name == code) return reason;
    }
    return null;
  }
}

/// Leaf gained/lost counts for a calendar month (`monthStart` = first day).
class MonthlyLeafStat {
  final DateTime monthStart;
  final int newLeafCount;
  final int removedLeafCount;

  const MonthlyLeafStat({
    required this.monthStart,
    required this.newLeafCount,
    required this.removedLeafCount,
  });
}

class GrowthEvent {
  final String id;
  final GrowthEventType type;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final LeafRemovalReason? reason;

  const GrowthEvent({
    required this.id,
    required this.type,
    this.createdAt,
    this.expiresAt,
    this.reason,
  });

  factory GrowthEvent.fromMap(String id, Map<String, dynamic> data) {
    return GrowthEvent(
      id: id,
      type: GrowthEventType.fromCode(readField(data, 'type')),
      createdAt: readDate(data, 'createdAt'),
      expiresAt: readDate(data, 'expiresAt'),
      reason: LeafRemovalReason.fromCode(readString(data, 'reason')),
    );
  }

  /// Visible leaf count on the vine: baseline + new − removed (never below 0).
  static int displayLeafCount({
    required int initialLeafCount,
    required Iterable<GrowthEvent> events,
  }) {
    var added = 0;
    var removed = 0;
    for (final event in events) {
      switch (event.type) {
        case GrowthEventType.newLeaf:
          added++;
        case GrowthEventType.leafRemoved:
          removed++;
        case GrowthEventType.watering:
        case GrowthEventType.fertilizing:
        case GrowthEventType.repotting:
        case GrowthEventType.trimming:
        case GrowthEventType.pinching:
          break;
      }
    }
    final total = initialLeafCount + added - removed;
    return total < 0 ? 0 : total;
  }

  /// New and removed leaves per calendar month, starting from [now]'s month
  /// going back [months] months (newest first).
  static List<MonthlyLeafStat> leafStatsByMonth(
    Iterable<GrowthEvent> events, {
    int months = 3,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final result = <MonthlyLeafStat>[];

    for (var i = 0; i < months; i++) {
      final monthDate = DateTime(anchor.year, anchor.month - i, 1);
      final start = DateTime(monthDate.year, monthDate.month, 1);
      final end = DateTime(monthDate.year, monthDate.month + 1, 1);

      var gained = 0;
      var lost = 0;
      for (final event in events) {
        final createdAt = event.createdAt;
        if (createdAt == null) continue;
        if (createdAt.isBefore(start) || !createdAt.isBefore(end)) continue;
        switch (event.type) {
          case GrowthEventType.newLeaf:
            gained++;
          case GrowthEventType.leafRemoved:
            lost++;
          case GrowthEventType.watering:
          case GrowthEventType.fertilizing:
          case GrowthEventType.repotting:
          case GrowthEventType.trimming:
          case GrowthEventType.pinching:
            break;
        }
      }

      result.add(
        MonthlyLeafStat(
          monthStart: start,
          newLeafCount: gained,
          removedLeafCount: lost,
        ),
      );
    }

    return result;
  }

  /// Alias kept for call sites that only need the monthly list shape.
  static List<MonthlyLeafStat> newLeavesByMonth(
    Iterable<GrowthEvent> events, {
    int months = 3,
    DateTime? now,
  }) {
    return leafStatsByMonth(events, months: months, now: now);
  }
}
