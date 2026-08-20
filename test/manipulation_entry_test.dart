import 'package:cloud_firestore/cloud_firestore.dart';
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
        'appliedAt': Timestamp.fromDate(appliedAt),
        'note': 'верхушку',
      });

      expect(entry.id, 'id1');
      expect(entry.type, ManipulationType.pinching);
      expect(entry.appliedAt, appliedAt);
      expect(entry.note, 'верхушку');
    });

    test('fromMap parses rerooting with stages', () {
      final entry = ManipulationEntry.fromMap('id2', {
        'type': 'rerooting',
        'appliedAt': Timestamp.fromDate(DateTime(2026, 3, 11)),
        'stageBefore': 3,
        'stageAfter': 1,
        'note': 'гнилые корни',
      });

      expect(entry.type, ManipulationType.rerooting);
      expect(entry.stageBefore, 3);
      expect(entry.stageAfter, 1);
      expect(entry.note, 'гнилые корни');
    });

    test('fromMap parses stimulator entry', () {
      final entry = ManipulationEntry.fromMap('id3', {
        'type': 'stimulator',
        'appliedAt': Timestamp.fromDate(DateTime(2026, 3, 12)),
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
      expect(map['type'], 'stimulator');
      expect(map['stimulatorName'], 'Kornevin');
      expect(map['dosage'], '1 мл / л');
      expect((map['appliedAt'] as Timestamp).toDate(), appliedAt);
    });
  });
}
