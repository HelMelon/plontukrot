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

  @override
  String toString() => 'ApiException($statusCode): $message';
}
