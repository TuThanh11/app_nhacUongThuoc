import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/reminder.dart';
import '../models/medicine.dart';
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

  static const String expiryChannelId = 'expiry_channel';
  static const String expiryChannelName = 'Cảnh báo hết hạn';
  static const String expiryChannelDescription = 'Thông báo khi thuốc sắp hết hạn';

  Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    
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

    // Create notification channels for Android
    const AndroidNotificationChannel reminderChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
    );

    const AndroidNotificationChannel expiryChannel = AndroidNotificationChannel(
      expiryChannelId,
      expiryChannelName,
      description: expiryChannelDescription,
      importance: Importance.high,
    );

    final plugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    await plugin?.createNotificationChannel(reminderChannel);
    await plugin?.createNotificationChannel(expiryChannel);
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null) {
      print('Notification tapped with payload: $payload');
    }
  }

  int _getNumericId(String? stringId) {
    if (stringId == null) return 0;
    return stringId.hashCode.abs();
  }

  // ==================== MEDICINE REMINDER NOTIFICATIONS ====================

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
      
      print('Successfully cancelled all notifications');
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

  // ==================== MEDICINE EXPIRY NOTIFICATIONS ====================

  /// Schedule expiry notifications for a medicine
  /// Notifies at: 30 days, 14 days, 7 days, 3 days, 1 day, and on expiry date
  Future<void> scheduleMedicineExpiryNotification(Medicine medicine) async {
    if (medicine.id == null) return;

    final now = DateTime.now();
    final expiryDate = medicine.expiryDate;
    final daysUntilExpiry = expiryDate.difference(now).inDays;

    // Cancel existing notifications for this medicine
    await cancelMedicineExpiryNotifications(medicine.id!);

    // Notification schedule: 30, 14, 7, 3, 1 days before and on expiry date
    final notificationDays = [30, 14, 7, 3, 1, 0];

    for (final daysBeforeExpiry in notificationDays) {
      if (daysUntilExpiry >= daysBeforeExpiry) {
        final notificationDate = expiryDate.subtract(Duration(days: daysBeforeExpiry));
        
        // Only schedule if notification date is in the future
        if (notificationDate.isAfter(now)) {
          await _scheduleExpiryNotification(
            medicine,
            notificationDate,
            daysBeforeExpiry,
          );
        }
      }
    }
  }

  Future<void> _scheduleExpiryNotification(
    Medicine medicine,
    DateTime notificationDate,
    int daysBeforeExpiry,
  ) async {
    // Schedule at 9:00 AM
    final scheduledDateTime = DateTime(
      notificationDate.year,
      notificationDate.month,
      notificationDate.day,
      9,
      0,
    );

    final notificationId = _generateExpiryNotificationId(
      medicine.id!,
      daysBeforeExpiry,
    );

    String title;
    String body;
    
    if (daysBeforeExpiry == 0) {
      title = 'Thuốc đã hết hạn!';
      body = 'Thuốc "${medicine.name}" đã hết hạn hôm nay. Vui lòng kiểm tra và không sử dụng.';
    } else if (daysBeforeExpiry == 1) {
      title = 'Thuốc sắp hết hạn!';
      body = 'Thuốc "${medicine.name}" sẽ hết hạn vào ngày mai (${_formatDate(medicine.expiryDate)}).';
    } else if (daysBeforeExpiry <= 7) {
      title = 'Cảnh báo hết hạn';
      body = 'Thuốc "${medicine.name}" sẽ hết hạn trong $daysBeforeExpiry ngày nữa (${_formatDate(medicine.expiryDate)}).';
    } else {
      title = 'Nhắc nhở hạn sử dụng';
      body = 'Thuốc "${medicine.name}" sẽ hết hạn trong $daysBeforeExpiry ngày (${_formatDate(medicine.expiryDate)}).';
    }

    await _notifications.zonedSchedule(
      notificationId,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          expiryChannelId,
          expiryChannelName,
          channelDescription: expiryChannelDescription,
          importance: daysBeforeExpiry <= 3 ? Importance.max : Importance.high,
          priority: daysBeforeExpiry <= 3 ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          color: daysBeforeExpiry == 0 ? Colors.red : Colors.orange,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: daysBeforeExpiry <= 3 
              ? InterruptionLevel.critical 
              : InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'expiry|||${medicine.id}|||${medicine.name}',
    );

    print('Scheduled expiry notification for "${medicine.name}" - $daysBeforeExpiry days before');
  }

  int _generateExpiryNotificationId(String medicineId, int daysBeforeExpiry) {
    final baseId = medicineId.hashCode.abs();
    return (baseId * 100) + daysBeforeExpiry;
  }

  Future<void> cancelMedicineExpiryNotifications(String medicineId) async {
    final notificationDays = [30, 14, 7, 3, 1, 0];
    
    for (final days in notificationDays) {
      final notificationId = _generateExpiryNotificationId(medicineId, days);
      await _notifications.cancel(notificationId);
    }
    
    print('Cancelled all expiry notifications for medicine: $medicineId');
  }

  /// Schedule expiry notifications for all medicines
  Future<void> scheduleAllMedicineExpiryNotifications(List<Medicine> medicines) async {
    print('📅 Scheduling expiry notifications for ${medicines.length} medicines');
    
    for (final medicine in medicines) {
      await scheduleMedicineExpiryNotification(medicine);
    }
    
    print('Completed scheduling all medicine expiry notifications');
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Show immediate expiry warning (for testing or immediate alerts)
  Future<void> showExpiryWarning(String medicineName, DateTime expiryDate) async {
    final daysLeft = expiryDate.difference(DateTime.now()).inDays;
    
    String title;
    String body;
    
    if (daysLeft < 0) {
      title = 'Thuốc đã hết hạn!';
      body = 'Thuốc "$medicineName" đã hết hạn. Vui lòng không sử dụng.';
    } else if (daysLeft == 0) {
      title = 'Thuốc hết hạn hôm nay!';
      body = 'Thuốc "$medicineName" sẽ hết hạn vào hôm nay.';
    } else if (daysLeft <= 3) {
      title = 'Thuốc sắp hết hạn!';
      body = 'Thuốc "$medicineName" sẽ hết hạn trong $daysLeft ngày (${_formatDate(expiryDate)}).';
    } else {
      title = 'Nhắc nhở hạn sử dụng';
      body = 'Thuốc "$medicineName" sẽ hết hạn vào ${_formatDate(expiryDate)} (còn $daysLeft ngày).';
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      expiryChannelId,
      expiryChannelName,
      channelDescription: expiryChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Colors.orange,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _notifications.show(
      medicineName.hashCode,
      title,
      body,
      platformDetails,
    );
  }
}