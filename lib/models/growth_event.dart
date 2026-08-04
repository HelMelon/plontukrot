import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_helpers.dart';

enum GrowthEventType {
  newLeaf,
  leafRemoved,
  watering,
  fertilizing,
  repotting,
  trimming,
  pinching;

  String get code => name;

  static GrowthEventType fromCode(String? code) {
    return GrowthEventType.values.firstWhere(
      (type) => type.name == code,
      orElse: () => GrowthEventType.newLeaf,
    );
  }
}

/// New-leaf count for a calendar month (`monthStart` = first day of month).
class MonthlyLeafStat {
  final DateTime monthStart;
  final int newLeafCount;

  const MonthlyLeafStat({
    required this.monthStart,
    required this.newLeafCount,
  });
}

class GrowthEvent {
  final String id;
  final GrowthEventType type;
  final DateTime? createdAt;
  final DateTime? expiresAt;

  const GrowthEvent({
    required this.id,
    required this.type,
    this.createdAt,
    this.expiresAt,
  });

  factory GrowthEvent.fromMap(String id, Map<String, dynamic> data) {
    return GrowthEvent(
      id: id,
      type: GrowthEventType.fromCode(data['type'] as String?),
      createdAt: readTimestamp(data['createdAt']),
      expiresAt: readTimestamp(data['expiresAt']),
    );
  }

  factory GrowthEvent.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return GrowthEvent.fromMap(doc.id, doc.data());
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

  /// New leaves per calendar month, starting from [now]'s month going back
  /// [months] months (newest first).
  static List<MonthlyLeafStat> newLeavesByMonth(
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

      var count = 0;
      for (final event in events) {
        if (event.type != GrowthEventType.newLeaf) continue;
        final createdAt = event.createdAt;
        if (createdAt == null) continue;
        if (createdAt.isBefore(start) || !createdAt.isBefore(end)) continue;
        count++;
      }

      result.add(MonthlyLeafStat(monthStart: start, newLeafCount: count));
    }

    return result;
  }
}
