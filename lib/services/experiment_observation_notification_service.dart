import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../core/features/feature_flags.dart';
import '../core/locale/app_locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/experiment_observation_reminder.dart';
import 'app_crash_reporting.dart';
import 'experiment_service.dart';
import 'fertilizing_notification_service.dart';

/// Local reminder to log observations for active experiments.
///
/// Uses the same [FlutterLocalNotificationsPlugin] singleton, timezone setup,
/// and permission helpers as fertilizing reminders. Taps open the app; care
/// reminders do not route the tap to a screen.
class ExperimentObservationNotificationService {
  ExperimentObservationNotificationService._();

  static final ExperimentObservationNotificationService instance =
      ExperimentObservationNotificationService._();

  static const _channelId = 'experiment_observation_reminders';
  static const _payload = 'experiment_observation';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> _queue = Future<void>.value();

  /// Cancel and, when an active experiment exists, plan the next fires.
  ///
  /// Failures are recorded and do not surface to the caller: a reminder must
  /// not fail creating or completing an experiment.
  Future<void> reschedule() {
    final scheduled = _queue.then((_) => _rescheduleBody());
    _queue = scheduled.catchError((Object error, StackTrace stack) async {
      try {
        await AppCrashReporting.instance.recordError(
          error,
          stack,
          reason: 'experiment_observation_reminder_reschedule_failed',
        );
      } catch (_) {}
    });
    return _queue;
  }

  Future<void> _rescheduleBody() async {
    await FertilizingNotificationService.instance.initialize();

    final enabled =
        FeatureFlagsController.instance.isEnabled(FeatureFlag.experiments);
    if (!enabled) {
      await _cancel();
      return;
    }

    final experiments = await ExperimentService().fetchExperiments();
    final hasActive = experiments.any(experimentWantsObservationReminder);
    if (!hasActive) {
      await _cancel();
      return;
    }

    final granted =
        await FertilizingNotificationService.instance.isPermissionGranted();
    if (!granted) {
      await _cancel();
      return;
    }

    final l10n = _resolveL10n();
    final times = upcomingExperimentObservationReminders(DateTime.now());
    await _ensureAndroidChannel(l10n);
    await _cancel();
    for (var slot = 0; slot < times.length; slot++) {
      await _schedule(
        id: experimentObservationReminderId(slot),
        when: times[slot],
        title: l10n.experimentObservationReminderTitle,
        body: l10n.experimentObservationReminderBody,
        channelName: l10n.experimentObservationReminderChannelName,
        channelDescription:
            l10n.experimentObservationReminderChannelDescription,
      );
    }
  }

  Future<void> _cancel() async {
    for (var slot = 0; slot < experimentObservationReminderHorizon; slot++) {
      await _plugin.cancel(experimentObservationReminderId(slot));
    }
    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload != null && payload.startsWith(_payload)) {
        await _plugin.cancel(request.id);
      }
    }
  }

  Future<void> _ensureAndroidChannel(AppLocalizations l10n) async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        l10n.experimentObservationReminderChannelName,
        description: l10n.experimentObservationReminderChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzWhen,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: _payload,
    );
  }

  AppLocalizations _resolveL10n() {
    final override = AppLocaleController.instance.localeOverride;
    final device = PlatformDispatcher.instance.locale;
    final locale = AppLocaleController.resolveLocale(
          override ?? device,
          AppLocalizations.supportedLocales,
        ) ??
        const Locale('ru');
    return lookupAppLocalizations(locale);
  }
}
