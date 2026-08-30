import 'dart:async';
import 'dart:io';

import '../models/genus_care_guide.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'app_crash_reporting.dart';
import 'genus_care_disk_cache.dart';

class GenusCareService {
  final ApiClient _api = ApiClient.instance;

  static final Map<String, GenusCareGuide> _cache = {};
  static Future<void>? _warmFuture;

  static String _cacheKey(String genus, String locale) =>
      '${genus.trim().toLowerCase()}|$locale';

  /// Loads disk cache into memory. Safe to call multiple times.
  static Future<void> warmDiskCache() {
    _warmFuture ??= _hydrateFromDisk();
    return _warmFuture!;
  }

  /// Returns a cached guide when already in memory (after [warmDiskCache]).
  static GenusCareGuide? peekCached(String genus, {required String locale}) {
    final trimmed = genus.trim();
    if (trimmed.isEmpty) return null;
    return _cache[_cacheKey(trimmed, _normalizeLocale(locale))];
  }

  static Future<void> _hydrateFromDisk() async {
    try {
      final entries = await GenusCareDiskCache.readAll();
      _cache.addAll(entries);
    } catch (e, stack) {
      unawaited(
        AppCrashReporting.instance.recordError(
          e,
          stack,
          reason: 'genus_care_disk_hydrate_error',
        ),
      );
    }
  }

  /// Fetch care guide for the given [genus] in the requested [locale].
  ///
  /// Order: memory/disk cache, then API. On network failure returns disk cache
  /// when available unless [forceRefresh] is true.
  Future<GenusCareGuide?> getCareGuide(
    String genus, {
    required String locale,
    bool forceRefresh = false,
  }) async {
    final trimmed = genus.trim();
    if (trimmed.isEmpty) return null;

    final normalizedLocale = _normalizeLocale(locale);
    final cacheKey = _cacheKey(trimmed, normalizedLocale);

    await warmDiskCache();

    if (!forceRefresh && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    try {
      final encodedGenus = Uri.encodeComponent(trimmed);
      final raw = await _api.get(
        '/genera/$encodedGenus/care-guide',
        query: {'locale': normalizedLocale},
      );
      if (raw == null) return _offlineFallback(cacheKey, forceRefresh);

      final guide = GenusCareGuide.fromMap(jsonMap(raw));
      if (guide.isNotEmpty) {
        _cache[cacheKey] = guide;
        unawaited(GenusCareDiskCache.put(cacheKey, guide));
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
              'genus_care_guide_api_error: $trimmed/$normalizedLocale (${e.statusCode})',
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
          reason: 'genus_care_guide_offline: $trimmed/$normalizedLocale',
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
          reason: 'genus_care_guide_timeout: $trimmed/$normalizedLocale',
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
          reason: 'genus_care_guide_fetch_error: $trimmed/$normalizedLocale',
        ),
      );
      rethrow;
    }
  }

  static GenusCareGuide? _offlineFallback(String cacheKey, bool forceRefresh) {
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
    await GenusCareDiskCache.clear();
  }
}
