import 'variegation.dart';

class PlantMember {
  final String? cultivar;
  final Variegation variegation;
  final String? sourcePlantId;

  const PlantMember({
    this.cultivar,
    this.variegation = Variegation.none,
    this.sourcePlantId,
  });

  factory PlantMember.fromMap(Map<String, dynamic> data) {
    final rawCultivar = data['cultivar'] as String?;
    final trimmed = rawCultivar?.trim();
    return PlantMember(
      cultivar: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      variegation: Variegation.fromStorage(data['variegation'] as String?),
      sourcePlantId: data['sourcePlantId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final trimmed = cultivar?.trim();
    return {
      'cultivar':
          (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      'variegation': variegation.storageValue,
      if (sourcePlantId != null) 'sourcePlantId': sourcePlantId,
    };
  }
}
