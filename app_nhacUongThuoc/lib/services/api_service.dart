import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    } else {
      return 'http://10.0.2.2:3000/api';
    }
  }

  String? _userId;
  Map<String, dynamic>? _userInfo;

  // Thêm timeout cho tất cả request
  static const Duration timeoutDuration = Duration(seconds: 10);

  // Lưu userId
  Future<void> setUserId(String userId) async {
    _userId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    print('✅ User ID saved: $userId');
  }

  // Lấy userId
  Future<String?> getUserId() async {
    try {
      if (_userId != null) {
        print('User ID from memory: $_userId');
        return _userId;
      }
      
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      print('User ID from SharedPreferences: $_userId');
      return _userId;
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Xóa userId
  Future<void> clearUserId() async {
    _userId = null;
    _userInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_info');
    print('✅ User data cleared');
  }

  // Helper method để tạo headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // Helper để xử lý response
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    try {
      final data = json.decode(response.body);
      
      if (response.statusCode >= 400) {
        return {
          'success': false,
          'message': data['message'] ?? 'Đã xảy ra lỗi',
        };
      }
      
      return data;
    } catch (e) {
      print('Parse error: $e');
      return {
        'success': false,
        'message': 'Lỗi xử lý dữ liệu: $e',
      };
    }
  }

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> signup({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      print('=== SIGNUP REQUEST ===');
      print('URL: $baseUrl/auth/signup');
      
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/signup'),
            headers: _getHeaders(),
            body: json.encode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeoutDuration); // Thêm timeout

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng kiểm tra:\n'
            '1. Server có đang chạy không?\n'
            '2. Địa chỉ $baseUrl có đúng không?',
      };
    } catch (e) {
      print('Signup error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('=== LOGIN REQUEST ===');
      print('URL: $baseUrl/auth/login');
      print('Email: $email');

      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: _getHeaders(),
            body: json.encode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(timeoutDuration); // Thêm timeout

      final data = _handleResponse(response);
      
      if (data['success'] && data['user'] != null) {
        final uid = data['user']['uid'] as String;
        await setUserId(uid);
        
        print('=== LOGIN SUCCESS ===');
        print('Saved UID: $uid');
        
        _userInfo = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_info', json.encode(data['user']));
      }

      return data;
    } on http.ClientException catch (e) {
      print('Network error: $e');
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng kiểm tra:\n'
            '1. Server có đang chạy không? (npm start)\n'
            '2. Địa chỉ $baseUrl có đúng không?',
      };
    } catch (e) {
      print('Login error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  // Lấy thông tin user
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      if (_userInfo != null) {
        return _userInfo;
      }

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('user_info');
      if (cached != null) {
        _userInfo = json.decode(cached);
        return _userInfo;
      }

      final userId = await getUserId();
      if (userId == null) {
        return null;
      }

      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/user/$userId'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success'] && data['user'] != null) {
        _userInfo = data['user'];
        await prefs.setString('user_info', json.encode(data['user']));
        return _userInfo;
      }

      return null;
    } catch (e) {
      print('GetUserInfo error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> updateAvatar(String avatarUrl) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/auth/avatar/$userId'),
            headers: _getHeaders(),
            body: json.encode({'avatarUrl': avatarUrl}),
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response);
      
      if (data['success'] && _userInfo != null) {
        _userInfo!['avatar_url'] = avatarUrl;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_info', json.encode(_userInfo));
      }

      return data;
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> changePassword(String newPassword) async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return {'success': false, 'message': 'Chưa đăng nhập'};
      }

      final response = await http
          .put(
            Uri.parse('$baseUrl/auth/password/$userId'),
            headers: _getHeaders(),
            body: json.encode({'newPassword': newPassword}),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // ==================== MEDICINES ====================

  Future<List<dynamic>> getMedicines(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/medicines/$userId'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success']) {
        return data['medicines'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get medicines error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createMedicine({
    required String userId,
    required String name,
    String? description,
    String? usage,
    required String startDate,
    required String expiryDate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/medicines'),
            headers: _getHeaders(),
            body: json.encode({
              'userId': userId,
              'name': name,
              'description': description,
              'usage': usage,
              'startDate': startDate,
              'expiryDate': expiryDate,
            }),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> updateMedicine({
    required String userId,
    required String id,
    required String name,
    String? description,
    String? usage,
    required String startDate,
    required String expiryDate,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/medicines/$id'),
            headers: _getHeaders(),
            body: json.encode({
              'userId': userId,
              'name': name,
              'description': description,
              'usage': usage,
              'startDate': startDate,
              'expiryDate': expiryDate,
            }),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMedicine(String userId, String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/medicines/$id?userId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ==================== REMINDERS ====================

  Future<List<dynamic>> getReminders(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/reminders/$userId'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success']) {
        return data['reminders'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get reminders error: $e');
      return [];
    }
  }

  Future<List<dynamic>> getTodayReminders(String userId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/reminders/$userId/today'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success']) {
        return data['reminders'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get today reminders error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createReminder({
    required String userId,
    required String medicineName,
    String? description,
    required bool isRepeatEnabled,
    required String repeatMode,
    required List<int> customDays,
    required List<String> times,
    required bool isEnabled,
    String? selectedDate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/reminders'),
            headers: _getHeaders(),
            body: json.encode({
              'userId': userId,
              'medicineName': medicineName,
              'description': description,
              'isRepeatEnabled': isRepeatEnabled,
              'repeatMode': repeatMode,
              'customDays': customDays,
              'times': times,
              'isEnabled': isEnabled,
              'selectedDate': selectedDate,
            }),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> updateReminder({
    required String userId,
    required String id,
    required String medicineName,
    String? description,
    required bool isRepeatEnabled,
    required String repeatMode,
    required List<int> customDays,
    required List<String> times,
    bool? isEnabled,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/reminders/$id'),
            headers: _getHeaders(),
            body: json.encode({
              'userId': userId,
              'medicineName': medicineName,
              'description': description,
              'isRepeatEnabled': isRepeatEnabled,
              'repeatMode': repeatMode,
              'customDays': customDays,
              'times': times,
              'isEnabled': isEnabled,
            }),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteReminder(String userId, String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/reminders/$id?userId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> toggleReminder(String userId, String id) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/reminders/$id/toggle'),
            headers: _getHeaders(),
            body: json.encode({'userId': userId}),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // ==================== MEDICINE HISTORY ====================

  Future<List<dynamic>> getMedicineHistory({
    required String userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      var url = '$baseUrl/history/$userId';
      
      // Thêm query parameters nếu có
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      final data = _handleResponse(response);
      if (data['success']) {
        return data['history'] ?? [];
      }
      return [];
    } catch (e) {
      print('Get medicine history error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> logMedicineHistory({
    required String userId,
    String? reminderId,
    required String medicineName,
    required String time,
    required String status, // 'taken', 'rejected', 'missed'
    String? timestamp,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/history'),
            headers: _getHeaders(),
            body: json.encode({
              'userId': userId,
              'reminderId': reminderId,
              'medicineName': medicineName,
              'time': time,
              'status': status,
              'timestamp': timestamp ?? DateTime.now().toIso8601String(),
            }),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> getMedicineStats({
    required String userId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      var url = '$baseUrl/history/$userId/stats';
      
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
      }

      final response = await http
          .get(
            Uri.parse(url),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteMedicineHistory(
    String userId, 
    String id
  ) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl/history/$id?userId=$userId'),
            headers: _getHeaders(),
          )
          .timeout(timeoutDuration);

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }
}