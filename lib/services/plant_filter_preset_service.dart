import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant_filter_criteria.dart';

class PlantFilterPresetService {
  PlantFilterPresetService._();

  static final PlantFilterPresetService instance = PlantFilterPresetService._();

  factory PlantFilterPresetService() => instance;

  static const _key = 'custom_plant_filter_presets';

  Future<List<PlantFilterPreset>> loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_key);
      if (rawList == null || rawList.isEmpty) return const [];
      final presets = <PlantFilterPreset>[];
      for (final raw in rawList) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            presets.add(
              PlantFilterPreset.fromMap(decoded.cast<String, dynamic>()),
            );
          }
        } catch (_) {}
      }
      presets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return presets;
    } catch (_) {
      return const [];
    }
  }

  Future<void> savePreset(PlantFilterPreset preset) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await loadPresets();
      final updated = <PlantFilterPreset>[
        preset,
        ...current.where((p) => p.id != preset.id),
      ];
      final encodedList = updated.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_key, encodedList);
    } catch (_) {}
  }

  Future<void> deletePreset(String presetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await loadPresets();
      final updated = current.where((p) => p.id != presetId).toList();
      final encodedList = updated.map((p) => jsonEncode(p.toMap())).toList();
      await prefs.setStringList(_key, encodedList);
    } catch (_) {}
  }
}
