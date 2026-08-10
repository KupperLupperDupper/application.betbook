import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper over flutter_local_notifications. It knows nothing about
/// localisation or money — callers pass fully-composed strings (composed from
/// the local store at fire time). All content is on-device; nothing is sent
/// anywhere. See NOTIFICATIONS_HANDOFF.md.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  /// The route a tapped notification wants to open. The app widget watches this
  /// and navigates, clearing it back to null.
  final ValueNotifier<String?> pendingRoute = ValueNotifier<String?>(null);

  static const int _weeklyId = 1001;
  static const int _limitBaseId = 1100;
  static const String weeklyChannelId = 'weekly_summary';
  static const String limitChannelId = 'limit_warnings';

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Fall back to UTC — a weekly nudge is inexact by design.
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: (resp) {
        final p = resp.payload;
        if (p != null && p.isNotEmpty) pendingRoute.value = p;
      },
    );

    // A cold-start tap (app launched from a notification).
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      final p = launch!.notificationResponse?.payload;
      if (p != null && p.isNotEmpty) pendingRoute.value = p;
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Asks the OS for POST_NOTIFICATIONS (Android 13+). Returns whether granted.
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? true;

  Future<bool> areEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  /// Schedules the weekly summary as a repeating Monday-09:00 nudge. The body is
  /// generic ("tap to see your week"); the figures live in the in-app card,
  /// because a scheduled OS notification cannot recompute them at fire time.
  Future<void> scheduleWeekly({
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _plugin.zonedSchedule(
      _weeklyId,
      title,
      body,
      _nextMonday9am(),
      NotificationDetails(
        android: AndroidNotificationDetails(
          weeklyChannelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: payload,
    );
  }

  Future<void> cancelWeekly() => _plugin.cancel(_weeklyId);

  /// Shows a limit warning immediately (fired from the RG evaluation).
  /// [slot] 0/1/2 keeps the three kinds from overwriting each other.
  Future<void> showLimit({
    required int slot,
    required String channelName,
    required String channelDesc,
    required String title,
    required String body,
    required String payload,
  }) {
    return _plugin.show(
      _limitBaseId + slot,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          limitChannelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          autoCancel: true,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  tz.TZDateTime _nextMonday9am() {
    final now = tz.TZDateTime.now(tz.local);
    var d = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    while (d.weekday != DateTime.monday || !d.isAfter(now)) {
      final next = d.add(const Duration(days: 1));
      d = tz.TZDateTime(tz.local, next.year, next.month, next.day, 9);
    }
    return d;
  }
}
