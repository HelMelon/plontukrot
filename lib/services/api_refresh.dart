import 'dart:async';

/// Broadcast ping after a mutating REST call so polling streams re-fetch.
class ApiRefresh {
  ApiRefresh._();

  static final ApiRefresh instance = ApiRefresh._();

  final StreamController<void> _controller =
      StreamController<void>.broadcast();

  Stream<void> get stream => _controller.stream;

  void ping() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
