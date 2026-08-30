import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/genus_care_guide.dart';
import 'package:plontukrot/services/genus_care_disk_cache.dart';

void main() {
  group('GenusCareDiskCache', () {
    late Directory tempDir;
    late File cacheFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('genus_care_cache_test');
      cacheFile = File('${tempDir.path}/genus_care_guides.json');
      GenusCareDiskCache.debugSetFile(cacheFile);
    });

    tearDown(() async {
      GenusCareDiskCache.debugSetFile(null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('readAll returns empty map when file is missing', () async {
      final entries = await GenusCareDiskCache.readAll();
      expect(entries, isEmpty);
    });

    test('put and readAll roundtrip guide entries', () async {
      const guide = GenusCareGuide(
        genus: 'Monstera',
        origin: 'Central America',
        watering: 'Moderate',
      );

      await GenusCareDiskCache.put('monstera|ru', guide);
      final entries = await GenusCareDiskCache.readAll();

      expect(entries.length, 1);
      expect(entries['monstera|ru']?.genus, 'Monstera');
      expect(entries['monstera|ru']?.origin, 'Central America');
      expect(entries['monstera|ru']?.watering, 'Moderate');
    });

    test('clear removes persisted cache file', () async {
      const guide = GenusCareGuide(
        genus: 'Ficus',
        light: 'Bright indirect',
      );

      await GenusCareDiskCache.put('ficus|en', guide);
      expect(await cacheFile.exists(), isTrue);

      await GenusCareDiskCache.clear();
      expect(await cacheFile.exists(), isFalse);
      expect(await GenusCareDiskCache.readAll(), isEmpty);
    });
  });
}
