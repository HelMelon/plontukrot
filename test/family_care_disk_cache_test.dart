import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plontukrot/models/family_care_guide.dart';
import 'package:plontukrot/services/family_care_disk_cache.dart';

void main() {
  group('FamilyCareDiskCache', () {
    late Directory tempDir;
    late File cacheFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('family_care_cache_test');
      cacheFile = File('${tempDir.path}/family_care_guides.json');
      FamilyCareDiskCache.debugSetFile(cacheFile);
    });

    tearDown(() async {
      FamilyCareDiskCache.debugSetFile(null);
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('readAll returns empty map when file is missing', () async {
      final entries = await FamilyCareDiskCache.readAll();
      expect(entries, isEmpty);
    });

    test('put and readAll roundtrip guide entries', () async {
      const guide = FamilyCareGuide(
        family: 'Araceae',
        origin: 'Tropical regions',
        watering: 'Moderate',
      );

      await FamilyCareDiskCache.put('araceae|ru', guide);
      final entries = await FamilyCareDiskCache.readAll();

      expect(entries.length, 1);
      expect(entries['araceae|ru']?.family, 'Araceae');
      expect(entries['araceae|ru']?.origin, 'Tropical regions');
      expect(entries['araceae|ru']?.watering, 'Moderate');
    });

    test('clear removes persisted cache file', () async {
      const guide = FamilyCareGuide(
        family: 'Orchidaceae',
        light: 'Bright indirect',
      );

      await FamilyCareDiskCache.put('orchidaceae|en', guide);
      expect(await cacheFile.exists(), isTrue);

      await FamilyCareDiskCache.clear();
      expect(await cacheFile.exists(), isFalse);
      expect(await FamilyCareDiskCache.readAll(), isEmpty);
    });
  });
}
