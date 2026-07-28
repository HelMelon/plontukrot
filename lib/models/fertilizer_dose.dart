const List<int> kWaterVolumesMl = [250, 500, 1000];

enum FertilizerDoseUnit { g, ml }

FertilizerDoseUnit parseFertilizerDoseUnit(String? raw) {
  if (raw == 'ml') return FertilizerDoseUnit.ml;
  return FertilizerDoseUnit.g;
}

int normalizeWaterMl(int? raw) {
  if (raw != null && kWaterVolumesMl.contains(raw)) return raw;
  return 250;
}

class FertilizerDose {
  final String component;
  final double amount;
  final FertilizerDoseUnit unit;

  const FertilizerDose({
    required this.component,
    required this.amount,
    this.unit = FertilizerDoseUnit.g,
  });

  double get grams => amount;

  factory FertilizerDose.fromMap(Map<String, dynamic> data) {
    final rawAmount = (data['amount'] as num?)?.toDouble() ??
        (data['grams'] as num?)?.toDouble() ??
        0;
    return FertilizerDose(
      component: data['component'] as String? ?? '',
      amount: rawAmount < 0 ? 0 : rawAmount,
      unit: parseFertilizerDoseUnit(data['unit'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'component': component,
      'amount': amount,
      'unit': unit == FertilizerDoseUnit.ml ? 'ml' : 'g',
    };
  }

  String get unitLabel => unit == FertilizerDoseUnit.ml ? 'мл' : 'г';

  String get label {
    final value = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    return '$component · $value$unitLabel';
  }
}
