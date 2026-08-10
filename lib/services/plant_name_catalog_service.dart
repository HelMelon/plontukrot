import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/plant.dart';
import '../models/variegation.dart';

/// In-memory + SharedPreferences cache of plant name parts for random
/// display-name suggestions (genus / species / nickname + variegation).
class PlantNameCatalogService {
  PlantNameCatalogService._();

  static final PlantNameCatalogService instance = PlantNameCatalogService._();

  static const _prefsKey = 'plant_name_catalog_v1';

  static const List<String> _seedGenera = [
    'Hoya',
    'Monstera',
    'Philodendron',
    'Anthurium',
    'Alocasia',
    'Begonia',
    'Calathea',
    'Syngonium',
    'Epipremnum',
    'Scindapsus',
    'Peperomia',
    'Ficus',
    'Aglaonema',
    'Dieffenbachia',
    'Maranta',
    'Stromanthe',
    'Rhaphidophora',
    'Dischidia',
    'Ceropegia',
    'Sansevieria',
  ];

  static const List<String> _seedSpecies = [
    'carnosa',
    'pubicalyx',
    'kerrii',
    'linearis',
    'obovata',
    'deliciosa',
    'adansonii',
    'thai constellation',
    'hederaceum',
    'micans',
    'birkin',
    'crystallinum',
    'clarinervium',
    'amazonica',
    'polly',
    'maculata',
    'orbifolia',
    'makoyana',
    'podophyllum',
    'pictus',
    'argyraeus',
    'obtusifolia',
    'lyrata',
    'elastica',
    'commutatum',
    'seguine',
    'leuconeura',
    'triostar',
    'tetrasperma',
    'woodii',
    'trifasciata',
  ];

  /// Friendly plant nicknames / trading-style names used as «название».
  static const List<String> _seedNames = [
    'Moonlight',
    'Velvet Queen',
    'Silver Splash',
    'Green Goddess',
    'Little Gem',
    'Forest Fairy',
    'Sunny Side',
    'Misty Leaf',
    'Coral Reef',
    'Night Owl',
    'Sugarplum',
    'Jade Whisper',
    'Pepper Mint',
    'Golden Hour',
    'Cloud Nine',
    'Fernweh',
    'Lush Life',
    'Root Beer',
    'Tea Leaf',
    'Wildflower',
    'Бабушка',
    'Крошка',
    'Солнышко',
    'Пятнышко',
    'Туман',
    'Изумруд',
    'Росинка',
    'Листок',
  ];

  final Set<String> _genera = {};
  final Set<String> _species = {};
  final Set<String> _names = {};

  bool _loaded = false;
  Future<void>? _loadFuture;

  List<String> get genera => List.unmodifiable(_genera);
  List<String> get species => List.unmodifiable(_species);
  List<String> get names => List.unmodifiable(_names);

  /// Variegation values usable in generated display names.
  List<Variegation> get variegations => Variegation.values
      .where((v) => v != Variegation.none && v != Variegation.unknown)
      .toList(growable: false);

  Future<void> ensureLoaded() {
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    if (_loaded) return;
    _seedDefaults();
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          _mergeList(_genera, decoded['genera']);
          _mergeList(_species, decoded['species']);
          _mergeList(_names, decoded['names']);
        }
      }
    } catch (_) {
      // Keep seed data if cache is corrupt.
    }
    _loaded = true;
  }

  void _seedDefaults() {
    _genera.addAll(_seedGenera);
    _species.addAll(_seedSpecies);
    _names.addAll(_seedNames);
  }

  void _mergeList(Set<String> target, Object? raw) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is! String) continue;
      final trimmed = item.trim();
      if (trimmed.isEmpty) continue;
      target.add(trimmed);
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'genera': _genera.toList()..sort(),
          'species': _species.toList()..sort(),
          'names': _names.toList()..sort(),
        }),
      );
    } catch (_) {
      // Cache write is best-effort.
    }
  }

  /// Merges unique values from the user's plants into the local cache.
  Future<void> absorbPlants(Iterable<Plant> plants) async {
    await ensureLoaded();
    var changed = false;
    for (final plant in plants) {
      final genus = plant.genus.trim();
      if (genus.isNotEmpty && _genera.add(genus)) changed = true;

      final species = plant.species.trim();
      if (species.isNotEmpty && _species.add(species)) changed = true;

      final nickname = plant.nickname.trim();
      if (nickname.isNotEmpty && _names.add(nickname)) changed = true;

      final trading = plant.tradingName.trim();
      if (trading.isNotEmpty && _names.add(trading)) changed = true;
    }
    if (changed) await _persist();
  }
}
