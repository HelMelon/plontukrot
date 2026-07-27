class SoilComponent {
  final String component;
  final double parts;

  const SoilComponent({
    required this.component,
    required this.parts,
  });

  factory SoilComponent.fromMap(Map<String, dynamic> data) {
    final double rawParts = (data['parts'] as num?)?.toDouble() ?? 0.5;
    return SoilComponent(
      component: data['component'] as String? ?? '',
      parts: rawParts < 0.5 ? 0.5 : rawParts, // Ограничение снизу 0.5
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'component': component,
      'parts': parts < 0.5 ? 0.5 : parts,
    };
  }
}
