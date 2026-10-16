import 'variegation.dart';

class BotanicalPrefillResult {
  final String? genus;
  final String? species;
  final String? cultivar;
  final String? plantFamily;
  final String? tradingName;
  final bool isHybrid;
  final Variegation variegation;

  const BotanicalPrefillResult({
    this.genus,
    this.species,
    this.cultivar,
    this.plantFamily,
    this.tradingName,
    this.isHybrid = false,
    this.variegation = Variegation.none,
  });

  factory BotanicalPrefillResult.fromMap(Map<String, dynamic> data) {
    String? trimmed(String? value) {
      if (value == null) return null;
      final result = value.trim();
      return result.isEmpty ? null : result;
    }

    return BotanicalPrefillResult(
      genus: trimmed(data['genus'] as String?),
      species: trimmed(data['species'] as String?),
      cultivar: trimmed(data['cultivar'] as String?),
      plantFamily: trimmed(data['plantFamily'] as String? ??
          data['plant_family'] as String?),
      tradingName: trimmed(data['tradingName'] as String? ??
          data['trading_name'] as String?),
      isHybrid: data['isHybrid'] as bool? ??
          data['is_hybrid'] as bool? ??
          false,
      variegation: Variegation.fromJson(data['variegation']),
    );
  }
}
