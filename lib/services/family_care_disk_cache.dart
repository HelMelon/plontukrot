import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/family_care_guide.dart';

/// Persists family care guides on device for offline use.
class FamilyCareDiskCache {
  FamilyCareDiskCache._();

  static const _fileName = 'family_care_guides.json';
  static const _version = 1;

  static File? _overrideFile;

  @visibleForTesting
  static void debugSetFile(File? file) {
    _overrideFile = file;
  }

  static Future<File> _resolveFile() async {
    if (_overrideFile != null) {
      return _overrideFile!;
    }
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  static Future<Map<String, FamilyCareGuide>> readAll() async {
    try {
      final file = await _resolveFile();
      if (!await file.exists()) {
        return {};
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return {};
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      final version = decoded['version'];
      if (version != _version) {
        return {};
      }

      final entries = decoded['entries'];
      if (entries is! Map<String, dynamic>) {
        return {};
      }

      final result = <String, FamilyCareGuide>{};
      for (final entry in entries.entries) {
        final value = entry.value;
        if (value is! Map<String, dynamic>) continue;
        final guideMap = value['guide'];
        if (guideMap is! Map<String, dynamic>) continue;

        final guide = FamilyCareGuide.fromMap(guideMap);
        if (guide.isNotEmpty) {
          result[entry.key] = guide;
        }
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<void> put(String cacheKey, FamilyCareGuide guide) async {
    if (guide.isEmpty) return;

    final file = await _resolveFile();
    final entries = await readAll();
    entries[cacheKey] = guide;
    await _writeAll(file, entries);
  }

  static Future<void> clear() async {
    final file = await _resolveFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> _writeAll(
    File file,
    Map<String, FamilyCareGuide> entries,
  ) async {
    final payload = <String, dynamic>{
      'version': _version,
      'entries': entries.map(
        (key, guide) => MapEntry(key, {
          'guide': guide.toMap(),
        }),
      ),
    };

    final encoded = jsonEncode(payload);
    await file.parent.create(recursive: true);
    await file.writeAsString(encoded, flush: true);
  }
}
