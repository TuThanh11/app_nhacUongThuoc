import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reminder.dart';
import '../services/api_service.dart';
import '../main.dart';
import '../screens/medicine_call.dart';

class AlarmManagerService {
  static final AlarmManagerService _instance = AlarmManagerService._internal();
  factory AlarmManagerService() => _instance;
  AlarmManagerService._internal();
  final Map<String, Timer> _snoozeTimers = {}; 
  final Map<String, int> _snoozeCount = {}; // Đếm số lần snooze

  Timer? _checkTimer;
  final Set<String> _triggeredAlarms = {}; // Để tránh trigger nhiều lần

  // ✅ Bắt đầu service kiểm tra alarm
  void startMonitoring() {
    print('🚀 AlarmManagerService started');
    
    // Kiểm tra mỗi 30 giây
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkAlarms();
    });
    
    // Kiểm tra ngay lập tức khi start
    _checkAlarms();
  }

  // Dừng service
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    // Cancel tất cả snooze timers
    for (var timer in _snoozeTimers.values) {
      timer.cancel();
    }
    _snoozeTimers.clear();
    print('⛔ AlarmManagerService stopped');
  }

  void scheduleSnooze({
    required String reminderId,
    required String medicineName,
    required String time,
    String? description,
  }) {
    // Lấy số lần đã snooze
    int currentCount = _snoozeCount[reminderId] ?? 0;
    
    // ✅ Nếu đã snooze 3 lần thì ghi nhận là missed
    if (currentCount >= 3) {
      print('❌ MISSED: $medicineName after 3 snoozes');
      _logMissedMedicine(reminderId, medicineName, time);
      _snoozeCount.remove(reminderId);
      return;
    }
    
    // Tăng số lần snooze
    _snoozeCount[reminderId] = currentCount + 1;
    print('⏰ Scheduling snooze #${currentCount + 1} for $medicineName in 5 minutes');
    
    // Hủy snooze cũ nếu có
    _snoozeTimers[reminderId]?.cancel();
    
    // ✅ Tạo timer mới sau 5 phút
    _snoozeTimers[reminderId] = Timer(const Duration(minutes: 5), () {
      print('🔔 SNOOZE #${currentCount + 1} TRIGGERED: $medicineName');
      
      _showMedicineCallScreen(
        reminderId: reminderId,
        medicineName: medicineName,
        time: time,
        description: description,
      );
      
      // Xóa timer sau khi đã trigger
      _snoozeTimers.remove(reminderId);
    });
  }

  void clearSnooze(String reminderId) {
    _snoozeTimers[reminderId]?.cancel();
    _snoozeTimers.remove(reminderId);
    _snoozeCount.remove(reminderId);
    print('✅ Cleared snooze for reminder: $reminderId');
  }

  // HÀM GHI NHẬN MISSED
  Future<void> _logMissedMedicine(String reminderId, String medicineName, String time) async {
    try {
      final userId = await ApiService.instance.getUserId();
      if (userId == null) return;

      await ApiService.instance.logMedicineHistory(
        userId: userId,
        reminderId: reminderId,
        medicineName: medicineName,
        time: time,
        status: 'missed',
        timestamp: DateTime.now().toIso8601String(),
      );
      
      print('📝 Logged missed medicine: $medicineName');
    } catch (e) {
      print('Error logging missed medicine: $e');
    }
  }

  // ✅ Kiểm tra các alarm cần trigger
  Future<void> _checkAlarms() async {
    try {
      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;
      
      // Lấy userId
      final userId = await ApiService.instance.getUserId();
      if (userId == null) return;

      // Lấy tất cả reminders đang enable
      final remindersData = await ApiService.instance.getReminders(userId);
      final reminders = remindersData.map((data) {
        return Reminder.fromMap(data);
      }).where((r) => r.isEnabled).toList();

      print('⏰ Checking alarms at ${currentHour.toString().padLeft(2, '0')}:${currentMinute.toString().padLeft(2, '0')}');
      print('Found ${reminders.length} enabled reminders');

      for (var reminder in reminders) {
        // Kiểm tra reminder có active hôm nay không
        if (!reminder.isActiveOnDate(now)) {
          continue;
        }

        // Kiểm tra từng thời gian
        for (var timeStr in reminder.times) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          // Kiểm tra xem có đúng giờ không (cho phép sai lệch 1 phút)
          if (currentHour == hour && (currentMinute == minute || currentMinute == minute + 1)) {
            
            // Tạo unique key để tránh trigger nhiều lần
            final alarmKey = '${reminder.id}_${timeStr}_${now.day}';
            
            if (!_triggeredAlarms.contains(alarmKey)) {
              print('🔔 ALARM TRIGGERED: ${reminder.medicineName} at $timeStr');
              
              // Đánh dấu đã trigger
              _triggeredAlarms.add(alarmKey);
              
              // ✅ Hiển thị MedicineCallScreen
              _showMedicineCallScreen(
                reminderId: reminder.id!,
                medicineName: reminder.medicineName,
                time: timeStr,
                description: reminder.description,
              );
              
              // Xóa key sau 2 phút để có thể trigger lại nếu cần
              Future.delayed(const Duration(minutes: 2), () {
                _triggeredAlarms.remove(alarmKey);
              });
            }
          }
        }
      }
      
      // Dọn dẹp triggered alarms cũ (quá 1 giờ)
      _cleanupOldTriggers();
    } catch (e) {
      print('Error checking alarms: $e');
    }
  }

  // ✅ Hiển thị màn hình MedicineCall
  void _showMedicineCallScreen({
    required String reminderId,
    required String medicineName,
    required String time,
    String? description,
  }) {
    try {
      // Sử dụng global navigator key để navigate
      final context = navigatorKey.currentContext;
      if (context != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MedicineCallScreen(
              reminderId: reminderId,
              medicineName: medicineName,
              time: time,
              description: description,
            ),
            fullscreenDialog: true, // Hiển thị full screen
          ),
        );
      } else {
        print('❌ Navigator context is null');
      }
    } catch (e) {
      print('Error showing medicine call screen: $e');
    }
  }

  // ✅ Dọn dẹp các trigger cũ
  void _cleanupOldTriggers() {
    if (_triggeredAlarms.length > 100) {
      _triggeredAlarms.clear();
      print('🧹 Cleaned up old alarm triggers');
    }
  }

  // ✅ Force check ngay lập tức (dùng cho test)
  Future<void> forceCheck() async {
    print('🔍 Force checking alarms...');
    await _checkAlarms();
  }
}