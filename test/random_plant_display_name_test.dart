import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/l10n/app_localizations.dart';
import 'package:plontukrot/models/random_plant_display_name.dart';
import 'package:plontukrot/services/plant_name_catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('random plant display name uses catalog templates', () async {
    final catalog = PlantNameCatalogService.instance;
    await catalog.ensureLoaded();
    final l10n = lookupAppLocalizations(const Locale('en'));
    final generator = RandomPlantDisplayName(
      catalog: catalog,
      random: Random(42),
    );

    final names = <String>{};
    for (var i = 0; i < 30; i++) {
      final name = await generator.next(l10n);
      expect(name, isNotEmpty);
      expect(name.split(' ').length, greaterThanOrEqualTo(2));
      names.add(name);
    }
    expect(names.length, greaterThan(1));
  });
}
