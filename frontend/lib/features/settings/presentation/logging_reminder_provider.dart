
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:frontend/features/settings/domain/reminder_frequency.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

part 'logging_reminder_provider.g.dart';


// logging_reminder.dart
//
// Riverpod Notifier that schedules a repeating local notification (iOS only)
// to remind the user to log an expense, based on a ReminderFrequency.
//
// pubspec.yaml dependencies:
//   flutter_riverpod: ^2.5.1
//   flutter_local_notifications: ^18.0.1
//   timezone: ^0.9.4
//   flutter_timezone: ^3.0.0   // used to read the device's IANA timezone name
//
// Notes:
// - This only configures the iOS (Darwin) side of flutter_local_notifications.
//   `androidScheduleMode` is still passed to zonedSchedule() because it's a
//   required parameter of the plugin API, but it has no effect on iOS.
// - Permission is requested lazily, the first time a reminder is actually
//   scheduled, rather than at app launch.
// - State is kept in memory only. If you want the choice to survive app
//   restarts, persist `state` (e.g. with shared_preferences) whenever it
//   changes and read it back in `build()`.
@Riverpod(keepAlive: true)
class LoggingReminder extends Notifier<ReminderFrequency> {
  static const _notificationId = 1001;
  static const _title = 'Log your expenses';
  static const _body = "Don't forget to log today's spending.";

  // Time of day the reminder fires at.
  static const _hour = 20;
  static const _minute = 0;

  // Day used for the weekly reminder (Monday).
  static const _weeklyWeekday = DateTime.monday;

  final _plugin = FlutterLocalNotificationsPlugin();
  late final Future<void> _initialized;

  @override
  ReminderFrequency build() {
    // Kick off plugin/timezone setup once; every public method awaits this
    // before touching the plugin, so call order doesn't matter.
    _initialized = _initializePlugin();
    return ReminderFrequency.none;
  }

  Future<void> _initializePlugin() async {
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (_) {
      // Fall back rather than leaving timezone unset.
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(iOS: iosSettings),
    );
  }

  Future<bool> _requestPermissions() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }

  /// Schedules (or cancels) the logging reminder to match [frequency] and
  /// updates state accordingly. Passing [ReminderFrequency.none] cancels the
  /// reminder, same as calling [cancelAll].
  ///
  /// Returns false if [frequency] requires scheduling but notification
  /// permission was denied (state is reset to `none` in that case).
  Future<bool> set(ReminderFrequency frequency) async {
    await _initialized;
    await _plugin.cancel(id: _notificationId);

    if (frequency == ReminderFrequency.none) {
      state = ReminderFrequency.none;
      return true;
    }

    final granted = await _requestPermissions();
    if (!granted) {
      state = ReminderFrequency.none;
      return false;
    }

    await _plugin.zonedSchedule(
      id: _notificationId,
      title: _title,
      body: _body,
      scheduledDate: _nextInstance(frequency),
      notificationDetails: 
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentList: true,
          sound: 'noti.wav',
          presentBanner: true
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: _matchComponents(frequency),
    );

    state = frequency;
    return true;
  }

  /// Cancels the reminder (and, for safety, any other pending notifications
  /// this app has scheduled) and resets state to [ReminderFrequency.none].
  Future<void> cancelAll() async {
    await _initialized;
    await _plugin.cancelAll();
    state = ReminderFrequency.none;
  }

  DateTimeComponents? _matchComponents(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return DateTimeComponents.time;
      case ReminderFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case ReminderFrequency.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case ReminderFrequency.none:
        return null;
    }
  }

  /// Computes the next fire time for [frequency], in the local timezone.
  tz.TZDateTime _nextInstance(ReminderFrequency frequency) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, _hour, _minute);

    switch (frequency) {
      case ReminderFrequency.daily:
        if (!scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        return scheduled;

      case ReminderFrequency.weekly:
        while (scheduled.weekday != _weeklyWeekday || !scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        return scheduled;

      case ReminderFrequency.monthly:
        scheduled =
            tz.TZDateTime(tz.local, now.year, now.month, 1, _hour, _minute);
        if (!scheduled.isAfter(now)) {
          final nextMonth = now.month == 12 ? 1 : now.month + 1;
          final nextYear = now.month == 12 ? now.year + 1 : now.year;
          scheduled =
              tz.TZDateTime(tz.local, nextYear, nextMonth, 1, _hour, _minute);
        }
        return scheduled;

      case ReminderFrequency.none:
        return now;
    }
  }
}