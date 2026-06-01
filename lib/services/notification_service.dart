import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service — handles FCM + local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kamer_sync_channel',
      'KamerSync Notifications',
      channelDescription: 'Land management system notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    // Generate a unique ID based on timestamp
    final id = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    await _plugin.show(
      id, // Changed to named parameter
      title, // Changed to named parameter
      body, // Changed to named parameter
      details,
      payload: payload,
    );
  }
}
