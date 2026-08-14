import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/fertilizing_growth_season.dart';

/// Season boundaries for fertilizing: SharedPreferences + Firestore user doc.
class FertilizingSeasonController extends ChangeNotifier {
  FertilizingSeasonController._();

  static final FertilizingSeasonController instance =
      FertilizingSeasonController._();

  static const _prefsModeKey = 'fertilizing_season_mode';
  static const _prefsSpringStartKey = 'fertilizing_spring_start_month';
  static const _prefsSpringEndKey = 'fertilizing_spring_end_month';

  SharedPreferences? _prefs;
  FertilizingSeasonSettings _settings = const FertilizingSeasonSettings();

  FertilizingSeasonSettings get settings => _settings;

  FertilizingGrowthSeason get currentGrowthSeason =>
      _settings.growthSeasonForDate(DateTime.now());

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final modeRaw = _prefs?.getString(_prefsModeKey);
    final mode = FertilizingSeasonMode.values.firstWhere(
      (m) => m.name == modeRaw,
      orElse: () => FertilizingSeasonMode.northern,
    );
    _settings = FertilizingSeasonSettings(
      mode: mode,
      springStartMonth: _prefs?.getInt(_prefsSpringStartKey) ??
          FertilizingSeasonSettings.northernSpringStart,
      springEndMonth: _prefs?.getInt(_prefsSpringEndKey) ??
          FertilizingSeasonSettings.northernSpringEnd,
    );
  }

  Future<void> setSettings(FertilizingSeasonSettings next) async {
    _settings = next;
    await _prefs?.setString(_prefsModeKey, next.mode.name);
    await _prefs?.setInt(_prefsSpringStartKey, next.springStartMonth);
    await _prefs?.setInt(_prefsSpringEndKey, next.springEndMonth);
    await _writeToCloud(next);
    notifyListeners();
  }

  Future<void> setMode(FertilizingSeasonMode mode) async {
    await setSettings(_settings.copyWith(mode: mode));
  }

  Future<void> setCustomMonths({
    required int springStartMonth,
    required int springEndMonth,
  }) async {
    await setSettings(
      _settings.copyWith(
        mode: FertilizingSeasonMode.custom,
        springStartMonth: springStartMonth,
        springEndMonth: springEndMonth,
      ),
    );
  }

  Future<void> syncWithCloud() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final remote = FertilizingSeasonSettings.fromMap(doc.data());
      if (remote.mode == _settings.mode &&
          remote.springStartMonth == _settings.springStartMonth &&
          remote.springEndMonth == _settings.springEndMonth) {
        return;
      }
      _settings = remote;
      await _prefs?.setString(_prefsModeKey, remote.mode.name);
      await _prefs?.setInt(_prefsSpringStartKey, remote.springStartMonth);
      await _prefs?.setInt(_prefsSpringEndKey, remote.springEndMonth);
      notifyListeners();
    } catch (_) {
      // Keep local settings if cloud sync fails.
    }
  }

  Future<void> _writeToCloud(FertilizingSeasonSettings settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
            settings.toMap(),
            SetOptions(merge: true),
          );
    } catch (_) {
      // Local preference is already saved.
    }
  }
}
