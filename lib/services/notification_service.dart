import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
      },
    );

    // Request permissions for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    int? progress,
    int? maxProgress,
    double? nozzleTemp,
    double? bedTemp,
  }) async {
    String finalBody = body;
    if (nozzleTemp != null && bedTemp != null) {
      finalBody = "$body  🌡️ ${nozzleTemp.round()}° / ${bedTemp.round()}°";
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'farm_manager_channel',
      'Printer Alerts',
      channelDescription: 'Notifications for printer status changes',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: progress != null,
      maxProgress: maxProgress ?? 100,
      progress: progress ?? 0,
      ongoing: progress != null && progress < (maxProgress ?? 100),
      onlyAlertOnce: true,
      showWhen: progress == null,
      category: progress != null ? AndroidNotificationCategory.progress : AndroidNotificationCategory.status,
      styleInformation: BigTextStyleInformation(finalBody),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final safeId = id.abs() % 0x7FFFFFFF;

    print("Showing notification: $title - $finalBody (ID: $safeId, Progress: $progress)");
    await _notificationsPlugin.show(safeId, title, finalBody, notificationDetails);
  }

  static Future<void> cancelNotification(int id) async {
    final safeId = id.abs() % 0x7FFFFFFF;
    await _notificationsPlugin.cancel(safeId);
  }
}
