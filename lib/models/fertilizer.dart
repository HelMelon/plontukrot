import 'fertilizer_dose.dart';
import 'model_helpers.dart';

enum FertilizerKind {
  mix,
  purchased;

  String get code => name;

  static FertilizerKind fromCode(dynamic code) {
    return readEnum(code, FertilizerKind.values, FertilizerKind.mix);
  }
}

class Fertilizer {
  final String id;
  final String name;
  final FertilizerKind kind;
  final DateTime? createdAt;
  final int waterMl;
  final List<FertilizerDose> components;

  const Fertilizer({
    required this.id,
    required this.name,
    this.kind = FertilizerKind.mix,
    this.createdAt,
    this.waterMl = 250,
    this.components = const [],
  });

  bool get isPurchased => kind == FertilizerKind.purchased;

  factory Fertilizer.fromMap(String id, Map<String, dynamic> data) {
    final rawComponents = readField(data, 'components') as List<dynamic>?;

    return Fertilizer(
      id: id,
      name: readString(data, 'name') ?? '',
      kind: FertilizerKind.fromCode(readField(data, 'kind')),
      createdAt: readDate(data, 'createdAt'),
      waterMl: normalizeWaterMl(readInt(data, 'waterMl')),
      components: rawComponents != null
          ? rawComponents
              .whereType<Map>()
              .map(
                (item) => FertilizerDose.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'kind': kind.index,
      'waterMl': waterMl,
      'water_ml': waterMl,
      if (createdAt != null) 'createdAt': isoOrNull(createdAt),
      'components': components.map((e) => e.toMap()).toList(),
    };
  }
}
