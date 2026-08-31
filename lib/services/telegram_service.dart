import '../models/model_helpers.dart';
import 'api_client.dart';
import 'api_exception.dart';
import 'rest_stream.dart';

/// Result of creating a Telegram link code.
class TelegramLink {
  final String code;
  final String botUsername;
  final DateTime? expiresAt;

  const TelegramLink({
    required this.code,
    required this.botUsername,
    this.expiresAt,
  });

  /// The deep-link the user opens to bind their chat: t.me/bot?start=code.
  String get deepLink => 'https://t.me/$botUsername?start=$code';

  factory TelegramLink.fromMap(Map<String, dynamic> data) {
    return TelegramLink(
      code: readString(data, 'code') ?? '',
      botUsername: readString(data, 'botUsername') ?? '',
      expiresAt: readDate(data, 'expiresAt'),
    );
  }
}

/// Bind the user's Telegram chat to their plontukrot account so alerts
/// (water the pot, bring the plant inside) reach them.
class TelegramService {
  final ApiClient _api = ApiClient.instance;

  /// Mint a one-time code and return the deep-link to open in Telegram.
  Future<TelegramLink> createLink() async {
    final res = jsonMap(await _api.post('/telegram/link'));
    return TelegramLink.fromMap(res);
  }

  /// Whether the current user has linked a Telegram chat.
  Future<bool> isLinked() async {
    try {
      final res = jsonMap(await _api.get('/telegram/status'));
      return readBool(res, 'linked');
    } on ApiException catch (e) {
      if (e.isNotFound) return false;
      rethrow;
    }
  }

  /// Remove the user's Telegram binding.
  Future<void> unlink() async {
    try {
      await _api.delete('/telegram/link');
    } on ApiException catch (e) {
      if (!e.isNotFound) rethrow;
    }
  }

  /// Live stream of the linked state (re-polls every 30s).
  Stream<bool> watchLinked() {
    return restPollStream(isLinked);
  }
}
