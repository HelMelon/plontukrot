import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/manipulation_entry.dart';
import 'package:plontukrot/models/manipulation_type.dart';

void main() {
  group('ManipulationType', () {
    test('fromCode resolves known values', () {
      expect(
        ManipulationType.fromCode('rerooting'),
        ManipulationType.rerooting,
      );
      expect(
        ManipulationType.fromCode('stimulator'),
        ManipulationType.stimulator,
      );
    });

    test('fromCode falls back to pinching', () {
      expect(
        ManipulationType.fromCode('unknown'),
        ManipulationType.pinching,
      );
    });
  });

  group('ManipulationEntry', () {
    test('fromMap parses pinching entry', () {
      final appliedAt = DateTime(2026, 3, 10);
      final entry = ManipulationEntry.fromMap('id1', {
        'type': 'pinching',
        'appliedAt': appliedAt,
        'note': 'верхушку',
      });

      expect(entry.id, 'id1');
      expect(entry.type, ManipulationType.pinching);
      expect(entry.appliedAt, appliedAt);
      expect(entry.note, 'верхушку');
    });

    test('fromMap parses rerooting with stages and endedAt', () {
      final entry = ManipulationEntry.fromMap('id2', {
        'type': 'rerooting',
        'appliedAt': DateTime(2026, 3, 11),
        'endedAt': DateTime(2026, 3, 20),
        'stageBefore': 3,
        'stageAfter': 1,
        'note': 'гнилые корни',
      });

      expect(entry.type, ManipulationType.rerooting);
      expect(entry.appliedAt, DateTime(2026, 3, 11));
      expect(entry.endedAt, DateTime(2026, 3, 20));
      expect(entry.stageBefore, 3);
      expect(entry.stageAfter, 1);
      expect(entry.note, 'гнилые корни');
    });

    test('fromMap parses snake_case ended_at', () {
      final entry = ManipulationEntry.fromMap('id2_snake', {
        'type': 1,
        'applied_at': '2026-03-11T00:00:00.000Z',
        'ended_at': '2026-03-20T00:00:00.000Z',
        'stage_before': 3,
        'stage_after': 1,
      });

      expect(entry.type, ManipulationType.rerooting);
      expect(entry.endedAt, isNotNull);
      expect(entry.stageBefore, 3);
      expect(entry.stageAfter, 1);
    });

    test('toMap round-trips rerooting endedAt', () {
      final appliedAt = DateTime(2026, 3, 11);
      final endedAt = DateTime(2026, 3, 20);
      final entry = ManipulationEntry(
        id: 'id2',
        type: ManipulationType.rerooting,
        appliedAt: appliedAt,
        endedAt: endedAt,
        stageBefore: 3,
        stageAfter: 1,
      );

      final map = entry.toMap();
      expect(map['type'], ManipulationType.rerooting.index);
      expect(map['endedAt'], isNotNull);
      expect(map['ended_at'], isNotNull);
      expect(DateTime.parse(map['endedAt'] as String).toUtc(), endedAt.toUtc());
    });

    test('fromMap parses stimulator entry', () {
      final entry = ManipulationEntry.fromMap('id3', {
        'type': 'stimulator',
        'appliedAt': DateTime(2026, 3, 12),
        'stimulatorId': 'stim1',
        'stimulatorName': 'Kornevin',
        'dosage': '1 мл / л',
      });

      expect(entry.type, ManipulationType.stimulator);
      expect(entry.stimulatorId, 'stim1');
      expect(entry.stimulatorName, 'Kornevin');
      expect(entry.dosage, '1 мл / л');
    });

    test('toMap round-trips stimulator fields', () {
      final appliedAt = DateTime(2026, 3, 12);
      final entry = ManipulationEntry(
        id: 'id3',
        type: ManipulationType.stimulator,
        appliedAt: appliedAt,
        stimulatorName: 'Kornevin',
        dosage: '1 мл / л',
      );

      final map = entry.toMap();
      expect(map['type'], ManipulationType.stimulator.index);
      expect(map['stimulatorName'], 'Kornevin');
      expect(map['dosage'], '1 мл / л');
      expect(DateTime.parse(map['appliedAt'] as String).toUtc(), appliedAt.toUtc());
    });
  });
}
