// lib/models/medicine.dart

class Medicine {
  final int? id;
  final int userId;
  final String name;
  final String? description;
  final String? usage;
  final DateTime startDate;
  final DateTime expiryDate;
  final DateTime createdAt;

  Medicine({
    this.id,
    required this.userId,
    required this.name,
    this.description,
    this.usage,
    required this.startDate,
    required this.expiryDate,
    required this.createdAt,
  });

  // Chuyển từ Map sang Medicine object
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      usage: map['usage'] as String?,
      startDate: DateTime.parse(map['start_date'] as String),
      expiryDate: DateTime.parse(map['expiry_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  // Chuyển từ Medicine object sang Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'usage': usage,
      'start_date': startDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copy with - để update dữ liệu
  Medicine copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? usage,
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? createdAt,
  }) {
    return Medicine(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      usage: usage ?? this.usage,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}