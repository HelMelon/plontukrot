import 'experiment_variant.dart';
import 'model_helpers.dart';

/// A comparative trial: a hypothesis, several variants, and (per participant) an
/// observation log. See [ExperimentVariant] for the compared arms.
class Experiment {
  final String id;
  final String title;
  final String? hypothesis;
  final String? note;
  final DateTime? startedAt;
  final String? conclusion;
  final DateTime? completedAt;
  final DateTime? archivedAt;
  final List<ExperimentVariant> variants;
  final DateTime? createdAt;

  const Experiment({
    required this.id,
    required this.title,
    this.hypothesis,
    this.note,
    this.startedAt,
    this.conclusion,
    this.completedAt,
    this.archivedAt,
    this.variants = const [],
    this.createdAt,
  });

  bool get isCompleted => completedAt != null;

  bool get isArchived => archivedAt != null;

  int get variantCount => variants.length;

  int get observationCount =>
      variants.fold(0, (sum, variant) => sum + variant.observationCount);

  /// Days elapsed since the trial started, floored at zero.
  int get daysSinceStart {
    final start = startedAt;
    if (start == null) return 0;
    final now = DateTime.now();
    final from = DateTime(start.year, start.month, start.day);
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(from).inDays;
    return days < 0 ? 0 : days;
  }

  /// Variants that carry at least one numeric reading — the compare table rows.
  List<ExperimentVariant> get comparableVariants =>
      variants.where((variant) => variant.latestWithMetrics != null).toList();

  factory Experiment.fromMap(String id, Map<String, dynamic> data) {
    final raw = readField(data, 'variants');
    final variants = <ExperimentVariant>[];
    if (raw is List) {
      for (final entry in raw.whereType<Map>()) {
        final map = Map<String, dynamic>.from(entry);
        variants.add(
          ExperimentVariant.fromMap(readString(map, 'id') ?? '', map),
        );
      }
      variants.sort((a, b) => a.position.compareTo(b.position));
    }
    return Experiment(
      id: id,
      title: readString(data, 'title') ?? '',
      hypothesis: readString(data, 'hypothesis'),
      note: readString(data, 'note'),
      startedAt: readDate(data, 'startedAt'),
      conclusion: readString(data, 'conclusion'),
      completedAt: readDate(data, 'completedAt'),
      archivedAt: readDate(data, 'archivedAt'),
      variants: variants,
      createdAt: readDate(data, 'createdAt'),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        if (hypothesis != null) 'hypothesis': hypothesis,
        if (note != null) 'note': note,
        if (startedAt != null) 'started_at': isoOrNull(startedAt),
        if (conclusion != null) 'conclusion': conclusion,
        if (completedAt != null) 'completed_at': isoOrNull(completedAt),
        if (archivedAt != null) 'archived_at': isoOrNull(archivedAt),
      };
}
