import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medicine.dart';
import '../models/reminder.dart';
import '../models/medicine_history.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DatabaseHelper._init();

  // Collections
  CollectionReference get _medicinesCollection => _db.collection('medicines');
  CollectionReference get _remindersCollection => _db.collection('reminders');
  CollectionReference get _historyCollection => _db.collection('medicine_history');

  // ==================== MEDICINES ====================
  
  Future<int> createMedicine(Medicine medicine) async {
    final docRef = await _medicinesCollection.add(medicine.toMap());
    return docRef.id.hashCode; // Convert string ID to int
  }

  Future<List<Medicine>> getMedicines(int userId) async {
    final querySnapshot = await _medicinesCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('name')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id.hashCode;
      return Medicine.fromMap(data);
    }).toList();
  }

  Future<Medicine?> getMedicineById(int id) async {
    // Tìm document có hashCode khớp
    final querySnapshot = await _medicinesCollection.get();
    
    for (var doc in querySnapshot.docs) {
      if (doc.id.hashCode == id) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = id;
        return Medicine.fromMap(data);
      }
    }
    return null;
  }

  Future<int> updateMedicine(Medicine medicine) async {
    // Tìm document theo hashCode
    final querySnapshot = await _medicinesCollection.get();
    
    for (var doc in querySnapshot.docs) {
      if (doc.id.hashCode == medicine.id) {
        await doc.reference.update(medicine.toMap());
        return medicine.id!;
      }
    }
    return 0;
  }

  Future<int> deleteMedicine(int id) async {
    final querySnapshot = await _medicinesCollection.get();
    
    for (var doc in querySnapshot.docs) {
      if (doc.id.hashCode == id) {
        await doc.reference.delete();
        return 1;
      }
    }
    return 0;
  }

  Future<List<Medicine>> searchMedicines(int userId, String query) async {
    final medicines = await getMedicines(userId);
    return medicines
        .where((m) => m.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ==================== REMINDERS ====================
  
  Future<int> createReminder(Reminder reminder) async {
    final docRef = await _remindersCollection.add(reminder.toMap());
    return docRef.id.hashCode;
  }

  Future<List<Reminder>> getReminders(int userId) async {
    final querySnapshot = await _remindersCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id.hashCode;
      return Reminder.fromMap(data);
    }).toList();
  }

  Future<List<Reminder>> getTodayReminders(int userId) async {
    final allReminders = await getReminders(userId);
    final today = DateTime.now();
    final dayOfWeek = today.weekday - 1;
    
    return allReminders.where((reminder) {
      if (!reminder.isEnabled) return false;
      return reminder.isActiveOnDay(dayOfWeek);
    }).toList();
  }

  Future<int> updateReminder(Reminder reminder) async {
    final querySnapshot = await _remindersCollection.get();
    
    for (var doc in querySnapshot.docs) {
      if (doc.id.hashCode == reminder.id) {
        await doc.reference.update(reminder.toMap());
        return reminder.id!;
      }
    }
    return 0;
  }

  Future<int> deleteReminder(int id) async {
    final querySnapshot = await _remindersCollection.get();
    
    for (var doc in querySnapshot.docs) {
      if (doc.id.hashCode == id) {
        await doc.reference.delete();
        return 1;
      }
    }
    return 0;
  }

  Future<int> deleteMultipleReminders(List<int> ids) async {
    final querySnapshot = await _remindersCollection.get();
    int count = 0;
    
    for (var doc in querySnapshot.docs) {
      if (ids.contains(doc.id.hashCode)) {
        await doc.reference.delete();
        count++;
      }
    }
    return count;
  }

  // ==================== HISTORY ====================
  
  Future<int> createHistory(MedicineHistory history) async {
    final docRef = await _historyCollection.add(history.toMap());
    return docRef.id.hashCode;
  }

  Future<List<MedicineHistory>> getHistory(int userId, {int? limit}) async {
    Query query = _historyCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .orderBy('scheduled_time', descending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    final querySnapshot = await query.get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id.hashCode;
      return MedicineHistory.fromMap(data);
    }).toList();
  }

  Future<Map<String, int>> getHistoryStats(int userId) async {
    final completedQuery = await _historyCollection
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'completed')
        .get();
    
    final missedQuery = await _historyCollection
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'missed')
        .get();
    
    final lateQuery = await _historyCollection
        .where('user_id', isEqualTo: userId)
        .where('status', isEqualTo: 'late')
        .get();

    return {
      'completed': completedQuery.docs.length,
      'missed': missedQuery.docs.length,
      'late': lateQuery.docs.length,
    };
  }

  Future<List<MedicineHistory>> getHistoryByDate(int userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    final querySnapshot = await _historyCollection
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
        .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
        .orderBy('date')
        .orderBy('scheduled_time')
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id.hashCode;
      return MedicineHistory.fromMap(data);
    }).toList();
  }

  // ==================== UTILITY ====================
  
  Future close() async {
    // Firestore không cần close
  }

  Future deleteDatabase() async {
    // Xóa tất cả documents trong collections
    final batch = _db.batch();
    
    final medicinesSnapshot = await _medicinesCollection.get();
    for (var doc in medicinesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    final remindersSnapshot = await _remindersCollection.get();
    for (var doc in remindersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    final historySnapshot = await _historyCollection.get();
    for (var doc in historySnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }
  
  // Stream realtime updates (bonus feature!)
  Stream<List<Reminder>> streamReminders(int userId) {
    return _remindersCollection
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id.hashCode;
        return Reminder.fromMap(data);
      }).toList();
    });
  }
}