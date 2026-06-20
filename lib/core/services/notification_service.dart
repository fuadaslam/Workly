import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/launcher_icon');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'enquiry_followup',
          'Enquiry Follow-ups',
          description: 'Reminders for enquiry follow-up dates',
          importance: Importance.high,
        ));

    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static const _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'enquiry_followup',
      'Enquiry Follow-ups',
      channelDescription: 'Reminders for enquiry follow-up dates',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static Future<void> scheduleFollowUpReminder({
    required int id,
    required String clientName,
    required String enquiryCode,
    required DateTime followUpDate,
  }) async {
    await init();

    final scheduledDate = DateTime(
      followUpDate.year, followUpDate.month, followUpDate.day, 9, 0, 0,
    );
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id: id,
      title: 'Follow-up due: $clientName',
      body: 'Enquiry $enquiryCode requires your attention today.',
      scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails: _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showOverdueReminder({
    required String clientName,
    required String enquiryCode,
    required int daysOverdue,
  }) async {
    await init();
    await _plugin.show(
      id: enquiryCode.hashCode,
      title: 'Overdue follow-up: $clientName',
      body: '$enquiryCode is $daysOverdue day${daysOverdue == 1 ? '' : 's'} overdue.',
      notificationDetails: _notifDetails,
    );
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
