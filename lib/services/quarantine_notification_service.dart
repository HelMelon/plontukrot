import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/locale/app_locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/plant.dart';
import 'plant_service.dart';

/// Local notification when a plant leaves quarantine.
class QuarantineNotificationService {
  QuarantineNotificationService._();

  static final QuarantineNotificationService instance =
      QuarantineNotificationService._();

  static const _channelId = 'quarantine_reminders';
  static const _channelName = 'Quarantine reminders';
  static const _payloadPrefix = 'quarantine:';

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
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
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
        description: 'Notice when quarantine ends',
        importance: Importance.high,
      ),
    );
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

    if (plant.isArchived || !plant.isInQuarantine()) return;
    final until = plant.quarantineUntil;
    if (until == null) return;

    final when = DateTime(until.year, until.month, until.day, 9);
    final now = DateTime.now();
    if (!when.isAfter(now)) return;

    final l10n = _resolveL10n();
    final displayName = plant.nickname.trim().isEmpty
        ? plant.species.trim()
        : plant.nickname.trim();

    final tzWhen = tz.TZDateTime.from(when, tz.local);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notice when quarantine ends',
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
      _notificationId(plant.id),
      l10n.quarantineEndedTitle,
      l10n.quarantineEndedBody(displayName),
      tzWhen,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '$_payloadPrefix${plant.id}',
    );
  }

  Future<void> cancelForPlant(String plantId) async {
    await initialize();
    await _plugin.cancel(_notificationId(plantId));
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

  /// Distinct from fertilizing notification IDs (`hash*2` / `hash*2+1`).
  static int _notificationId(String plantId) =>
      (plantId.hashCode & 0x0FFFFFFF) + 0x30000000;
}
