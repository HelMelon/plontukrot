import 'dart:async';

import 'api_refresh.dart';
import 'app_crash_reporting.dart';

/// Turns a one-shot REST fetch into a broadcast stream that many widgets can
/// listen to at once without "already been listened to" errors.
///
/// Emits immediately, again after each [ApiRefresh.ping]/[ApiRefresh.refresh],
/// and on a background poll interval (default 30s; ADR-033 v1). Because it is
/// a broadcast stream, a listener that attaches later receives the most
/// recently emitted value via a replay cache (so it does not sit on an
/// infinite spinner), and multiple `StreamBuilder`s can subscribe to the same
/// stream safely.
Stream<T> restPollStream<T>(
  Future<T> Function() fetch, {
  Duration interval = const Duration(seconds: 30),
}) {
  late StreamController<T> controller;
  Timer? timer;
  Future<void> emitChain = Future<void>.value();
  T? lastValue;
  var hasValue = false;

  Future<void> emitOnce() async {
    if (controller.isClosed) return;
    try {
      final value = await fetch();
      if (controller.isClosed) return;
      lastValue = value;
      hasValue = true;
      controller.add(value);
    } catch (error, stack) {
      unawaited(
        AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'rest_poll_stream_failed',
        ),
      );
      if (!controller.isClosed) {
        // If there is no cached value yet, notify listeners of initial failure.
        // If we already have a value, retain the current UI rather than clearing data.
        if (!hasValue) {
          controller.addError(error, stack);
        }
      }
    }
  }

  Future<void> emit() {
    emitChain = emitChain.then((_) => emitOnce());
    return emitChain;
  }

  controller = StreamController<T>.broadcast(
    onListen: () {
      // Replay the last value so a new subscriber never spins forever.
      if (hasValue && !controller.isClosed) controller.add(lastValue as T);
      unawaited(emit());
      timer = Timer.periodic(interval, (_) => unawaited(emit()));
      ApiRefresh.instance.register(emit);
    },
    onCancel: () {
      timer?.cancel();
      ApiRefresh.instance.unregister(emit);
    },
  );

  return controller.stream;
}
