import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/manipulation_entry.dart';
import 'package:plontukrot/models/manipulation_type.dart';
import 'package:plontukrot/models/reanimation_tag.dart';

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

  group('ReanimationTag', () {
    test('tryParse parses codes and camelCase', () {
      expect(ReanimationTag.tryParse('rerooting'), ReanimationTag.rerooting);
      expect(ReanimationTag.tryParse('soil_flush'), ReanimationTag.soilFlush);
      expect(ReanimationTag.tryParse('soilFlush'), ReanimationTag.soilFlush);
      expect(ReanimationTag.tryParse('rot_trimming'), ReanimationTag.rotTrimming);
      expect(ReanimationTag.tryParse('rotTrimming'), ReanimationTag.rotTrimming);
      expect(ReanimationTag.tryParse('invalid'), isNull);
      expect(ReanimationTag.tryParse(null), isNull);
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

    test('fromMap parses rerooting with stages, endedAt, tags, greenhouse', () {
      final entry = ManipulationEntry.fromMap('id2', {
        'type': 'rerooting',
        'appliedAt': DateTime(2026, 3, 11),
        'endedAt': DateTime(2026, 3, 20),
        'reanimationTags': ['rerooting', 'rot_trimming'],
        'isGreenhouse': true,
        'stageBefore': 3,
        'stageAfter': 1,
        'note': 'гнилые корни',
      });

      expect(entry.type, ManipulationType.rerooting);
      expect(entry.appliedAt, DateTime(2026, 3, 11));
      expect(entry.endedAt, DateTime(2026, 3, 20));
      expect(entry.reanimationTags, [
        ReanimationTag.rerooting,
        ReanimationTag.rotTrimming,
      ]);
      expect(entry.isGreenhouse, isTrue);
      expect(entry.stageBefore, 3);
      expect(entry.stageAfter, 1);
      expect(entry.note, 'гнилые корни');
    });

    test('fromMap parses snake_case ended_at, reanimation_tags, and is_greenhouse', () {
      final entry = ManipulationEntry.fromMap('id2_snake', {
        'type': 1,
        'applied_at': '2026-03-11T00:00:00.000Z',
        'ended_at': '2026-03-20T00:00:00.000Z',
        'reanimation_tags': ['soil_flush'],
        'is_greenhouse': true,
        'stage_before': 3,
        'stage_after': 1,
      });

      expect(entry.type, ManipulationType.rerooting);
      expect(entry.endedAt, isNotNull);
      expect(entry.reanimationTags, [ReanimationTag.soilFlush]);
      expect(entry.isGreenhouse, isTrue);
      expect(entry.stageBefore, 3);
      expect(entry.stageAfter, 1);
    });

    test('toMap round-trips rerooting endedAt, tags, and greenhouse', () {
      final appliedAt = DateTime(2026, 3, 11);
      final endedAt = DateTime(2026, 3, 20);
      final entry = ManipulationEntry(
        id: 'id2',
        type: ManipulationType.rerooting,
        appliedAt: appliedAt,
        endedAt: endedAt,
        reanimationTags: const [
          ReanimationTag.rerooting,
          ReanimationTag.rotTrimming,
        ],
        isGreenhouse: true,
        stageBefore: 3,
        stageAfter: 1,
      );

      final map = entry.toMap();
      expect(map['type'], ManipulationType.rerooting.index);
      expect(map['endedAt'], isNotNull);
      expect(map['ended_at'], isNotNull);
      expect(map['reanimationTags'], ['rerooting', 'rot_trimming']);
      expect(map['reanimation_tags'], ['rerooting', 'rot_trimming']);
      expect(map['isGreenhouse'], isTrue);
      expect(map['is_greenhouse'], isTrue);
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
