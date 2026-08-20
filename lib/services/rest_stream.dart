import 'dart:async';

import 'api_refresh.dart';

/// Turns a one-shot REST fetch into a broadcast stream that many widgets can
/// listen to at once without "already been listened to" errors.
///
/// Emits immediately, again after each [ApiRefresh.ping], and on a background
/// poll interval (default 30s; ADR-033 v1). Because it is a broadcast stream,
/// a listener that attaches later receives the most recently emitted value via
/// a replay cache (so it does not sit on an infinite spinner), and multiple
/// `StreamBuilder`s can subscribe to the same stream safely.
Stream<T> restPollStream<T>(
  Future<T> Function() fetch, {
  Duration interval = const Duration(seconds: 30),
}) {
  late StreamController<T> controller;
  Timer? timer;
  StreamSubscription<void>? refreshSub;
  var inFlight = false;
  T? lastValue;
  var hasValue = false;

  Future<void> emit() async {
    if (inFlight || controller.isClosed) return;
    inFlight = true;
    try {
      final value = await fetch();
      if (controller.isClosed) return;
      lastValue = value;
      hasValue = true;
      controller.add(value);
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    } finally {
      inFlight = false;
    }
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      // Replay the last value so a new subscriber never spins forever.
      if (hasValue && !controller.isClosed) controller.add(lastValue as T);
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
