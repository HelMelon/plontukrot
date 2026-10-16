import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/botanical_prefill_result.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'app_crash_reporting.dart';

class BotanicalPrefillService {
  final ApiClient _api = ApiClient.instance;

  Future<BotanicalPrefillResult> prefill({
    required String phrase,
    String locale = 'ru',
  }) async {
    if (kDebugMode) {
      debugPrint('[BotanicalPrefillService] prefill: phrase="$phrase", locale=$locale');
    }
    final raw = await _api.post(
      '/botanical/prefill',
      body: {'phrase': phrase, 'locale': locale},
    );
    if (raw is! Map<String, dynamic>) {
      throw ApiException(0, 'Invalid response from botanical prefill');
    }
    if (kDebugMode) {
      debugPrint('[BotanicalPrefillService] response: $raw');
    }
    return BotanicalPrefillResult.fromMap(raw);
  }

  /// Records a non-fatal error for diagnostics. Callers should still show UI feedback.
  static void reportError(Object error, StackTrace stack, {String? phrase}) {
    unawaited(
      AppCrashReporting.instance.recordError(
        error,
        stack,
        reason: 'botanical_prefill${phrase == null ? '' : ': $phrase'}',
      ),
    );
  }
}
