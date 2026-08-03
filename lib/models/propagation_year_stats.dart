import '../models/propagation.dart';
import '../models/propagation_method.dart';
import '../models/propagation_status.dart';

class PropagationYearStats {
  final int year;
  final int startedBatches;
  final int startedQuantity;
  final int soldQuantity;
  final int lostQuantity;
  final Map<PropagationMethod, int> byMethod;
  final Map<String, int> byFamily;

  const PropagationYearStats({
    required this.year,
    required this.startedBatches,
    required this.startedQuantity,
    required this.soldQuantity,
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

      // Cumulative sold/lost attributed to current year if event/archive falls in year,
      // otherwise if still active, count known sold/lost totals started this year.
      final soldAt = item.soldAt;
      final archivedAt = item.archivedAt;

      if (soldAt != null &&
          !soldAt.isBefore(yearStart) &&
          soldAt.isBefore(yearEnd)) {
        soldQuantity += item.soldQuantity;
      } else if (startedInYear &&
          item.soldQuantity > 0 &&
          item.status == PropagationStatus.active) {
        soldQuantity += item.soldQuantity;
      }

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
      lostQuantity: lostQuantity,
      byMethod: byMethod,
      byFamily: byFamily,
    );
  }
}
