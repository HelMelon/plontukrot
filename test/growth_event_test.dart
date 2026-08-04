import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/growth_event.dart';

void main() {
  group('GrowthEvent.displayLeafCount', () {
    test('uses initial baseline without events', () {
      expect(
        GrowthEvent.displayLeafCount(
          initialLeafCount: 5,
          events: const [],
        ),
        5,
      );
    });

    test('adds newLeaf and subtracts leafRemoved', () {
      final events = [
        const GrowthEvent(id: '1', type: GrowthEventType.newLeaf),
        const GrowthEvent(id: '2', type: GrowthEventType.newLeaf),
        const GrowthEvent(
          id: '3',
          type: GrowthEventType.leafRemoved,
          reason: LeafRemovalReason.eaten,
        ),
      ];
      expect(
        GrowthEvent.displayLeafCount(initialLeafCount: 3, events: events),
        4,
      );
    });

    test('counts leafRemoved regardless of reason', () {
      final events = [
        const GrowthEvent(
          id: '1',
          type: GrowthEventType.leafRemoved,
          reason: LeafRemovalReason.cutForRooting,
        ),
        const GrowthEvent(
          id: '2',
          type: GrowthEventType.leafRemoved,
          reason: LeafRemovalReason.dried,
        ),
        const GrowthEvent(id: '3', type: GrowthEventType.leafRemoved),
      ];
      expect(
        GrowthEvent.displayLeafCount(initialLeafCount: 5, events: events),
        2,
      );
    });

    test('ignores care events for display count', () {
      final events = [
        const GrowthEvent(id: '1', type: GrowthEventType.newLeaf),
        const GrowthEvent(id: '2', type: GrowthEventType.watering),
        const GrowthEvent(id: '3', type: GrowthEventType.fertilizing),
        const GrowthEvent(id: '4', type: GrowthEventType.repotting),
        const GrowthEvent(id: '5', type: GrowthEventType.trimming),
        const GrowthEvent(id: '6', type: GrowthEventType.pinching),
      ];
      expect(
        GrowthEvent.displayLeafCount(initialLeafCount: 2, events: events),
        3,
      );
    });

    test('never goes below zero', () {
      final events = [
        const GrowthEvent(id: '1', type: GrowthEventType.leafRemoved),
        const GrowthEvent(id: '2', type: GrowthEventType.leafRemoved),
      ];
      expect(
        GrowthEvent.displayLeafCount(initialLeafCount: 1, events: events),
        0,
      );
    });
  });

  group('GrowthEvent.leafStatsByMonth', () {
    final now = DateTime(2026, 8, 15);

    test('splits gained and lost across current and previous months', () {
      final events = [
        GrowthEvent(
          id: '1',
          type: GrowthEventType.newLeaf,
          createdAt: DateTime(2026, 8, 4),
        ),
        GrowthEvent(
          id: '2',
          type: GrowthEventType.newLeaf,
          createdAt: DateTime(2026, 8, 10),
        ),
        GrowthEvent(
          id: '3',
          type: GrowthEventType.newLeaf,
          createdAt: DateTime(2026, 7, 20),
        ),
        GrowthEvent(
          id: '4',
          type: GrowthEventType.newLeaf,
          createdAt: DateTime(2026, 6, 1),
        ),
        GrowthEvent(
          id: '5',
          type: GrowthEventType.newLeaf,
          createdAt: DateTime(2026, 5, 30),
        ),
        GrowthEvent(
          id: '6',
          type: GrowthEventType.leafRemoved,
          reason: LeafRemovalReason.eaten,
          createdAt: DateTime(2026, 8, 5),
        ),
        GrowthEvent(
          id: '7',
          type: GrowthEventType.leafRemoved,
          createdAt: DateTime(2026, 7, 2),
        ),
        GrowthEvent(
          id: '8',
          type: GrowthEventType.watering,
          createdAt: DateTime(2026, 8, 5),
        ),
      ];

      final stats = GrowthEvent.leafStatsByMonth(events, now: now);

      expect(stats.length, 3);
      expect(stats[0].monthStart, DateTime(2026, 8, 1));
      expect(stats[0].newLeafCount, 2);
      expect(stats[0].removedLeafCount, 1);
      expect(stats[1].monthStart, DateTime(2026, 7, 1));
      expect(stats[1].newLeafCount, 1);
      expect(stats[1].removedLeafCount, 1);
      expect(stats[2].monthStart, DateTime(2026, 6, 1));
      expect(stats[2].newLeafCount, 1);
      expect(stats[2].removedLeafCount, 0);
    });
  });
}
