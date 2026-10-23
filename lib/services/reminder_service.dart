import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings: settings);
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return (await android?.requestNotificationsPermission()) ??
        (await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        )) ??
        true;
  }

  Future<void> schedule({
    required int id,
    required DateTime at,
    required String presetLabel,
  }) async {
    if (!at.isAfter(DateTime.now())) {
      throw ArgumentError('Reminder time must be in the future.');
    }
    await _plugin.zonedSchedule(
      id: id,
      title: 'Focus session reminder',
      body: 'Ready to begin $presetLabel?',
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'focus_reminders',
          'Focus reminders',
          channelDescription: 'Optional reminders for planned focus sessions',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) => _plugin.cancel(id: id);
}
