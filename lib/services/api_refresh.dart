import 'dart:async';

typedef ApiRefreshHandler = Future<void> Function();

/// Triggers re-fetch for every active [restPollStream] listener.
///
/// [ping] is fire-and-forget (after mutating REST calls).
/// [refresh] awaits registered fetches — use from [RefreshIndicator].
class ApiRefresh {
  ApiRefresh._();

  static final ApiRefresh instance = ApiRefresh._();

  final Set<ApiRefreshHandler> _handlers = <ApiRefreshHandler>{};

  void register(ApiRefreshHandler handler) {
    _handlers.add(handler);
  }

  void unregister(ApiRefreshHandler handler) {
    _handlers.remove(handler);
  }

  void ping() {
    for (final handler in List<ApiRefreshHandler>.from(_handlers)) {
      unawaited(handler());
    }
  }

  Future<void> refresh() async {
    if (_handlers.isEmpty) return;
    await Future.wait(
      List<ApiRefreshHandler>.from(_handlers).map((handler) => handler()),
    );
  }
}
