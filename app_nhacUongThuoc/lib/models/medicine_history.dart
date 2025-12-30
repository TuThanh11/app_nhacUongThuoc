// lib/models/medicine_history.dart

class MedicineHistory {
  final int? id;
  final int userId;
  final int reminderId;
  final String medicineName;
  final String scheduledTime; // '08:00'
  final DateTime? actualTime; // Thời gian thực tế uống
  final String status; // 'completed', 'missed', 'late'
  final DateTime date;

  MedicineHistory({
    this.id,
    required this.userId,
    required this.reminderId,
    required this.medicineName,
    required this.scheduledTime,
    this.actualTime,
    required this.status,
    required this.date,
  });

  factory MedicineHistory.fromMap(Map<String, dynamic> map) {
    return MedicineHistory(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      reminderId: map['reminder_id'] as int,
      medicineName: map['medicine_name'] as String,
      scheduledTime: map['scheduled_time'] as String,
      actualTime: map['actual_time'] != null 
          ? DateTime.parse(map['actual_time'] as String)
          : null,
      status: map['status'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'reminder_id': reminderId,
      'medicine_name': medicineName,
      'scheduled_time': scheduledTime,
      'actual_time': actualTime?.toIso8601String(),
      'status': status,
      'date': date.toIso8601String(),
    };
  }

  MedicineHistory copyWith({
    int? id,
    int? userId,
    int? reminderId,
    String? medicineName,
    String? scheduledTime,
    DateTime? actualTime,
    String? status,
    DateTime? date,
  }) {
    return MedicineHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reminderId: reminderId ?? this.reminderId,
      medicineName: medicineName ?? this.medicineName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      actualTime: actualTime ?? this.actualTime,
      status: status ?? this.status,
      date: date ?? this.date,
    );
  }
}