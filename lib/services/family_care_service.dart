import 'dart:async';
import 'dart:io';

import '../models/family_care_guide.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'app_crash_reporting.dart';
import 'family_care_disk_cache.dart';

class FamilyCareService {
  final ApiClient _api = ApiClient.instance;

  static final Map<String, FamilyCareGuide> _cache = {};
  static Future<void>? _warmFuture;

  static String _cacheKey(String family, String locale) =>
      '${family.trim().toLowerCase()}|$locale';

  /// Loads disk cache into memory. Safe to call multiple times.
  static Future<void> warmDiskCache() {
    _warmFuture ??= _hydrateFromDisk();
    return _warmFuture!;
  }

  /// Returns a cached guide when already in memory (after [warmDiskCache]).
  static FamilyCareGuide? peekCached(String family, {required String locale}) {
    final trimmed = family.trim();
    if (trimmed.isEmpty) return null;
    return _cache[_cacheKey(trimmed, _normalizeLocale(locale))];
  }

  static Future<void> _hydrateFromDisk() async {
    try {
      final entries = await FamilyCareDiskCache.readAll();
      _cache.addAll(entries);
    } catch (e, stack) {
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason: 'family_care_disk_hydrate_error',
        ),
      );
    }
  }

  /// Fetch care guide for the given [family] in the requested [locale].
  ///
  /// Order: memory/disk cache, then API. On network failure returns disk cache
  /// when available unless [forceRefresh] is true.
  Future<FamilyCareGuide?> getCareGuide(
    String family, {
    required String locale,
    bool forceRefresh = false,
  }) async {
    final trimmed = family.trim();
    if (trimmed.isEmpty) return null;

    final normalizedLocale = _normalizeLocale(locale);
    final cacheKey = _cacheKey(trimmed, normalizedLocale);

    await warmDiskCache();

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final encodedFamily = Uri.encodeComponent(trimmed);
      final raw = await _api.get(
        '/families/$encodedFamily/care-guide',
        query: {'locale': normalizedLocale},
      );
      if (raw == null) return _offlineFallback(cacheKey, forceRefresh);

      final guide = FamilyCareGuide.fromMap(jsonMap(raw));
      if (guide.isNotEmpty) {
        _cache[cacheKey] = guide;
        unawaited(FamilyCareDiskCache.put(cacheKey, guide));
      }
      return guide.isNotEmpty ? guide : _offlineFallback(cacheKey, forceRefresh);
    } on ApiException catch (e, stack) {
      if (e.isNotFound) {
        return null;
      }
      final cached = _offlineFallback(cacheKey, forceRefresh);
      if (cached != null) {
        return cached;
      }
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason:
              'family_care_guide_api_error: $trimmed/$normalizedLocale (${e.statusCode})',
        ),
      );
      rethrow;
    } on SocketException catch (e, stack) {
      final cached = _offlineFallback(cacheKey, forceRefresh);
      if (cached != null) {
        return cached;
      }
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason: 'family_care_guide_offline: $trimmed/$normalizedLocale',
        ),
      );
      rethrow;
    } on TimeoutException catch (e, stack) {
      final cached = _offlineFallback(cacheKey, forceRefresh);
      if (cached != null) {
        return cached;
      }
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason: 'family_care_guide_timeout: $trimmed/$normalizedLocale',
        ),
      );
      rethrow;
    } catch (e, stack) {
      final cached = _offlineFallback(cacheKey, forceRefresh);
      if (cached != null) {
        return cached;
      }
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason: 'family_care_guide_fetch_error: $trimmed/$normalizedLocale',
        ),
      );
      rethrow;
    }
  }

  static FamilyCareGuide? _offlineFallback(String cacheKey, bool forceRefresh) {
    if (forceRefresh) return null;
    return _cache[cacheKey];
  }

  static String _normalizeLocale(String locale) {
    const supported = {'en', 'ru', 'de', 'fr'};
    final code = locale.trim().toLowerCase().split('-').first;
    if (supported.contains(code)) return code;
    return 'en';
  }

  /// Clears in-memory and on-disk cache.
  static Future<void> clearCache() async {
    _cache.clear();
    _warmFuture = null;
    await FamilyCareDiskCache.clear();
  }
}
