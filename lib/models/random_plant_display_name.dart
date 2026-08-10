import 'dart:math';

import 'package:plontukrot/l10n/app_localizations.dart';

import '../core/l10n/app_localizations_x.dart';
import '../services/plant_name_catalog_service.dart';

enum PlantDisplayNameTemplate {
  speciesVariegation,
  nameVariegation,
  genusVariegation,
}

/// Builds random display-name suggestions from the plant name catalog.
class RandomPlantDisplayName {
  RandomPlantDisplayName({
    PlantNameCatalogService? catalog,
    Random? random,
  })  : _catalog = catalog ?? PlantNameCatalogService.instance,
        _random = random ?? Random();

  final PlantNameCatalogService _catalog;
  final Random _random;

  Future<String> next(AppLocalizations l10n) async {
    await _catalog.ensureLoaded();
    final variegations = _catalog.variegations;
    if (variegations.isEmpty) return '';

    final variegation = _pick(variegations);
    final variegationLabel = l10n.variegationLabelOf(variegation);

    final template = PlantDisplayNameTemplate
        .values[_random.nextInt(PlantDisplayNameTemplate.values.length)];

    final left = switch (template) {
      PlantDisplayNameTemplate.speciesVariegation =>
        _pickNonEmpty(_catalog.species),
      PlantDisplayNameTemplate.nameVariegation =>
        _pickNonEmpty(_catalog.names),
      PlantDisplayNameTemplate.genusVariegation =>
        _pickNonEmpty(_catalog.genera),
    };

    if (left == null || variegationLabel.trim().isEmpty) return '';
    return '$left $variegationLabel';
  }

  T _pick<T>(List<T> items) => items[_random.nextInt(items.length)];

  String? _pickNonEmpty(List<String> items) {
    if (items.isEmpty) return null;
    for (var attempt = 0; attempt < 8; attempt++) {
      final value = _pick(items).trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }
}
