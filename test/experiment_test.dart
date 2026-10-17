import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/experiment.dart';
import 'package:plontukrot/models/experiment_observation.dart';
import 'package:plontukrot/models/experiment_subject.dart';
import 'package:plontukrot/models/experiment_variant.dart';

void main() {
  group('ExperimentSubjectType', () {
    test('parses backend string codes', () {
      expect(ExperimentSubjectType.fromCode('plant'),
          ExperimentSubjectType.plant);
      expect(ExperimentSubjectType.fromCode('propagation'),
          ExperimentSubjectType.propagation);
    });

    test('falls back to plant for unknown codes', () {
      expect(ExperimentSubjectType.fromCode('nonsense'),
          ExperimentSubjectType.plant);
      expect(ExperimentSubjectType.fromCode(null),
          ExperimentSubjectType.plant);
    });

    test('bool extension getters', () {
      expect(ExperimentSubjectType.plant.isPlant, isTrue);
      expect(ExperimentSubjectType.plant.isPropagation, isFalse);
      expect(ExperimentSubjectType.propagation.isPropagation, isTrue);
    });
  });

  group('ExperimentObservation', () {
    test('reads snake_case API fields and keeps nulls', () {
      final observation = ExperimentObservation.fromMap('o1', {
        'subject_id': 's1',
        'observed_at': '2026-10-05T18:30:00',
        'note': 'первый замер',
        'height_cm': 12.5,
        'leaf_count': 4,
        'moisture': 47.0,
      });
      expect(observation.subjectId, 's1');
      expect(observation.note, 'первый замер');
      expect(observation.heightCm, 12.5);
      expect(observation.leafCount, 4);
      expect(observation.moisture, 47.0);
      expect(observation.hasMetrics, isTrue);
    });

    test('hasMetrics is false when no number was recorded', () {
      final observation = ExperimentObservation.fromMap('o1', {
        'subject_id': 's1',
        'observed_at': '2026-10-05T18:30:00',
        'note': 'только текст',
      });
      expect(observation.hasMetrics, isFalse);
      expect(observation.heightCm, isNull);
    });
  });

  group('Experiment.fromMap', () {
    Map<String, dynamic> payload() => {
          'id': 'e1',
          'title': 'Кокос против грунта',
          'hypothesis': 'в кокосе быстрее',
          'started_at': '2026-10-05T10:00:00',
          'variants': [
            {
              'id': 'v2',
              'label': 'в грунте',
              'position': 1,
              'observation_count': 1,
              'observations': [
                {
                  'id': 'o2',
                  'subject_id': 's2',
                  'observed_at': '2026-10-06T10:00:00',
                  'note': 'только текстовое наблюдение',
                },
              ],
              'subjects': [
                {
                  'id': 's2',
                  'subject_type': 'plant',
                  'subject_id': 'p2',
                  'subject_name': 'Регал',
                },
              ],
            },
            {
              'id': 'v1',
              'label': 'в кокосе',
              'position': 0,
              'observation_count': 2,
              'observations': [
                {
                  'id': 'o1',
                  'subject_id': 's1',
                  'observed_at': '2026-10-05T10:00:00',
                  'height_cm': 12.5,
                  'leaf_count': 4,
                  'moisture': 47.0,
                },
              ],
              'subjects': [
                {
                  'id': 's1',
                  'subject_type': 'propagation',
                  'subject_id': 'b1',
                  'subject_name': 'монстера',
                },
              ],
            },
          ],
        };

    test('parses variants and sorts them by position', () {
      final experiment = Experiment.fromMap('e1', payload());
      expect(experiment.title, 'Кокос против грунта');
      expect(experiment.variants.map((v) => v.label).toList(),
          ['в кокосе', 'в грунте']);
    });

    test('aggregates counts across variants', () {
      final experiment = Experiment.fromMap('e1', payload());
      expect(experiment.variantCount, 2);
      expect(experiment.observationCount, 3);
    });

    test('comparableVariants keeps only variants with a numeric reading', () {
      final experiment = Experiment.fromMap('e1', payload());
      final comparable = experiment.comparableVariants;
      expect(comparable.length, 1);
      expect(comparable.first.label, 'в кокосе');
      expect(comparable.first.latestWithMetrics?.heightCm, 12.5);
    });

    test('variant without metrics has no latestWithMetrics', () {
      final experiment = Experiment.fromMap('e1', payload());
      final ground = experiment.variants.firstWhere((v) => v.label == 'в грунте');
      expect(ground.latestWithMetrics, isNull);
      expect(ground.observationCount, 1);
    });

    test('missing variants list yields an empty, non-null list', () {
      final experiment = Experiment.fromMap('e1', {'title': 'Пусто'});
      expect(experiment.variants, isEmpty);
      expect(experiment.observationCount, 0);
    });

    test('isCompleted follows completed_at', () {
      final open = Experiment.fromMap('e1', payload());
      expect(open.isCompleted, isFalse);
      final done = Experiment.fromMap('e1', {
        ...payload(),
        'completed_at': '2026-11-01T12:00:00',
      });
      expect(done.isCompleted, isTrue);
    });
  });

  group('ExperimentVariant image', () {
    test('reads snake_case image_url and keeps a missing photo null', () {
      final withPhoto = ExperimentVariant.fromMap('v1', {
        'label': 'подвесной горшок сетчатый',
        'position': 0,
        'image_url': 'https://example.test/photos/experiments/variants/u/a.jpg',
      });
      expect(withPhoto.imageUrl,
          'https://example.test/photos/experiments/variants/u/a.jpg');
      expect(withPhoto.toMap()['image_url'], withPhoto.imageUrl);

      final withoutPhoto = ExperimentVariant.fromMap('v2', {
        'label': 'в грунте',
        'imageUrl': null,
        'position': 1,
      });
      expect(withoutPhoto.imageUrl, isNull);
      expect(withoutPhoto.toMap().containsKey('image_url'), isFalse);
    });
  });

  group('ExperimentVariant.latestWithMetrics', () {
    test('picks the newest observation that has numbers', () {
      final variant = ExperimentVariant.fromMap('v1', {
        'label': 'в кокосе',
        'position': 0,
        'observations': [
          {
            'id': 'o1',
            'subject_id': 's1',
            'observed_at': '2026-10-05T10:00:00',
            'height_cm': 10,
          },
          {
            'id': 'o2',
            'subject_id': 's1',
            'observed_at': '2026-10-07T10:00:00',
            'note': 'без чисел',
          },
          {
            'id': 'o3',
            'subject_id': 's1',
            'observed_at': '2026-10-09T10:00:00',
            'height_cm': 15,
          },
        ],
      });
      expect(variant.latestWithMetrics?.heightCm, 15);
    });
  });

  group('membershipsForSubject', () {
    ExperimentSubject subject(ExperimentSubjectType type, String id) {
      return ExperimentSubject(
        id: 'row-$type-$id',
        subjectType: type,
        subjectId: id,
      );
    }

    ExperimentVariant arm(
      String id,
      String label,
      List<ExperimentSubject> subjects,
    ) {
      return ExperimentVariant(
        id: id,
        label: label,
        position: 0,
        subjects: subjects,
      );
    }

    Experiment trial(
      String id, {
      List<ExperimentVariant> variants = const [],
      DateTime? completedAt,
      DateTime? archivedAt,
    }) {
      return Experiment(
        id: id,
        title: id,
        variants: variants,
        completedAt: completedAt,
        archivedAt: archivedAt,
      );
    }

    test('returns each experiment that includes the subject, in input order', () {
      final plant = subject(ExperimentSubjectType.plant, 'p1');
      final other = subject(ExperimentSubjectType.plant, 'p2');
      final experiments = [
        trial('newer', variants: [
          arm('v1', 'в кокосе', [plant]),
        ]),
        trial('older', variants: [
          arm('v2', 'в грунте', [other]),
        ]),
        trial('also', variants: [
          arm('v3', 'на балконе', [plant]),
        ]),
      ];

      final memberships = membershipsForSubject(
        experiments,
        subjectType: ExperimentSubjectType.plant,
        subjectId: 'p1',
      );

      expect(memberships.map((item) => item.experiment.id), ['newer', 'also']);
      expect(memberships.first.variantLabels, ['в кокосе']);
      expect(memberships.last.variantLabels, ['на балконе']);
    });

    test('lists every variant of one experiment and ignores the other type', () {
      final plant = subject(ExperimentSubjectType.plant, 'same');
      final batch = subject(ExperimentSubjectType.propagation, 'same');
      final experiments = [
        trial('e1', variants: [
          arm('v1', 'в кокосе', [plant]),
          arm('v2', '  ', [plant]),
          arm('v3', 'в кокосе', [plant]),
          arm('v4', 'в грунте', [batch]),
        ]),
      ];

      final plantMemberships = membershipsForSubject(
        experiments,
        subjectType: ExperimentSubjectType.plant,
        subjectId: 'same',
      );
      final batchMemberships = membershipsForSubject(
        experiments,
        subjectType: ExperimentSubjectType.propagation,
        subjectId: 'same',
      );

      expect(plantMemberships, hasLength(1));
      expect(plantMemberships.single.variantLabels, ['в кокосе']);
      expect(batchMemberships.single.variantLabels, ['в грунте']);
    });

    test('keeps finished and archived experiments and skips an empty id', () {
      final plant = subject(ExperimentSubjectType.plant, 'p1');
      final experiments = [
        trial(
          'done',
          variants: [arm('v1', 'горшок', [plant])],
          completedAt: DateTime(2026, 10, 1),
          archivedAt: DateTime(2026, 10, 2),
        ),
      ];

      expect(
        membershipsForSubject(
          experiments,
          subjectType: ExperimentSubjectType.plant,
          subjectId: 'p1',
        ).single.experiment.id,
        'done',
      );
      expect(
        membershipsForSubject(
          experiments,
          subjectType: ExperimentSubjectType.plant,
          subjectId: '  ',
        ),
        isEmpty,
      );
      expect(
        membershipsForSubject(
          experiments,
          subjectType: ExperimentSubjectType.plant,
          subjectId: 'missing',
        ),
        isEmpty,
      );
    });
  });
}
