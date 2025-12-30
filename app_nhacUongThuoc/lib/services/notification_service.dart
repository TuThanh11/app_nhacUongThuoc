import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder.dart';
import '../main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'medicine_reminder_channel';
  static const String channelName = 'Medicine Reminders';
  static const String channelDescription = 'Notifications for medicine reminders';

  // ✅ Không cần callback nữa vì dùng AlarmManagerService

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
      importance: Importance.max,
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
    // ✅ Backup: chỉ xử lý khi user tap vào notification
    final payload = response.payload;
    if (payload != null) {
      print('Notification tapped with payload: $payload');
      // Có thể thêm xử lý nếu cần
    }
  }

  // ✅ Helper method: Convert String ID to numeric hash
  int _getNumericId(String? stringId) {
    if (stringId == null) return 0;
    return stringId.hashCode.abs();
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.isEnabled) return;

    final numericReminderId = _getNumericId(reminder.id);

    for (int i = 0; i < reminder.times.length; i++) {
      final time = reminder.times[i];
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      if (reminder.isRepeatEnabled) {
        await _scheduleRepeatingNotification(
          reminder,
          hour,
          minute,
          i,
          numericReminderId,
        );
      } else {
        await _scheduleOneTimeNotification(
          reminder,
          hour,
          minute,
          i,
          numericReminderId,
        );
      }
    }
  }

  Future<void> _scheduleRepeatingNotification(
    Reminder reminder,
    int hour,
    int minute,
    int index,
    int numericReminderId,
  ) async {
    final now = DateTime.now();
    
    List<int> daysToSchedule = [];
    
    if (reminder.repeatMode == 'Hằng ngày') {
      daysToSchedule = [1, 2, 3, 4, 5, 6, 7];
    } else if (reminder.repeatMode == 'Từ thứ 2 đến thứ 6') {
      daysToSchedule = [1, 2, 3, 4, 5];
    } else if (reminder.repeatMode == 'Tùy chỉnh') {
      daysToSchedule = reminder.customDays.map((d) => d + 1).toList();
    }

    for (final dayOfWeek in daysToSchedule) {
      var scheduledDate = _getNextInstanceOfDayAndTime(dayOfWeek, hour, minute);
      
      final notificationId = _generateNotificationId(
        numericReminderId,
        index,
        dayOfWeek,
      );

      // ✅ Payload chứa thông tin để navigate
      final payload = '${reminder.id}|||${reminder.medicineName}|||${reminder.times[index]}';

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
            importance: Importance.max,
            priority: Priority.max,
            fullScreenIntent: true, // ✅ Hiển thị full screen
            category: AndroidNotificationCategory.alarm,
            sound: const RawResourceAndroidNotificationSound('alarm'),
            playSound: true,
            enableVibration: true,
            //vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
            autoCancel: false, // ✅ Không tự động đóng
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'alarm.mp3',
            interruptionLevel: InterruptionLevel.critical, // ✅ iOS critical alert
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    }
  }

  Future<void> _scheduleOneTimeNotification(
    Reminder reminder,
    int hour,
    int minute,
    int index,
    int numericReminderId,
  ) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    if (reminder.customDays.isNotEmpty) {
      final targetDayOfWeek = reminder.customDays[0];
      scheduledDate = _getNextInstanceOfDayAndTime(
        targetDayOfWeek + 1,
        hour,
        minute,
      );
    }

    final notificationId = _generateNotificationId(
      numericReminderId,
      index,
      0,
    );

    final payload = '${reminder.id}|||${reminder.medicineName}|||${reminder.times[index]}';

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
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
          autoCancel: false,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'alarm.mp3',
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
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
    
    if (scheduledDate.isBefore(DateTime.now())) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    
    return scheduledDate;
  }

  int _generateNotificationId(int reminderId, int timeIndex, int dayOfWeek) {
    return reminderId * 1000 + timeIndex * 10 + dayOfWeek;
  }

  Future<void> cancelReminder(dynamic reminderId) async {
    try {
      final numericId = reminderId is String 
          ? _getNumericId(reminderId) 
          : reminderId as int;
      
      print('Cancelling all notifications for reminder ID: $reminderId (numeric: $numericId)');
      
      for (int timeIndex = 0; timeIndex < 100; timeIndex++) {
        for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
          final notificationId = _generateNotificationId(numericId, timeIndex, dayOfWeek);
          await _notifications.cancel(notificationId);
        }
      }
      
      final snoozeId = _generateNotificationId(numericId, 999, 0);
      await _notifications.cancel(snoozeId);
      
      print('✅ Successfully cancelled all notifications');
    } catch (e) {
      print('Error in cancelReminder: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelDisplayedNotifications(String reminderId) async {
    try {
      final numericId = _getNumericId(reminderId);
      
      for (int timeIndex = 0; timeIndex < 100; timeIndex++) {
        for (int dayOfWeek = 0; dayOfWeek < 7; dayOfWeek++) {
          final notificationId = _generateNotificationId(numericId, timeIndex, dayOfWeek);
          await _notifications.cancel(notificationId);
        }
      }
      
      final snoozeId = _generateNotificationId(numericId, 999, 0);
      await _notifications.cancel(snoozeId);
      
      print('✅ Cancelled all displayed notifications for reminder: $reminderId');
    } catch (e) {
      print('Error cancelling displayed notifications: $e');
    }
  }
}