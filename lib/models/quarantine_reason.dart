enum QuarantineReason {
  purchase,
  repotting;

  String get code => switch (this) {
        QuarantineReason.purchase => 'purchase',
        QuarantineReason.repotting => 'repotting',
      };

  static QuarantineReason? tryParse(String? value) {
    if (value == null) return null;
    return switch (value.trim()) {
      'purchase' => QuarantineReason.purchase,
      'repotting' || 'transplant' => QuarantineReason.repotting,
      _ => null,
    };
  }
}
