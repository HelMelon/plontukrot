import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/core/date_time_utils.dart';
import 'package:plontukrot/models/plant.dart';
import 'package:plontukrot/models/propagation.dart';
import 'package:plontukrot/models/propagation_initial_stage.dart';
import 'package:plontukrot/models/propagation_method.dart';
import 'package:plontukrot/models/propagation_outcome.dart';
import 'package:plontukrot/models/propagation_parent_label.dart';
import 'package:plontukrot/models/propagation_stage_entry.dart';
import 'package:plontukrot/models/propagation_status.dart';
import 'package:plontukrot/models/propagation_year_stats.dart';

void main() {
  group('initialStageFor', () {
    test('offset starts at baby (Детка)', () {
      expect(
        initialStageFor(PropagationMethod.offset),
        propagationStageBaby,
      );
    });

    test('division uses chosen baby stage', () {
      expect(
        initialStageFor(
          PropagationMethod.division,
          divisionStage: propagationStageBaby,
        ),
        propagationStageBaby,
      );
    });

    test('division uses chosen juvenile stage', () {
      expect(
        initialStageFor(
          PropagationMethod.division,
          divisionStage: propagationStageJuvenile,
        ),
        propagationStageJuvenile,
      );
    });

    test('cutting starts at start', () {
      expect(
        initialStageFor(PropagationMethod.cutting),
        propagationStageStart,
      );
    });

    test('other methods start at start', () {
      for (final method in [
        PropagationMethod.leaf,
        PropagationMethod.leafFragment,
        PropagationMethod.rhizome,
        PropagationMethod.tuber,
      ]) {
        expect(initialStageFor(method), propagationStageStart, reason: '$method');
      }
    });

    test('division requires initial stage choice', () {
      expect(requiresInitialStageChoice(PropagationMethod.division), isTrue);
      expect(requiresInitialStageChoice(PropagationMethod.cutting), isFalse);
    });
  });

  group('outcomes vs stage', () {
    test('outcome enum covers sold/gifted/traded/lost', () {
      expect(
        PropagationOutcome.values.map((e) => e.code).toList(),
        ['sold', 'gifted', 'traded', 'lost'],
      );
    });

    test('stage history keeps stage when outcome is set', () {
      final entry = PropagationStageEntry(
        stage: propagationStageBaby,
        changedAt: DateTime(2026, 8, 4, 15),
        quantityAlive: 8,
        outcome: PropagationOutcome.sold,
      );
      expect(entry.stage, propagationStageBaby);
      expect(entry.outcome, PropagationOutcome.sold);
      expect(entry.toMap()['stage'], propagationStageBaby);
      expect(entry.toMap()['outcome'], 'sold');
    });

    test('alive is absence of final write-off via counters', () {
      final batch = Propagation(
        id: '1',
        parentPlantId: 'p',
        parentPlantName: 'Hoya',
        parentPlantFamily: '',
        method: PropagationMethod.offset,
        quantity: 10,
        quantityAlive: 6,
        soldQuantity: 1,
        giftedQuantity: 1,
        tradedQuantity: 0,
        lostQuantity: 0,
        stage: propagationStageBaby,
        status: PropagationStatus.active,
        startedAt: DateTime(2026, 8, 1),
      );
      expect(batch.isActive, isTrue);
      expect(batch.quantityAlive, 6);
      expect(batch.soldQuantity + batch.giftedQuantity, 2);
    });
  });

  group('PropagationYearStats', () {
    test('counts mixed outcomes in a started batch', () {
      final year = 2026;
      final items = [
        Propagation(
          id: 'batch',
          parentPlantId: 'p',
          parentPlantName: 'Hoya',
          parentPlantFamily: 'Apocynaceae',
          method: PropagationMethod.offset,
          quantity: 10,
          quantityAlive: 6,
          soldQuantity: 1,
          giftedQuantity: 1,
          tradedQuantity: 0,
          lostQuantity: 0,
          stage: propagationStageJuvenile,
          status: PropagationStatus.active,
          startedAt: DateTime(2026, 3, 1),
        ),
      ];

      final stats = PropagationYearStats.fromList(year, items);
      expect(stats.startedBatches, 1);
      expect(stats.startedQuantity, 10);
      expect(stats.soldQuantity, 1);
      expect(stats.giftedQuantity, 1);
      expect(stats.tradedQuantity, 0);
      expect(stats.lostQuantity, 0);
    });
  });

  group('timeline ordering', () {
    test('same calendar day keeps chronological order by timestamp', () {
      final day = DateTime(2026, 8, 4);
      final baby = PropagationStageEntry(
        id: 'a',
        stage: propagationStageBaby,
        changedAt: DateTime(2026, 8, 4, 10),
      );
      final juvenile = PropagationStageEntry(
        id: 'b',
        stage: propagationStageJuvenile,
        changedAt: DateTime(2026, 8, 4, 15),
      );

      final history = [juvenile, baby]..sort((a, b) {
          final byTime = a.changedAt.compareTo(b.changedAt);
          if (byTime != 0) return byTime;
          return (a.id ?? '').compareTo(b.id ?? '');
        });

      expect(history.map((e) => e.stage).toList(), [
        propagationStageBaby,
        propagationStageJuvenile,
      ]);
      expect(
        DateTime(history[0].changedAt.year, history[0].changedAt.month,
            history[0].changedAt.day),
        day,
      );
      expect(
        DateTime(history[1].changedAt.year, history[1].changedAt.month,
            history[1].changedAt.day),
        day,
      );
      expect(history[1].changedAt.isAfter(history[0].changedAt), isTrue);
    });

    test('dateWithCurrentTime preserves clock time on picked date', () {
      final before = DateTime.now();
      final merged = dateWithCurrentTime(DateTime(2026, 8, 4));
      final after = DateTime.now();
      expect(merged.year, 2026);
      expect(merged.month, 8);
      expect(merged.day, 4);
      final mergedTod = Duration(
        hours: merged.hour,
        minutes: merged.minute,
        seconds: merged.second,
        milliseconds: merged.millisecond,
      );
      final beforeTod = Duration(
        hours: before.hour,
        minutes: before.minute,
        seconds: before.second,
        milliseconds: before.millisecond,
      );
      final afterTod = Duration(
        hours: after.hour,
        minutes: after.minute,
        seconds: after.second,
        milliseconds: after.millisecond + 1,
      );
      expect(mergedTod.inMilliseconds, greaterThanOrEqualTo(beforeTod.inMilliseconds));
      expect(mergedTod.inMilliseconds, lessThanOrEqualTo(afterTod.inMilliseconds));
    });
  });

  group('propagationParentLabel', () {
    test('appends nickname without writing it onto the batch', () {
      final propagation = Propagation(
        id: '1',
        parentPlantId: 'plant-1',
        parentPlantName: 'carnosa',
        parentPlantFamily: '',
        method: PropagationMethod.cutting,
        quantity: 1,
        quantityAlive: 1,
        soldQuantity: 0,
        lostQuantity: 0,
        stage: 1,
        status: PropagationStatus.active,
        startedAt: DateTime(2026, 8, 1),
      );
      final parent = Plant(
        id: 'plant-1',
        genus: 'Hoya',
        species: 'carnosa',
        nickname: 'Бабушка',
        stage: 4,
      );

      expect(
        propagationParentLabel(propagation: propagation, parent: parent),
        'Hoya carnosa «Бабушка»',
      );
      expect(propagation.parentPlantName, 'carnosa');
    });

    test('falls back to stored parent name without plant', () {
      final propagation = Propagation(
        id: '1',
        parentPlantId: 'missing',
        parentPlantName: 'Hoya carnosa',
        parentPlantFamily: '',
        method: PropagationMethod.cutting,
        quantity: 1,
        quantityAlive: 1,
        soldQuantity: 0,
        lostQuantity: 0,
        stage: 1,
        status: PropagationStatus.active,
        startedAt: DateTime(2026, 8, 1),
      );
      expect(
        propagationParentLabel(propagation: propagation, parent: null),
        'Hoya carnosa',
      );
    });
  });
}
