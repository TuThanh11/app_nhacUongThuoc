import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import '../models/reminder.dart';


class AddReminder extends StatefulWidget {
  const AddReminder({super.key});

  @override
  State<AddReminder> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminder> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRepeatEnabled = false;
  String _repeatMode = 'Một lần';
  List<bool> _selectedDays = List.filled(7, false);
  bool _isLoading = false;
  List<String> _times = [];
  DateTime? _selectedDate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as DateTime?;
    if (args != null && _selectedDate == null) {
      setState(() {
        _selectedDate = args;
        _repeatMode = 'Một lần';
        _isRepeatEnabled = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showRepeatOptionsDialog() {
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
                const Text(
                  'Lặp lại',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F3F),
                  ),
                ),
                const SizedBox(height: 20),
                _buildRepeatOption('Một lần', _repeatMode == 'Một lần'),
                const SizedBox(height: 10),
                _buildRepeatOption('Hằng ngày', _repeatMode == 'Hằng ngày'),
                const SizedBox(height: 10),
                _buildRepeatOption(
                  'Từ thứ 2 đến thứ 6',
                  _repeatMode == 'Từ thứ 2 đến thứ 6',
                ),
                const SizedBox(height: 10),
                _buildRepeatOption('Tùy chỉnh', _repeatMode == 'Tùy chỉnh'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5F9F7A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Tiếp tục',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomRepeatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    const Text(
                      'Lặp lại',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5F3F),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FB896),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _buildDayOption('Thứ Hai', 0, setDialogState),
                          _buildDayOption('Thứ Ba', 1, setDialogState),
                          _buildDayOption('Thứ Tư', 2, setDialogState),
                          _buildDayOption('Thứ Năm', 3, setDialogState),
                          _buildDayOption('Thứ Sáu', 4, setDialogState),
                          _buildDayOption('Thứ Bảy', 5, setDialogState),
                          _buildDayOption('Chủ Nhật', 6, setDialogState),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _repeatMode = 'Tùy chỉnh';
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5F9F7A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Tiếp tục',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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

  Widget _buildDayOption(String day, int index, StateSetter setDialogState) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {
              setDialogState(() {
                _selectedDays[index] = !_selectedDays[index];
              });
              setState(() {});
            },
            child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: _selectedDays[index]
                    ? Colors.white
                    : const Color(0xFF5F9F7A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: _selectedDays[index]
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: _selectedDays[index]
                        ? const Color(0xFF5F9F7A)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRepeatModeDisplayText() {
    if (_repeatMode == 'Tùy chỉnh' && _selectedDays.isNotEmpty) {
      final dayNames = ['Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
      final selectedDayNames = <String>[];
      for (int i = 0; i < _selectedDays.length; i++) {
        if (_selectedDays[i]) {
          selectedDayNames.add(dayNames[i]);
        }
      }
      if (selectedDayNames.isNotEmpty) {
        return selectedDayNames.join(', ');
      }
    }
    return _repeatMode;
  }

  String _formatDate(DateTime date) {
    final months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildRepeatOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (text == 'Tùy chỉnh') {
          Navigator.pop(context);
          _showCustomRepeatDialog();
        } else {
          setState(() {
            _repeatMode = text;
            if (text == 'Một lần') {
              _isRepeatEnabled = false;
              // ✅ Tự động mở date picker khi chọn "Một lần"
              Navigator.pop(context);
              _showDatePicker();
            } else {
              _isRepeatEnabled = true;
              Navigator.pop(context);
            }
          });
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5F9F7A) : const Color(0xFF7FB896),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (isSelected)
              const Icon(Icons.check, color: Colors.white, size: 24),
            if (isSelected) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToSelectTime() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên thuốc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_repeatMode == 'Một lần' && _selectedDate == null) {
      _showDatePicker();
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      '/select_time',
      arguments: {
        'isEditMode': false,
        'existingTimes': _times.isEmpty ? ['08:00', '12:00', '18:00'] : _times,
      },
    );

    if (result != null && result is List<String>) {
      setState(() {
        _times = result;
      });
    }
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5F9F7A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF2D5F3F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createReminder() async {
    // Validate form
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên thuốc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 thời gian'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ VALIDATE: Kiểm tra ngày cho "Một lần"
    if (_repeatMode == 'Một lần' && _selectedDate == null) {
      // Tự động hiển thị date picker
      await _showDatePicker();
      
      // Kiểm tra lại sau khi picker đóng
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ngày cho nhắc nhở "Một lần"'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // ✅ VALIDATE: Nếu chọn "Tùy chỉnh" mà chưa chọn ngày nào
    if (_repeatMode == 'Tùy chỉnh') {
      final hasSelectedDay = _selectedDays.any((selected) => selected);
      if (!hasSelectedDay) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ít nhất 1 ngày cho chế độ "Tùy chỉnh"'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Lấy Firebase UID từ ApiService
      final userId = await ApiService.instance.getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      print('=== CREATE REMINDER DEBUG ===');
      print('Using Firebase UID: $userId');
      print('repeatMode: $_repeatMode');
      print('selectedDate: $_selectedDate');

      // ✅ Get custom days list - LUÔN TẠO LIST HỢP LỆ
      List<int> customDays = [];
      
      if (_repeatMode == 'Tùy chỉnh') {
        // Chỉ thêm các ngày đã chọn
        for (int i = 0; i < _selectedDays.length; i++) {
          if (_selectedDays[i]) {
            customDays.add(i);
          }
        }
      } else if (_repeatMode == 'Một lần') {
        // ✅ Với "Một lần", LUÔN dùng selectedDate nếu có
        if (_selectedDate != null) {
          final dayOfWeek = _selectedDate!.weekday == 7 ? 6 : _selectedDate!.weekday - 1; // 0-6, CN=6
          customDays = [dayOfWeek];
        } else {
          // Fallback: dùng ngày hiện tại
          final today = DateTime.now();
          final dayOfWeek = today.weekday == 7 ? 6 : today.weekday - 1;
          customDays = [dayOfWeek];
        }
      } else if (_repeatMode == 'Hằng ngày') {
        // Hằng ngày: tất cả các ngày
        customDays = [0, 1, 2, 3, 4, 5, 6];
      } else if (_repeatMode == 'Từ thứ 2 đến thứ 6') {
        // T2-T6
        customDays = [0, 1, 2, 3, 4];
      }

      print('customDays: $customDays');

      // ✅ Gọi API để tạo reminder
      final result = await ApiService.instance.createReminder(
        userId: userId, // Truyền Firebase UID
        medicineName: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        isRepeatEnabled: _isRepeatEnabled && _repeatMode != 'Một lần',
        repeatMode: _repeatMode,
        customDays: customDays,
        times: _times,
        isEnabled: true,
        selectedDate: _repeatMode == 'Một lần' ? _selectedDate?.toIso8601String() : null,
      );

      if (!mounted) return;

      // ✅ Kiểm tra kết quả
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo nhắc nhở "${_nameController.text}"!'),
            backgroundColor: const Color(0xFF5F9F7A),
          ),
        );
        Navigator.of(context).pop(true); // ✅ Trả về true để Home reload
      } else {
        throw Exception(result['message'] ?? 'Tạo nhắc nhở thất bại');
      }
    } catch (e) {
      print('Create reminder error: $e');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tạo nhắc nhở: $e'),
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
                        'Thêm nhắc nhở',
                        style: TextStyle(
                          fontSize: 24,
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    const Text(
                      'Tên thuốc',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF2D5F3F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(controller: _nameController),

                    const SizedBox(height: 20),

                    const Text(
                      'Mô tả',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF2D5F3F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(controller: _descriptionController),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Lặp lại',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF2D5F3F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isRepeatEnabled = !_isRepeatEnabled;
                              if (_isRepeatEnabled) {
                                _showRepeatOptionsDialog();
                              } else {
                                _repeatMode = 'Một lần';
                                _selectedDate = null;
                              }
                            });
                          },
                          child: Container(
                            width: 60,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _isRepeatEnabled
                                  ? const Color(0xFF5F9F7A)
                                  : const Color(0xFF7FB896),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _isRepeatEnabled
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
                    // Hiển thị và cho phép sửa chế độ lặp lại
                  if (_isRepeatEnabled) ...[
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _showRepeatOptionsDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7FB896),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _getRepeatModeDisplayText(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ✅ Hiển thị ngày đã chọn cho "Một lần"
                  if (_repeatMode == 'Một lần' && _selectedDate != null) ...[
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _showDatePicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F9F7A),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatDate(_selectedDate!),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                    const SizedBox(height: 30),

                    Center(
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
                          onPressed: _isLoading ? null : _navigateToSelectTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5F9F7A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.access_time, size: 24),
                              const SizedBox(width: 10),
                              Text(
                                _times.isEmpty 
                                    ? 'Chọn thời gian' 
                                    : '${_times.length} thời gian đã chọn',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Center(
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
                          onPressed: _isLoading ? null : _createReminder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5F3F),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check, size: 24),
                                    SizedBox(width: 10),
                                    Text(
                                      'Lưu',
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
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}