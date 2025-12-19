import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../database/database_helper_firebase.dart';
import '../models/reminder.dart' as model;
import 'dart:convert';
import '../database/auth_service.dart';
import '../utils/avatar_presets.dart';
import '../utils/time_format_helper.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Home> {
  int _selectedIndex = 2;
  bool _isSelectionMode = false;
  DateTime _currentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  
  List<model.Reminder> _reminders = [];
  List<model.Reminder> _filteredReminders = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 2;
    _loadReminders();
    _loadUserAvatar();
  }

  Widget _buildAvatar() {
    if (_avatarUrl == null || _avatarUrl!.isEmpty) {
      return _buildDefaultAvatar();
    }

    // Check if it's a preset avatar
    if (_avatarUrl!.startsWith('preset_')) {
      return _buildPresetAvatar();
    }

    // Check if it's Base64 image
    if (_avatarUrl!.startsWith('data:image')) {
      return _buildBase64Avatar();
    }

    // Fallback: Custom uploaded image
    if (_avatarUrl!.startsWith('http')) {
      return _buildNetworkAvatar();
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 45,
      height: 45,
      decoration: const BoxDecoration(
        color: Color(0xFF5F9F7A),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildPresetAvatar() {
    try {
      final index = int.tryParse(_avatarUrl!.replaceFirst('preset_', ''));
      if (index != null && index >= 0 && index < AvatarPresets.presets.length) {
        return AvatarPresets.buildAvatar(
          index: index,
          size: 45,
          backgroundColor: const Color(0xFF5F9F7A),
        );
      }
    } catch (e) {
      print('Error building preset avatar: $e');
    }
    return _buildDefaultAvatar();
  }

  Widget _buildBase64Avatar() {
    try {
      if (_avatarUrl!.contains(',')) {
        final base64String = _avatarUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 45,
            height: 45,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error displaying base64 avatar: $error');
              return _buildDefaultAvatar();
            },
          ),
        );
      }
    } catch (e) {
      print('Error decoding base64 avatar: $e');
    }
    return _buildDefaultAvatar();
  }

  Widget _buildNetworkAvatar() {
    return ClipOval(
      child: Image.network(
        _avatarUrl!,
        width: 45,
        height: 45,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 45,
            height: 45,
            decoration: const BoxDecoration(
              color: Color(0xFF5F9F7A),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading network avatar: $error');
          return _buildDefaultAvatar();
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from AuthService
      final userId = await AuthService.instance.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }
      
      final reminders = await DatabaseHelper.instance.getReminders(userId);
      
      // Filter reminders for selected date
      final dayOfWeek = _selectedDate.weekday - 1; // 0 = Monday
      final filteredByDate = reminders.where((reminder) {
        return reminder.isActiveOnDay(dayOfWeek);
      }).toList();

      setState(() {
        _reminders = reminders;
        _filteredReminders = filteredByDate;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadUserAvatar() async {
    try {
      final userInfo = await AuthService.instance.getUserInfo();
      if (mounted && userInfo != null) {
        setState(() {
          _avatarUrl = userInfo['avatar_url'] as String?;
        });
      }
    } catch (e) {
      print('Error loading avatar: $e');
      if (mounted) {
        setState(() {
          _avatarUrl = null; // Reset về default nếu có lỗi
        });
      }
    }
  }

  void _filterRemindersByDate() {
    final dayOfWeek = _selectedDate.weekday - 1;
    setState(() {
      _filteredReminders = _reminders.where((reminder) {
        return reminder.isActiveOnDay(dayOfWeek);
      }).toList();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 4) {
      Navigator.pushNamed(context, '/settings').then((_) async {
        await _loadUserAvatar(); // Load avatar TRƯỚC
        if (mounted) {
          setState(() {
            _currentDate = DateTime.now();
            _selectedDate = DateTime.now();
            _selectedIndex = 2;
          });
          _loadReminders();
        }
      });
    } else if (index == 1) {
      Navigator.pushNamed(context, '/medicine_home').then((_) {
        setState(() {
          _currentDate = DateTime.now();
          _selectedDate = DateTime.now();
          _selectedIndex = 2;
        });
      });
    } else if (index == 3) {
      Navigator.pushNamed(context, '/progress').then((_) {
        setState(() {
          _currentDate = DateTime.now();
          _selectedDate = DateTime.now();
          _selectedIndex = 2;
        });
      });
    } else if (index == 2) {
      Navigator.pushNamed(
        context,
        '/add_reminder',
        arguments: _selectedDate, // Truyền ngày đã chọn
      ).then((_) {
        setState(() {
          _currentDate = DateTime.now();
          _selectedDate = DateTime.now();
          _selectedIndex = 2;
        });
        _loadReminders();
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        // Clear all selections
        for (var reminder in _filteredReminders) {
          // Note: You'll need to add isSelected to Reminder model
          // or track selections in a separate Set<int>
        }
      }
    });
  }

  void _previousWeek() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
      _selectedDate = _currentDate;
      _filterRemindersByDate();
    });
  }

  void _nextWeek() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 7));
      _selectedDate = _currentDate;
      _filterRemindersByDate();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _filterRemindersByDate();
    });
  }

  List<DateTime> _getWeekDays() {
    final monday = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'T2';
      case 2: return 'T3';
      case 3: return 'T4';
      case 4: return 'T5';
      case 5: return 'T6';
      case 6: return 'T7';
      case 7: return 'CN';
      default: return '';
    }
  }

  String _getMonthYear() {
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return '${months[_currentDate.month - 1]} ${_currentDate.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelectedDate(DateTime date) {
    return date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
  }

  void _showMonthCalendar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFD4EBD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF5F9F7A),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentDate = DateTime(
                            _currentDate.year,
                            _currentDate.month - 1,
                          );
                        });
                        _showMonthCalendar();
                      },
                    ),
                    Text(
                      _getMonthYear(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5F3F),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF5F9F7A),
                        size: 28,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _currentDate = DateTime(
                            _currentDate.year,
                            _currentDate.month + 1,
                          );
                        });
                        _showMonthCalendar();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                      .map(
                        (day) => SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F9F7A),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                ..._buildMonthGrid(),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentDate = DateTime.now();
                      _selectedDate = DateTime.now();
                      _filterRemindersByDate();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F9F7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildMonthGrid() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(
      _currentDate.year,
      _currentDate.month + 1,
      0,
    );
    final startingWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> weeks = [];
    List<Widget> days = [];

    for (int i = 1; i < startingWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 40));
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final isToday = _isToday(date);

      days.add(
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _currentDate = date;
              _selectedDate = date;
              _filterRemindersByDate();
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF2D5F3F) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              day.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isToday ? Colors.white : const Color(0xFF2D5F3F),
              ),
            ),
          ),
        ),
      );

      if (days.length == 7) {
        weeks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.from(days),
            ),
          ),
        );
        days.clear();
      }
    }

    if (days.isNotEmpty) {
      while (days.length < 7) {
        days.add(const SizedBox(width: 40, height: 40));
      }
      weeks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.from(days),
          ),
        ),
      );
    }

    return weeks;
  }

  void _showNotifications() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;

    List<Map<String, dynamic>> upcoming = [];
    List<Map<String, dynamic>> overdue = [];

    for (var reminder in _filteredReminders) {
      for (var time in reminder.times) {
        final timeParts = time.split(':');
        final reminderMinutes =
            int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]);
        final difference = reminderMinutes - currentTime;

        if (difference > 0 && difference <= 60) {
          upcoming.add({'name': reminder.medicineName, 'time': TimeFormatHelper.format24To12Hour(time)});
        } else if (difference < 0 && difference > -180) {
          overdue.add({'name': reminder.medicineName, 'time': TimeFormatHelper.format24To12Hour(time)});
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFFD4EBD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F3F),
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (upcoming.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF5F9F7A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sắp diễn ra',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5F9F7A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...upcoming.map(
                            (notif) => _buildNotificationItem(
                              notif['name']!,
                              notif['time']!,
                              const Color(0xFF5F9F7A),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],
                        if (overdue.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE57373),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Đã trễ',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE57373),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...overdue.map(
                            (notif) => _buildNotificationItem(
                              notif['name']!,
                              notif['time']!,
                              const Color(0xFFE57373),
                            ),
                          ),
                        ],
                        if (upcoming.isEmpty && overdue.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.notifications_off,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Không có thông báo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F9F7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Đóng',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem(String name, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSelected() async {
    // Track selected reminder IDs
    final selectedIds = <int>[];
    // You'll need to implement selection tracking
    
    if (selectedIds.isEmpty) {
      return;
    }

    try {
      await DatabaseHelper.instance.deleteMultipleReminders(selectedIds);
      setState(() {
        _isSelectionMode = false;
      });
      _loadReminders();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa nhắc nhở đã chọn'),
            backgroundColor: Color(0xFF5F9F7A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD4EBD4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Xóa nhắc nhở',
            style: TextStyle(
              color: Color(0xFF2D5F3F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bạn có chắc muốn xóa các nhắc nhở đã chọn?',
                style: TextStyle(color: Color(0xFF2D5F3F)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FB896),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Hủy'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteSelected();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D5F3F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text('Xóa'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleReminderEnabled(model.Reminder reminder) async {
    try {
      final updatedReminder = reminder.copyWith(
        isEnabled: !reminder.isEnabled,
      );
      
      await DatabaseHelper.instance.updateReminder(updatedReminder);
      _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editReminder(model.Reminder reminder) {
    Navigator.pushNamed(
      context,
      '/edit_reminder',
      arguments: reminder,
    ).then((_) {
      _loadReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/user_info');
                      // Load lại avatar ngay sau khi quay về
                      await _loadUserAvatar();
                      if (mounted) {
                        setState(() {
                          _currentDate = DateTime.now();
                          _selectedDate = DateTime.now();
                          _selectedIndex = 2;
                        });
                      }
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2D5F3F),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(child: _buildAvatar()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FB896),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '',
                          hintStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          suffixIcon: Icon(
                            Icons.search,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showNotifications,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5F3F),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8E6C9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Color(0xFF5F9F7A),
                            size: 28,
                          ),
                          onPressed: _previousWeek,
                        ),
                        GestureDetector(
                          onTap: _showMonthCalendar,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7FB896),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text(
                              _getMonthYear(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF5F9F7A),
                            size: 28,
                          ),
                          onPressed: _nextWeek,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _getWeekDays().map((date) {
                        return GestureDetector(
                          onTap: () => _onDateSelected(date),
                          child: _buildDayColumn(
                            _getWeekdayName(date.weekday),
                            date.day.toString(),
                            _isToday(date),
                            _isSelectedDate(date),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F9F7A),
                      ),
                    )
                  : _filteredReminders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(220, 280),
                                painter: CloverPainter(),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Không có nhắc nhở nào',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF2D5F3F),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReminders,
                          color: const Color(0xFF5F9F7A),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: _filteredReminders.length,
                            itemBuilder: (context, index) {
                              final reminder = _filteredReminders[index];
                              return GestureDetector(
                                onTap: () => _editReminder(reminder),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB8E6C9),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      CustomPaint(
                                        size: const Size(60, 60),
                                        painter: SmallCloverPainter(),
                                      ),
                                      const SizedBox(width: 15),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reminder.medicineName,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2D5F3F),
                                              ),
                                            ),
                                            Text(
                                              TimeFormatHelper.formatList24To12Hour(reminder.times).join(', '),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF2D5F3F),
                                              ),
                                            ),
                                            if (reminder.description != null &&
                                                reminder.description!.isNotEmpty)
                                              Text(
                                                reminder.description!,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      // Toggle enabled button (giữ riêng không phụ thuộc onTap của item)
                                      GestureDetector(
                                        onTap: () => _toggleReminderEnabled(reminder),
                                        child: Container(
                                          width: 60,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: reminder.isEnabled
                                                ? const Color(0xFF5F9F7A)
                                                : const Color(0xFF7FB896),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: AnimatedAlign(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            alignment: reminder.isEnabled
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              margin: const EdgeInsets.all(2),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _toggleSelectionMode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7FB896),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Hủy', style: TextStyle(fontSize: 18)),
                    ),
                    ElevatedButton(
                      onPressed: _showDeleteConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5F3F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text('Xóa', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFD4EBD4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.calendar_today, 0),
            _buildNavItem(Icons.video_library, 1),
            _buildCenterButton(),
            _buildNavItem(Icons.pie_chart, 3),
            _buildNavItem(Icons.settings, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildDayColumn(String day, String date, bool isToday, bool isSelected) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isToday ? Colors.white : const Color(0xFF5F9F7A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isToday
                ? const Color(0xFF2D5F3F)
                : isSelected
                    ? const Color(0xFF5F9F7A)
                    : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            date,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: (isToday || isSelected)
                  ? Colors.white
                  : const Color(0xFF2D5F3F),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        _onItemTapped(index);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F9F7A) : const Color(0xFFD4EBD4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF2D5F3F),
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    final isSelected = _selectedIndex == 2;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/add_reminder',
          arguments: _selectedDate, // Truyền ngày đã chọn
        ).then((_) {
          setState(() {
            _currentDate = DateTime.now();
            _selectedDate = DateTime.now();
            _selectedIndex = 2;
          });
          _loadReminders();
        });
      },
      child: Container(
        width: 65,
        height: 65,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2D5F3F) : const Color(0xFF5F9F7A),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 36),
      ),
    );
  }
}

class CloverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF8BC34A);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2D5F3F)
      ..strokeWidth = 3;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final leafRadius = 55.0;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final leafX = centerX + math.cos(angle) * 40;
      final leafY = centerY + math.sin(angle) * 40;

      final path = Path();
      path.moveTo(centerX, centerY);
      path.quadraticBezierTo(
        leafX + math.cos(angle + math.pi / 2) * leafRadius,
        leafY + math.sin(angle + math.pi / 2) * leafRadius,
        leafX + math.cos(angle) * leafRadius,
        leafY + math.sin(angle) * leafRadius,
      );
      path.quadraticBezierTo(
        leafX + math.cos(angle - math.pi / 2) * leafRadius,
        leafY + math.sin(angle - math.pi / 2) * leafRadius,
        centerX,
        centerY,
      );

      canvas.drawPath(path, paint);
      canvas.drawPath(path, outlinePaint);
    }

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF689F38)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY + 10),
      Offset(centerX, size.height - 20),
      stemPaint,
    );

    final stemOutline = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2D5F3F)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY + 10),
      Offset(centerX, size.height - 20),
      stemOutline,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 10),
      Offset(centerX, size.height - 20),
      stemPaint,
    );

    canvas.drawLine(
      Offset(centerX - 20, centerY - 5),
      Offset(centerX - 20, centerY + 5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2D5F3F)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(centerX + 20, centerY - 5),
      Offset(centerX + 20, centerY + 5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2D5F3F)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final smilePath = Path();
    smilePath.moveTo(centerX - 15, centerY + 15);
    smilePath.quadraticBezierTo(
      centerX,
      centerY + 25,
      centerX + 15,
      centerY + 15,
    );
    canvas.drawPath(
      smilePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2D5F3F)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final blushPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.8);

    canvas.drawCircle(Offset(centerX - 45, centerY + 5), 12, blushPaint);
    canvas.drawCircle(Offset(centerX + 45, centerY + 5), 12, blushPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SmallCloverPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF8BC34A);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2D5F3F)
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2 - 5;
    final leafRadius = 15.0;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final leafX = centerX + math.cos(angle) * 12;
      final leafY = centerY + math.sin(angle) * 12;

      final path = Path();
      path.moveTo(centerX, centerY);
      path.quadraticBezierTo(
        leafX + math.cos(angle + math.pi / 2) * leafRadius,
        leafY + math.sin(angle + math.pi / 2) * leafRadius,
        leafX + math.cos(angle) * leafRadius,
        leafY + math.sin(angle) * leafRadius,
      );
      path.quadraticBezierTo(
        leafX + math.cos(angle - math.pi / 2) * leafRadius,
        leafY + math.sin(angle - math.pi / 2) * leafRadius,
        centerX,
        centerY,
      );

      canvas.drawPath(path, paint);
      canvas.drawPath(path, outlinePaint);
    }

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF689F38)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY + 5),
      Offset(centerX, size.height - 5),
      stemPaint,
    );

    canvas.drawLine(
      Offset(centerX - 8, centerY - 2),
      Offset(centerX - 8, centerY + 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2D5F3F)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawLine(
      Offset(centerX + 8, centerY - 2),
      Offset(centerX + 8, centerY + 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2D5F3F)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    final smilePath = Path();
    smilePath.moveTo(centerX - 6, centerY + 6);
    smilePath.quadraticBezierTo(
      centerX,
      centerY + 10,
      centerX + 6,
      centerY + 6,
    );
    canvas.drawPath(
      smilePath,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF2D5F3F)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    final blushPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withOpacity(0.8);

    canvas.drawCircle(Offset(centerX - 15, centerY + 2), 5, blushPaint);
    canvas.drawCircle(Offset(centerX + 15, centerY + 2), 5, blushPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}