import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'medicine_reminder_channel';
  static const String channelName = 'Medicine Reminders';
  static const String channelDescription = 'Notifications for medicine reminders';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle notification tap - navigate to alarm screen
    final payload = response.payload;
    if (payload != null) {
      // Parse payload to get reminder info
      // Navigate to AlarmScreen
      print('Notification tapped: $payload');
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) return;

    for (int i = 0; i < reminder.times.length; i++) {
      final time = reminder.times[i];
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (reminder.isRepeatEnabled) {
        // Schedule repeating notifications
        await _scheduleRepeatingNotification(
          reminder,
          hour,
          minute,
          i,
        );
      } else {
        // Schedule one-time notification
        await _scheduleOneTimeNotification(
          reminder,
          hour,
          minute,
          i,
        );
      }
    }
  }

  Future<void> _scheduleRepeatingNotification(
    Reminder reminder,
    int hour,
    int minute,
    int index,
  ) async {
    final now = DateTime.now();
    
    List<int> daysToSchedule = [];
    
    if (reminder.repeatMode == 'Hằng ngày') {
      daysToSchedule = [1, 2, 3, 4, 5, 6, 7]; // All days
    } else if (reminder.repeatMode == 'Từ thứ 2 đến thứ 6') {
      daysToSchedule = [1, 2, 3, 4, 5]; // Monday to Friday
    } else if (reminder.repeatMode == 'Tùy chỉnh') {
      daysToSchedule = reminder.customDays.map((d) => d + 1).toList(); // Convert to 1-7
    }

    for (final dayOfWeek in daysToSchedule) {
      var scheduledDate = _getNextInstanceOfDayAndTime(dayOfWeek, hour, minute);
      
      // Generate unique ID for each notification
      final notificationId = _generateNotificationId(
        reminder.id ?? 0,
        index,
        dayOfWeek,
      );

      await _notifications.zonedSchedule(
        notificationId,
        'Đến giờ uống thuốc',
        reminder.medicineName,
        tz.TZDateTime.from(scheduledDate, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
            sound: const RawResourceAndroidNotificationSound('alarm'),
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'alarm.mp3',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: '${reminder.id}_$index',
      );
    }
  }

  Future<void> _scheduleOneTimeNotification(
    Reminder reminder,
    int hour,
    int minute,
    int index,
  ) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time has passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // For "Một lần" mode with custom days, schedule for the specific day
    if (reminder.customDays.isNotEmpty) {
      final targetDayOfWeek = reminder.customDays[0];
      scheduledDate = _getNextInstanceOfDayAndTime(
        targetDayOfWeek + 1,
        hour,
        minute,
      );
    }

    final notificationId = _generateNotificationId(
      reminder.id ?? 0,
      index,
      0,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Đến giờ uống thuốc',
      reminder.medicineName,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm.mp3',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${reminder.id}_$index',
    );
  }

  DateTime _getNextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    var scheduledDate = DateTime.now();
    
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    scheduledDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minute,
    );
    
    // If the time has passed today, schedule for next week
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }

  int _generateNotificationId(int reminderId, int timeIndex, int dayOfWeek) {
    // Generate unique ID combining reminder ID, time index, and day
    return reminderId * 1000 + timeIndex * 10 + dayOfWeek;
  }

  Future<void> cancelReminder(int reminderId) async {
    // Cancel all notifications for this reminder
    for (int i = 0; i < 100; i++) {
      await _notifications.cancel(_generateNotificationId(reminderId, i, 0));
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> scheduleSnooze(Reminder reminder, String time) async {
    final now = DateTime.now();
    final snoozeTime = now.add(const Duration(minutes: 5));

    final notificationId = _generateNotificationId(
      reminder.id ?? 0,
      999, // Special index for snooze
      0,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Nhắc lại: Đến giờ uống thuốc',
      reminder.medicineName,
      tz.TZDateTime.from(snoozeTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm.mp3',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: '${reminder.id}_snooze',
    );
  }
}