import 'model_helpers.dart';

class Stimulator {
  final String id;
  final String name;
  final String? defaultDosage;
  final DateTime? createdAt;

  const Stimulator({
    required this.id,
    required this.name,
    this.defaultDosage,
    this.createdAt,
  });

  factory Stimulator.fromMap(String id, Map<String, dynamic> data) {
    return Stimulator(
      id: id,
      name: readString(data, 'name') ?? '',
      defaultDosage: _nullableTrimmed(readString(data, 'defaultDosage')),
      createdAt: readDate(data, 'createdAt'),
    );
  }

  static String? _nullableTrimmed(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (defaultDosage != null) 'defaultDosage': defaultDosage,
      if (defaultDosage != null) 'default_dosage': defaultDosage,
      if (createdAt != null) 'createdAt': isoOrNull(createdAt),
    };
  }
}
