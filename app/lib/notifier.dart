import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Notifier {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static int _id = 0;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    final impl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await impl?.requestNotificationsPermission();
    _ready = true;
  }

  static Future<void> show(String title, String body) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'parkify_slots',
        'Slot alerts',
        channelDescription: 'Tells you when a watched slot becomes free',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(_id++, title, body, details);
  }
}
