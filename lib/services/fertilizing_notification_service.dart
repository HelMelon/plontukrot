import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/locale/app_locale_controller.dart';
import '../core/season/fertilizing_season_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/fertilizing_frequency.dart';
import '../models/plant.dart';
import 'plant_service.dart';

/// Local notifications for fertilizing reminders (batched by due date).
class FertilizingNotificationService {
  FertilizingNotificationService._();

  static final FertilizingNotificationService instance =
      FertilizingNotificationService._();

  static const _channelId = 'fertilizing_reminders';
  static const _channelName = 'Fertilizing reminders';
  static const _acceptActionId = 'fertilizing_accept';
  static const _payloadPrefix = 'fertilizing:';

  /// Stable small IDs (must stay well below Android PendingIntent action
  /// spacing of `id * 16` to avoid 32-bit overflow / collisions).
  static const _idDueToday = 91001;
  static const _idUpcomingEve = 91002;
  static const _idUpcomingDay = 91003;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  var _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    await _ensureAndroidChannel();
    _initialized = true;

    // Cold start from the Accept action: callback may be missed until after
    // initialize, so apply launch details explicitly.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      unawaited(_onNotificationResponse(response));
    }
  }

  Future<void> _ensureAndroidChannel() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Reminders before and on fertilizing days',
        importance: Importance.high,
      ),
    );
  }

  Future<bool> isPermissionGranted() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final enabled = await android?.areNotificationsEnabled();
      return enabled ?? true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      return (settings?.isAlertEnabled ?? false) ||
          (settings?.isBadgeEnabled ?? false) ||
          (settings?.isSoundEnabled ?? false);
    }

    return true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      return granted ?? true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? true;
    }

    return true;
  }

  /// Rebuilds the whole fertilizing schedule (batch model — not per plant).
  Future<void> rescheduleAllActivePlants() async {
    await initialize();
    await _cancelFertilizingNotifications();

    final plants = await PlantService().getPlants().first;
    final now = DateTime.now();
    final seasonSettings = FertilizingSeasonController.instance.settings;

    final eligible = <Plant>[];
    for (final plant in plants) {
      if (plant.isArchived) continue;
      if (!isFertilizingActive(plant.fertilizingFrequencyDays)) continue;
      eligible.add(plant);
    }

    DateTime? nextDueFor(Plant plant) {
      final quarantineSeason = plant.quarantineUntil == null
          ? null
          : seasonSettings.growthSeasonForDate(plant.quarantineUntil!);
      return nextFertilizingDate(
        frequencyDays: plant.fertilizingFrequencyDays,
        lastFertilizedAt: plant.lastFertilizedAt,
        createdAt: plant.createdAt,
        now: now,
        quarantineUntil: plant.quarantineUntil,
        quarantineSeason: quarantineSeason,
      );
    }

    final groups = groupFertilizingReminderTargets<Plant>(
      items: eligible,
      nextDueDate: nextDueFor,
      now: now,
    );

    final l10n = _resolveL10n();

    if (groups.dueTodayOrOverdue.isNotEmpty) {
      final fireAt = fertilizingBatchDayFireAt(
        dueDay: DateTime(now.year, now.month, now.day),
        now: now,
      );
      if (fireAt != null) {
        final overdue = groups.dueTodayOrOverdue.any((plant) {
          final quarantineSeason = plant.quarantineUntil == null
              ? null
              : seasonSettings.growthSeasonForDate(plant.quarantineUntil!);
          return isFertilizingOverdue(
            frequencyDays: plant.fertilizingFrequencyDays,
            lastFertilizedAt: plant.lastFertilizedAt,
            createdAt: plant.createdAt,
            now: now,
            quarantineUntil: plant.quarantineUntil,
            quarantineSeason: quarantineSeason,
          );
        });
        await _scheduleDayBatch(
          id: _idDueToday,
          when: fireAt,
          plants: groups.dueTodayOrOverdue,
          overdue: overdue,
          l10n: l10n,
        );
      }
    }

    // Tomorrow cohort: eve tonight + morning tomorrow.
    if (groups.dueTomorrow.isNotEmpty) {
      final tomorrow = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      final eveAt = fertilizingBatchEveFireAt(dueDay: tomorrow, now: now);
      if (eveAt != null) {
        await _scheduleEveBatch(
          id: _idUpcomingEve,
          when: eveAt,
          plants: groups.dueTomorrow,
          l10n: l10n,
        );
      }
      final dayAt = fertilizingBatchDayFireAt(dueDay: tomorrow, now: now);
      if (dayAt != null) {
        await _scheduleDayBatch(
          id: _idUpcomingDay,
          when: dayAt,
          plants: groups.dueTomorrow,
          overdue: false,
          l10n: l10n,
        );
      }
    } else {
      // Next cohort after tomorrow (only when nothing is due tomorrow, so the
      // fixed eve/day slots stay free).
      final futureDay = groups.nextFutureDueDate;
      final futurePlants = groups.dueOnNextFutureDate;
      if (futureDay != null && futurePlants.isNotEmpty) {
        final eveAt = fertilizingBatchEveFireAt(dueDay: futureDay, now: now);
        if (eveAt != null) {
          await _scheduleEveBatch(
            id: _idUpcomingEve,
            when: eveAt,
            plants: futurePlants,
            l10n: l10n,
          );
        }
        final dayAt = fertilizingBatchDayFireAt(dueDay: futureDay, now: now);
        if (dayAt != null) {
          await _scheduleDayBatch(
            id: _idUpcomingDay,
            when: dayAt,
            plants: futurePlants,
            overdue: false,
            l10n: l10n,
          );
        }
      }
    }
  }

  /// Compatibility: batch schedule is global, so any plant change rebuilds all.
  Future<void> rescheduleForPlant(Plant plant) async {
    await rescheduleAllActivePlants();
  }

  /// Compatibility: after archive/delete, rebuild the remaining schedule.
  Future<void> cancelForPlant(String plantId) async {
    await rescheduleAllActivePlants();
  }

  Future<void> cancelAll() async {
    await initialize();
    await _cancelFertilizingNotifications();
  }

  Future<void> _cancelFertilizingNotifications() async {
    await _plugin.cancel(_idDueToday);
    await _plugin.cancel(_idUpcomingEve);
    await _plugin.cancel(_idUpcomingDay);

    final pending = await _plugin.pendingNotificationRequests();
    for (final request in pending) {
      final payload = request.payload;
      if (payload != null && payload.startsWith(_payloadPrefix)) {
        await _plugin.cancel(request.id);
      }
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final active = await android?.getActiveNotifications();
    if (active == null) return;
    for (final notification in active) {
      if (notification.channelId == _channelId) {
        await _plugin.cancel(notification.id ?? 0);
      }
    }
  }

  Future<void> _scheduleEveBatch({
    required int id,
    required DateTime when,
    required List<Plant> plants,
    required AppLocalizations l10n,
  }) async {
    final title = l10n.fertilizingReminderEveTitle;
    final body = plants.length == 1
        ? l10n.fertilizingReminderEveBodyOne(_displayName(plants.first))
        : l10n.fertilizingReminderEveBodyCount(plants.length);
    await _schedule(
      id: id,
      when: when,
      title: title,
      body: body,
      payload: '${_payloadPrefix}eve',
      acceptLabel: null,
    );
  }

  Future<void> _scheduleDayBatch({
    required int id,
    required DateTime when,
    required List<Plant> plants,
    required bool overdue,
    required AppLocalizations l10n,
  }) async {
    final single = plants.length == 1 ? plants.first : null;
    final title = single != null
        ? l10n.fertilizingReminderDayTitle(_displayName(single))
        : l10n.fertilizingReminderDayTitleBatch;
    final body = single != null
        ? (overdue
            ? l10n.fertilizingReminderOverdueBody
            : l10n.fertilizingReminderDayBody)
        : (overdue
            ? l10n.fertilizingReminderDayBodyCountOverdue(plants.length)
            : l10n.fertilizingReminderDayBodyCount(plants.length));
    final payload = single != null
        ? '${_payloadPrefix}day:single:${single.id}'
        : '${_payloadPrefix}day:batch';
    await _schedule(
      id: id,
      when: when,
      title: title,
      body: body,
      payload: payload,
      acceptLabel: single != null ? l10n.fertilizingReminderAccept : null,
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String payload,
    required String? acceptLabel,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders before and on fertilizing days',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ongoing: false,
      autoCancel: true,
      actions: acceptLabel == null
          ? null
          : [
              AndroidNotificationAction(
                _acceptActionId,
                acceptLabel,
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ],
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
      payload: payload,
    );
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (response.actionId != _acceptActionId) return;
    final payload = response.payload;
    if (payload == null || !payload.startsWith(_payloadPrefix)) return;

    final singlePrefix = '${_payloadPrefix}day:single:';
    if (!payload.startsWith(singlePrefix)) return;
    final plantId = payload.substring(singlePrefix.length);
    if (plantId.isEmpty) return;

    // Ensure the tray entry is gone even if cancelNotification raced.
    if (response.id != null) {
      await _plugin.cancel(response.id!);
    }

    await _acceptFertilizing(plantId);
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

  Future<void> _acceptFertilizing(String plantId) async {
    // markFertilizedToday reschedules fertilizing reminders via PlantService.
    await PlantService().markFertilizedToday(plantId);
  }

  static String _displayName(Plant plant) {
    final nickname = plant.nickname.trim();
    if (nickname.isNotEmpty) return nickname;
    final species = plant.species.trim();
    if (species.isNotEmpty) return species;
    return plant.genus.trim();
  }
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  unawaited(
    FertilizingNotificationService.instance._onNotificationResponse(response),
  );
}
