enum PlantArchiveReason {
  merged,
  died,
  sold,
  gifted;

  String get code => name;

  static PlantArchiveReason? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;
    return PlantArchiveReason.values.firstWhere(
      (value) => value.name == code,
      orElse: () => PlantArchiveReason.died,
    );
  }
}
