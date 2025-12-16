// lib/models/reminder.dart

class Reminder {
  final int? id;
  final int userId;
  final int? medicineId;
  final String medicineName;
  final String? description;
  final bool isRepeatEnabled;
  final String repeatMode; // 'Một lần', 'Hằng ngày', 'Từ thứ 2 đến thứ 6', 'Tùy chỉnh'
  final List<int> customDays; // [0-6] where 0 = Monday, 6 = Sunday
  final List<String> times; // ['08:00', '12:00', '18:00']
  final bool isEnabled;
  final DateTime createdAt;

  Reminder({
    this.id,
    required this.userId,
    this.medicineId,
    required this.medicineName,
    this.description,
    required this.isRepeatEnabled,
    required this.repeatMode,
    required this.customDays,
    required this.times,
    required this.isEnabled,
    required this.createdAt,
  });

  // Chuyển từ Map sang Reminder object
  factory Reminder.fromMap(Map<String, dynamic> map) {
    // Parse custom_days từ string sang List<int>
    List<int> parsedCustomDays = [];
    if (map['custom_days'] != null && map['custom_days'].toString().isNotEmpty) {
      try {
        parsedCustomDays = (map['custom_days'] as String)
            .split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s.trim()))
            .toList();
      } catch (e) {
        parsedCustomDays = [];
      }
    }

    // Parse times từ string sang List<String>
    List<String> parsedTimes = [];
    if (map['times'] != null && map['times'].toString().isNotEmpty) {
      parsedTimes = (map['times'] as String)
          .split(',')
          .map((s) => s.trim())
          .toList();
    }

    return Reminder(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      medicineId: map['medicine_id'] as int?,
      medicineName: map['medicine_name'] as String,
      description: map['description'] as String?,
      isRepeatEnabled: (map['is_repeat_enabled'] as int) == 1,
      repeatMode: map['repeat_mode'] as String,
      customDays: parsedCustomDays,
      times: parsedTimes,
      isEnabled: (map['is_enabled'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Chuyển từ Reminder object sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'medicine_id': medicineId,
      'medicine_name': medicineName,
      'description': description,
      'is_repeat_enabled': isRepeatEnabled ? 1 : 0,
      'repeat_mode': repeatMode,
      'custom_days': customDays.join(','),
      'times': times.join(','),
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with - để update dữ liệu
  Reminder copyWith({
    int? id,
    int? userId,
    int? medicineId,
    String? medicineName,
    String? description,
    bool? isRepeatEnabled,
    String? repeatMode,
    List<int>? customDays,
    List<String>? times,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      description: description ?? this.description,
      isRepeatEnabled: isRepeatEnabled ?? this.isRepeatEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      customDays: customDays ?? this.customDays,
      times: times ?? this.times,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper method: Kiểm tra reminder có hoạt động vào ngày cụ thể không
  bool isActiveOnDay(int dayOfWeek) {
    if (!isRepeatEnabled || repeatMode == 'Một lần') {
      return true;
    }
    if (repeatMode == 'Hằng ngày') {
      return true;
    }
    if (repeatMode == 'Từ thứ 2 đến thứ 6') {
      return dayOfWeek >= 0 && dayOfWeek <= 4; // Monday to Friday
    }
    if (repeatMode == 'Tùy chỉnh') {
      return customDays.contains(dayOfWeek);
    }
    return false;
  }

  // Helper method: Lấy tên hiển thị của repeat mode
  String getRepeatModeDisplay() {
    if (!isRepeatEnabled) {
      return 'Không lặp lại';
    }
    if (repeatMode == 'Tùy chỉnh' && customDays.isNotEmpty) {
      final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      final selectedDayNames = customDays.map((day) => dayNames[day]).toList();
      return selectedDayNames.join(', ');
    }
    return repeatMode;
  }

  // Helper method: Lấy thời gian tiếp theo
  String? getNextTime() {
    if (times.isEmpty) return null;
    
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    for (final time in times) {
      final parts = time.split(':');
      final timeMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      
      if (timeMinutes > currentMinutes) {
        return time;
      }
    }

    // Nếu tất cả thời gian đã qua, trả về thời gian đầu tiên
    return times.first;
  }

  @override
  String toString() {
    return 'Reminder(id: $id, medicineName: $medicineName, times: $times, repeatMode: $repeatMode, isEnabled: $isEnabled)';
  }
}