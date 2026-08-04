import '../models/propagation.dart';
import '../models/propagation_method.dart';
import '../models/propagation_status.dart';

class PropagationYearStats {
  final int year;
  final int startedBatches;
  final int startedQuantity;
  final int soldQuantity;
  final int giftedQuantity;
  final int tradedQuantity;
  final int lostQuantity;
  final Map<PropagationMethod, int> byMethod;
  final Map<String, int> byFamily;

  const PropagationYearStats({
    required this.year,
    required this.startedBatches,
    required this.startedQuantity,
    required this.soldQuantity,
    this.giftedQuantity = 0,
    this.tradedQuantity = 0,
    required this.lostQuantity,
    required this.byMethod,
    required this.byFamily,
  });

  factory PropagationYearStats.fromList(int year, List<Propagation> items) {
    final yearStart = DateTime(year);
    final yearEnd = DateTime(year + 1);

    var startedBatches = 0;
    var startedQuantity = 0;
    var soldQuantity = 0;
    var giftedQuantity = 0;
    var tradedQuantity = 0;
    var lostQuantity = 0;
    final byMethod = <PropagationMethod, int>{};
    final byFamily = <String, int>{};

    for (final item in items) {
      final startedInYear =
          !item.startedAt.isBefore(yearStart) && item.startedAt.isBefore(yearEnd);

      if (startedInYear) {
        startedBatches += 1;
        startedQuantity += item.quantity;
        byMethod.update(
          item.method,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
        // Empty key = no family; localize only when rendering UI.
        final family = item.parentPlantFamily.trim();
        byFamily.update(
          family,
          (value) => value + item.quantity,
          ifAbsent: () => item.quantity,
        );
      }

      final archivedAt = item.archivedAt;
      final soldAt = item.soldAt;

      if (soldAt != null &&
          !soldAt.isBefore(yearStart) &&
          soldAt.isBefore(yearEnd)) {
        soldQuantity += item.soldQuantity;
      } else if (startedInYear &&
          item.soldQuantity > 0 &&
          item.status == PropagationStatus.active) {
        soldQuantity += item.soldQuantity;
      }

      giftedQuantity += _outcomeInYear(
        quantity: item.giftedQuantity,
        startedInYear: startedInYear,
        archivedAt: archivedAt,
        yearStart: yearStart,
        yearEnd: yearEnd,
        status: item.status,
      );

      tradedQuantity += _outcomeInYear(
        quantity: item.tradedQuantity,
        startedInYear: startedInYear,
        archivedAt: archivedAt,
        yearStart: yearStart,
        yearEnd: yearEnd,
        status: item.status,
      );

      if (item.lostQuantity > 0) {
        final lostInYear = (archivedAt != null &&
                !archivedAt.isBefore(yearStart) &&
                archivedAt.isBefore(yearEnd)) ||
            (startedInYear && item.status == PropagationStatus.active);
        if (lostInYear) {
          lostQuantity += item.lostQuantity;
        }
      }
    }

    return PropagationYearStats(
      year: year,
      startedBatches: startedBatches,
      startedQuantity: startedQuantity,
      soldQuantity: soldQuantity,
      giftedQuantity: giftedQuantity,
      tradedQuantity: tradedQuantity,
      lostQuantity: lostQuantity,
      byMethod: byMethod,
      byFamily: byFamily,
    );
  }

  static int _outcomeInYear({
    required int quantity,
    required bool startedInYear,
    required DateTime? archivedAt,
    required DateTime yearStart,
    required DateTime yearEnd,
    required PropagationStatus status,
  }) {
    if (quantity <= 0) return 0;
    final inYear = (archivedAt != null &&
            !archivedAt.isBefore(yearStart) &&
            archivedAt.isBefore(yearEnd)) ||
        (startedInYear && status == PropagationStatus.active);
    return inYear ? quantity : 0;
  }
}
