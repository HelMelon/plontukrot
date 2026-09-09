import 'dart:convert';

/// HTTP error from [ApiClient].
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final Object? body;

  const ApiException(this.statusCode, this.message, {this.body});

  bool get isUnauthorized => statusCode == 401;

  bool get isConflict => statusCode == 409;

  bool get isNotFound => statusCode == 404;

  bool get isForbidden => statusCode == 403;

  Map<String, dynamic>? get _detailMap {
    try {
      Object? decoded = body;
      if (decoded is String) {
        if (decoded.isEmpty) return null;
        decoded = jsonDecode(decoded);
      }
      if (decoded is! Map) return null;
      final detail = decoded['detail'];
      if (detail is Map) {
        return Map<String, dynamic>.from(detail);
      }
    } catch (_) {}
    return null;
  }

  bool get isUserBanned {
    final detail = _detailMap;
    return detail != null && detail['code'] == 'user_banned';
  }

  bool get isUserDeleted {
    final detail = _detailMap;
    return detail != null && detail['code'] == 'user_deleted';
  }

  String? get banReason {
    final reason = _detailMap?['reason'];
    if (reason is String && reason.trim().isNotEmpty) return reason.trim();
    return null;
  }

  /// Same structured `reason` field as bans (`user_banned` / `user_deleted`).
  String? get deleteReason => banReason;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
