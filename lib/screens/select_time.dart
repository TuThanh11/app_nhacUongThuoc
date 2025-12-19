import 'package:flutter/material.dart';
import '../database/database_helper_firebase.dart';
import '../models/reminder.dart';
import '../database/auth_service.dart';
import '../utils/time_format_helper.dart';

class SelectTime extends StatefulWidget {
  const SelectTime({super.key});

  @override
  State<SelectTime> createState() => _SelectTimeScreenState();
}

class _SelectTimeScreenState extends State<SelectTime> {
  List<String> _times = ['08:00', '12:00', '18:00'];
  Map<String, dynamic>? _reminderData;
  bool _isLoading = false;
  bool _isEditMode = false;
  int? _reminderId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _reminderData = args;
      _isEditMode = args['isEditMode'] == true;
      _reminderId = args['reminderId'] as int?;
      
      // If edit mode, load existing times
      if (_isEditMode && args['existingTimes'] != null) {
        _times = List<String>.from(args['existingTimes']);
      }
    }
  }

  void _removeTime(int index) {
    if (_times.length > 1) {
      setState(() {
        _times.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phải có ít nhất 1 thời gian'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _addNewTime() {
    setState(() {
      _times.add('09:00');
    });
  }

  void _showTimePicker(int index) {
    // Parse thời gian hiện tại (24h format)
    int hour24 = int.parse(_times[index].split(':')[0]);
    int selectedMinute = int.parse(_times[index].split(':')[1]);
    
    // Xác định AM/PM
    bool isPM = hour24 >= 12;
    
    // Chuyển sang giờ 0-11 cho wheel picker
    int selectedHour = hour24 % 12; // 0-11

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF7FB896),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 450,
                child: Column(
                  children: [
                    const Text(
                      'Chọn giờ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Display current selected time in AM/PM format
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9F7A),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _formatDisplayTime(selectedHour, selectedMinute, isPM),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Time wheel selector - CHỈ 0-11 GIỜ
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hour selector (00-11)
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: FixedExtentScrollController(
                                initialItem: selectedHour,
                              ),
                              itemExtent: 60,
                              perspective: 0.003,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              magnification: 1.2,
                              useMagnifier: true,
                              onSelectedItemChanged: (value) {
                                setDialogState(() {
                                  selectedHour = value; // 0-11
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 12, // 0-11
                                builder: (context, index) {
                                  final isSelected = index == selectedHour;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: isSelected ? 32 : 24,
                                        color: isSelected 
                                            ? Colors.white 
                                            : Colors.white.withOpacity(0.5),
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              ':',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Minute selector
                          Expanded(
                            child: ListWheelScrollView.useDelegate(
                              controller: FixedExtentScrollController(
                                initialItem: selectedMinute,
                              ),
                              itemExtent: 60,
                              perspective: 0.003,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              magnification: 1.2,
                              useMagnifier: true,
                              onSelectedItemChanged: (value) {
                                setDialogState(() {
                                  selectedMinute = value;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  final isSelected = index == selectedMinute;
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        fontSize: isSelected ? 32 : 24,
                                        color: isSelected 
                                            ? Colors.white 
                                            : Colors.white.withOpacity(0.5),
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // AM/PM toggle buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  isPM = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isPM 
                                    ? const Color(0xFF2D5F3F) 
                                    : Colors.white,
                                foregroundColor: !isPM 
                                    ? Colors.white 
                                    : const Color(0xFF2D5F3F),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'AM',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                setDialogState(() {
                                  isPM = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isPM 
                                    ? const Color(0xFF2D5F3F) 
                                    : Colors.white,
                                foregroundColor: isPM 
                                    ? Colors.white 
                                    : const Color(0xFF2D5F3F),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                'PM',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Chuyển đổi về 24h format để lưu
                          int hour24;
                          if (isPM) {
                            // PM: 00 -> 12, 01 -> 13, ..., 11 -> 23
                            hour24 = (selectedHour == 0) ? 12 : selectedHour + 12;
                          } else {
                            // AM: 00 -> 00, 01 -> 01, ..., 11 -> 11
                            hour24 = selectedHour;
                          }
                          
                          setState(() {
                            _times[index] = '${hour24.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5F9F7A),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper function để format thời gian hiển thị
  String _formatDisplayTime(int hour, int minute, bool isPM) {
    // hour là 0-11
    int displayHour = hour;
    if (displayHour == 0) {
      displayHour = 12; // 00 -> 12 (cả AM và PM)
    }
    
    String period = isPM ? 'PM' : 'AM';
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _createReminder() async {
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 thời gian'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID from AuthService
      final userId = await AuthService.instance.getUserId();
      if (userId == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Always return the times list (both edit and create mode)
      if (!mounted) return;
      Navigator.of(context).pop(_times);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5F9F7A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Chọn giờ',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F3F),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Time list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                itemCount: _times.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showTimePicker(index),
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5F9F7A),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  TimeFormatHelper.format24To12Hour(_times[index]),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => _removeTime(index),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF5F9F7A),
                                width: 3,
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
                              Icons.close,
                              color: Color(0xFF5F9F7A),
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Add time button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _addNewTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7FB896),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 28),
                      SizedBox(width: 10),
                      Text(
                        'Thêm thời gian',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Create button
            Container(
              width: double.infinity,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF5F9F7A),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: _isLoading ? null : _createReminder,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Xong',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}