import 'dart:async';

import 'api_refresh.dart';

/// Turns a one-shot REST fetch into a stream: emit immediately, again after
/// each [ApiRefresh.ping], and on a short poll interval (ADR-033 v1).
Stream<T> restPollStream<T>(
  Future<T> Function() fetch, {
  Duration interval = const Duration(seconds: 8),
}) {
  late StreamController<T> controller;
  Timer? timer;
  StreamSubscription<void>? refreshSub;
  var inFlight = false;

  Future<void> emit() async {
    if (inFlight || controller.isClosed) return;
    inFlight = true;
    try {
      final value = await fetch();
      if (!controller.isClosed) controller.add(value);
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    } finally {
      inFlight = false;
    }
  }

  controller = StreamController<T>(
    onListen: () {
      unawaited(emit());
      timer = Timer.periodic(interval, (_) => unawaited(emit()));
      refreshSub = ApiRefresh.instance.stream.listen((_) => unawaited(emit()));
    },
    onCancel: () {
      timer?.cancel();
      refreshSub?.cancel();
    },
  );

  return controller.stream;
}
