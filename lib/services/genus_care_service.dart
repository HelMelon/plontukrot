import 'dart:async';

import '../models/genus_care_guide.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'app_crash_reporting.dart';

class GenusCareService {
  final ApiClient _api = ApiClient.instance;

  static final Map<String, GenusCareGuide> _cache = {};

  static String _cacheKey(String genus, String locale) =>
      '${genus.trim().toLowerCase()}|$locale';

  /// Fetch care guide for the given [genus] in the requested [locale].
  ///
  /// Uses in-memory cache when available unless [forceRefresh] is true.
  Future<GenusCareGuide?> getCareGuide(
    String genus, {
    required String locale,
    bool forceRefresh = false,
  }) async {
    final trimmed = genus.trim();
    if (trimmed.isEmpty) return null;

    final normalizedLocale = _normalizeLocale(locale);
    final cacheKey = _cacheKey(trimmed, normalizedLocale);
    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final encodedGenus = Uri.encodeComponent(trimmed);
      final raw = await _api.get(
        '/genera/$encodedGenus/care-guide',
        query: {'locale': normalizedLocale},
      );
      if (raw == null) return null;

      final guide = GenusCareGuide.fromMap(jsonMap(raw));
      if (guide.isNotEmpty) {
        _cache[cacheKey] = guide;
      }
      return guide;
    } on ApiException catch (e, stack) {
      if (e.isNotFound) {
        return null;
      }
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason:
              'genus_care_guide_api_error: $trimmed/$normalizedLocale (${e.statusCode})',
        ),
      );
      rethrow;
    } catch (e, stack) {
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason: 'genus_care_guide_fetch_error: $trimmed/$normalizedLocale',
        ),
      );
      rethrow;
    }
  }

  static String _normalizeLocale(String locale) {
    const supported = {'en', 'ru', 'de', 'fr'};
    final code = locale.trim().toLowerCase().split('-').first;
    if (supported.contains(code)) return code;
    return 'en';
  }

  /// Clears the in-memory cache.
  static void clearCache() {
    _cache.clear();
  }
}
