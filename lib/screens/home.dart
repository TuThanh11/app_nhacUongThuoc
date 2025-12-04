import 'package:flutter/material.dart';
import 'dart:math' as math;

class Reminder {
  final String time;
  final String medicineName;
  bool isEnabled;
  bool isSelected;

  Reminder({
    required this.time,
    required this.medicineName,
    this.isEnabled = true,
    this.isSelected = false,
  });
}

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

  List<Reminder> _reminders = [
    Reminder(time: '8:00', medicineName: 'Vitamin C'),
    Reminder(time: '18:00', medicineName: 'Paracetamol'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 2; // Set default to center button
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to different screens
    if (index == 4) {
      Navigator.pushNamed(context, '/settings').then((_) {
        // Reset to current week when coming back
        setState(() {
          _currentDate = DateTime.now();
          _selectedIndex = 2;
        });
      });
    } else if (index == 1) {
      Navigator.pushNamed(context, '/medicine_home').then((_) {
        setState(() {
          _currentDate = DateTime.now();
          _selectedIndex = 2;
        });
      });
    } else if (index == 3) {
      Navigator.pushNamed(context, '/progress').then((_) {
        setState(() {
          _currentDate = DateTime.now();
          _selectedIndex = 2;
        });
      });
    } else if (index == 2) {
      Navigator.pushNamed(context, '/add_reminder').then((_) {
        setState(() {
          _currentDate = DateTime.now();
          _selectedIndex = 2;
        });
      });
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        for (var reminder in _reminders) {
          reminder.isSelected = false;
        }
      }
    });
  }

  void _previousWeek() {
    setState(() {
      _currentDate = _currentDate.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentDate = _currentDate.add(const Duration(days: 7));
    });
  }

  List<DateTime> _getWeekDays() {
    // Get Monday of current week
    final monday = _currentDate.subtract(
      Duration(days: _currentDate.weekday - 1),
    );
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }

  String _getMonthYear() {
    final months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return '${months[_currentDate.month - 1]} ${_currentDate.year}';
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
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
                // Month/Year header
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
                // Weekday headers
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
                // Calendar grid
                ..._buildMonthGrid(),
                const SizedBox(height: 15),
                // Close button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _currentDate = DateTime.now();
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
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday
    final daysInMonth = lastDayOfMonth.day;

    List<Widget> weeks = [];
    List<Widget> days = [];

    // Add empty cells for days before month starts
    for (int i = 1; i < startingWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 40));
    }

    // Add days of month
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final isToday = _isToday(date);

      days.add(
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
            setState(() {
              _currentDate = date;
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

      // Create new row after 7 days
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

    // Add remaining days
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

    // Sample notifications
    List<Map<String, dynamic>> upcoming = [];
    List<Map<String, dynamic>> overdue = [];

    // Check reminders for upcoming (within 1 hour) and overdue
    for (var reminder in _reminders) {
      final timeParts = reminder.time.split(':');
      final reminderMinutes =
          int.parse(timeParts[0]) * 60 + int.parse(timeParts[1]);
      final difference = reminderMinutes - currentTime;

      if (difference > 0 && difference <= 60) {
        // Upcoming (within 1 hour)
        upcoming.add({'name': reminder.medicineName, 'time': reminder.time});
      } else if (difference < 0 && difference > -180) {
        // Overdue (within last 3 hours)
        overdue.add({'name': reminder.medicineName, 'time': reminder.time});
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
                // Header
                const Text(
                  'Thông báo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F3F),
                  ),
                ),
                const SizedBox(height: 20),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Upcoming notifications
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

                        // Overdue notifications
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

                        // Empty state
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

                // Close button
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

  void _deleteSelected() {
    setState(() {
      _reminders.removeWhere((reminder) => reminder.isSelected);
      _isSelectionMode = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Profile icon - navigate to User Info
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/user_info').then((_) {
                        setState(() {
                          _currentDate = DateTime.now();
                          _selectedIndex = 2;
                        });
                      });
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
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF2D5F3F),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Search bar
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
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: '',
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

                  // Notification icon - show notifications popup
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

            // Calendar widget
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
                    // Month/Year with navigation arrows
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
                    // Week days row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _getWeekDays().map((date) {
                        return _buildDayColumn(
                          _getWeekdayName(date.weekday),
                          date.day.toString(),
                          _isToday(date),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _reminders.isEmpty
                  ? Center(
                      child: CustomPaint(
                        size: const Size(220, 280),
                        painter: CloverPainter(),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: _reminders.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _toggleSelectionMode();
                              setState(() {
                                _reminders[index].isSelected = true;
                              });
                            }
                          },
                          onTap: () {
                            if (_isSelectionMode) {
                              setState(() {
                                _reminders[index].isSelected =
                                    !_reminders[index].isSelected;
                              });
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: _reminders[index].isSelected
                                  ? const Color(0xFF7FB896)
                                  : const Color(0xFFB8E6C9),
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
                                if (_isSelectionMode)
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 15),
                                    decoration: BoxDecoration(
                                      color: _reminders[index].isSelected
                                          ? const Color(0xFF2D5F3F)
                                          : Colors.white,
                                      border: Border.all(
                                        color: const Color(0xFF2D5F3F),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: _reminders[index].isSelected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 18,
                                          )
                                        : null,
                                  ),
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
                                        _reminders[index].time,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D5F3F),
                                        ),
                                      ),
                                      Text(
                                        _reminders[index].medicineName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF2D5F3F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!_isSelectionMode)
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _reminders[index].isEnabled =
                                            !_reminders[index].isEnabled;
                                      });
                                    },
                                    child: Container(
                                      width: 60,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _reminders[index].isEnabled
                                            ? const Color(0xFF5F9F7A)
                                            : const Color(0xFF7FB896),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: AnimatedAlign(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        alignment: _reminders[index].isEnabled
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

  Widget _buildDayColumn(String day, String date, bool isToday) {
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
            color: isToday ? const Color(0xFF2D5F3F) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            date,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isToday ? Colors.white : const Color(0xFF2D5F3F),
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
        Navigator.pushNamed(context, '/add_reminder').then((_) {
          setState(() {
            _currentDate = DateTime.now();
            _selectedIndex = 2;
          });
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

    final facePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2D5F3F);

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
