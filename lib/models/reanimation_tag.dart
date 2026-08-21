enum ReanimationTag {
  rerooting,
  soilFlush,
  rotTrimming;

  String get code => switch (this) {
        ReanimationTag.rerooting => 'rerooting',
        ReanimationTag.soilFlush => 'soil_flush',
        ReanimationTag.rotTrimming => 'rot_trimming',
      };

  static ReanimationTag? tryParse(String? value) {
    if (value == null) return null;
    return switch (value.trim()) {
      'rerooting' => ReanimationTag.rerooting,
      'soil_flush' || 'soilFlush' => ReanimationTag.soilFlush,
      'rot_trimming' || 'rotTrimming' => ReanimationTag.rotTrimming,
      _ => null,
    };
  }
}
