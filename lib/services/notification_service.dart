import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

  static const int _limitBaseId = 1100;
  static const String limitChannelId = 'limit_warnings';

  Future<void> init() async {
    if (_inited) return;
    _inited = true;

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
}
