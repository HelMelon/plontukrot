import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/locale/app_locale_controller.dart';
import '../core/l10n/app_localizations_x.dart';
import '../l10n/app_localizations.dart';
import '../models/fertilizing_frequency.dart';
import '../models/plant.dart';
import 'plant_service.dart';

/// Local notifications for fertilizing reminders (eve + feeding day).
class FertilizingNotificationService {
  FertilizingNotificationService._();

  static final FertilizingNotificationService instance =
      FertilizingNotificationService._();

  static const _channelId = 'fertilizing_reminders';
  static const _channelName = 'Fertilizing reminders';
  static const _acceptActionId = 'fertilizing_accept';
  static const _payloadPrefix = 'fertilizing:';

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

  Future<bool> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await android?.requestNotificationsPermission();
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

  Future<void> rescheduleAllActivePlants() async {
    await initialize();
    final plants = await PlantService().getPlants().first;
    for (final plant in plants) {
      await rescheduleForPlant(plant);
    }
  }

  Future<void> rescheduleForPlant(Plant plant) async {
    await initialize();
    await cancelForPlant(plant.id);

    final frequency = plant.fertilizingFrequencyDays;
    if (!isFertilizingActive(frequency) || plant.isArchived) {
      return;
    }

    final l10n = _resolveL10n();
    final now = DateTime.now();
    final eveAt = fertilizingEveNotificationAt(
      frequencyDays: frequency,
      lastFertilizedAt: plant.lastFertilizedAt,
      createdAt: plant.createdAt,
      now: now,
    );
    final dayAt = fertilizingDayNotificationAt(
      frequencyDays: frequency,
      lastFertilizedAt: plant.lastFertilizedAt,
      createdAt: plant.createdAt,
      now: now,
    );

    if (eveAt != null) {
      await _schedule(
        id: _eveNotificationId(plant.id),
        when: eveAt,
        title: l10n.fertilizingReminderEveTitle,
        body: l10n.fertilizingReminderEveBody(
          l10n.fertilizingStageGenitive(plant.stage),
        ),
        acceptLabel: l10n.fertilizingReminderAccept,
        fullScreen: false,
        plantId: plant.id,
      );
    }

    if (dayAt != null) {
      final displayName = plant.nickname.trim().isEmpty
          ? plant.species.trim()
          : plant.nickname.trim();
      final dayTitle = plant.isFertilizingFrequencyCustom
          ? l10n.fertilizingReminderDayTitle(displayName)
          : l10n.fertilizingReminderDayTitleStage(
              l10n.fertilizingStageGenitive(plant.stage),
            );
      await _schedule(
        id: _dayNotificationId(plant.id),
        when: dayAt,
        title: dayTitle,
        body: l10n.fertilizingReminderDayBody,
        acceptLabel: l10n.fertilizingReminderAccept,
        fullScreen: true,
        plantId: plant.id,
      );
    }
  }

  Future<void> cancelForPlant(String plantId) async {
    await initialize();
    await _plugin.cancel(_eveNotificationId(plantId));
    await _plugin.cancel(_dayNotificationId(plantId));
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    required String acceptLabel,
    required bool fullScreen,
    required String plantId,
  }) async {
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Reminders before and on fertilizing days',
      importance: Importance.high,
      priority: Priority.high,
      fullScreenIntent: fullScreen,
      category: fullScreen
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      ongoing: fullScreen,
      autoCancel: !fullScreen,
      actions: fullScreen
          ? [
              AndroidNotificationAction(
                _acceptActionId,
                acceptLabel,
                showsUserInterface: true,
                cancelNotification: true,
              ),
            ]
          : null,
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
      payload: '$_payloadPrefix$plantId',
    );
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (response.actionId != _acceptActionId) return;
    final payload = response.payload;
    if (payload == null || !payload.startsWith(_payloadPrefix)) return;
    final plantId = payload.substring(_payloadPrefix.length);
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
    final service = PlantService();
    await service.markFertilizedToday(plantId);
    final plant = await service.getPlant(plantId);
    if (plant != null) {
      await rescheduleForPlant(plant);
    }
  }

  static int _eveNotificationId(String plantId) =>
      (plantId.hashCode & 0x3FFFFFFF) * 2;

  static int _dayNotificationId(String plantId) =>
      (plantId.hashCode & 0x3FFFFFFF) * 2 + 1;
}

@pragma('vm:entry-point')
void _onBackgroundNotificationResponse(NotificationResponse response) {
  unawaited(
    FertilizingNotificationService.instance._onNotificationResponse(response),
  );
}
