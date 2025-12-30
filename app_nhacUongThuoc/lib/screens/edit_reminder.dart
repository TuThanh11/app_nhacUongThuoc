import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import '../models/reminder.dart';

class EditReminder extends StatefulWidget {
  const EditReminder({super.key});

  @override
  State<EditReminder> createState() => _EditReminderScreenState();
}

class _EditReminderScreenState extends State<EditReminder> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isRepeatEnabled = false;
  String _repeatMode = 'Một lần';
  List<bool> _selectedDays = List.filled(7, false);
  bool _isLoading = false;
  Reminder? _reminder;
  List<String> _times = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Reminder?;
    if (args != null && _reminder == null) {
      _reminder = args;
      _nameController.text = args.medicineName;
      _descriptionController.text = args.description ?? '';
      _isRepeatEnabled = args.isRepeatEnabled;
      _repeatMode = args.repeatMode;
      _times = List<String>.from(args.times);
      
      // Set selected days based on customDays
      for (int i = 0; i < 7; i++) {
        _selectedDays[i] = args.customDays.contains(i);
      }
      print('✅ Loaded reminder with ${_times.length} times');
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
    // Tạo một bản sao của selectedDays để sử dụng trong dialog
    final dialogSelectedDays = List<bool>.from(_selectedDays);
    
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
                          _buildDayOptionInDialog('Thứ Hai', 0, dialogSelectedDays, setDialogState),
                          _buildDayOptionInDialog('Thứ Ba', 1, dialogSelectedDays, setDialogState),
                          _buildDayOptionInDialog('Thứ Tư', 2, dialogSelectedDays, setDialogState),
                          _buildDayOptionInDialog('Thứ Năm', 3, dialogSelectedDays, setDialogState),
                          _buildDayOptionInDialog('Thứ Sáu', 4, dialogSelectedDays, setDialogState),
                          _buildDayOptionInDialog('Thứ Bảy', 5, dialogSelectedDays, setDialogState),
                          _buildDayOptionInDialog('Chủ Nhật', 6, dialogSelectedDays, setDialogState),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _repeatMode = 'Tùy chỉnh';
                          _selectedDays = dialogSelectedDays;
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

  Widget _buildDayOptionInDialog(String day, int index, List<bool> selectedDays, StateSetter setDialogState) {
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
                selectedDays[index] = !selectedDays[index];
              });
            },
            child: Container(
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: selectedDays[index]
                    ? Colors.white
                    : const Color(0xFF5F9F7A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: selectedDays[index]
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selectedDays[index]
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

  Widget _buildRepeatOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (text == 'Tùy chỉnh') {
          Navigator.pop(context);
          _showCustomRepeatDialog();
        } else {
          setState(() {
            _repeatMode = text;
            // Nếu chọn "Một lần" thì tắt lặp lại
            if (text == 'Một lần') {
              _isRepeatEnabled = false;
            } else {
              _isRepeatEnabled = true;
            }
          });
          Navigator.pop(context);
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

  String _getRepeatModeDisplayText() {
    if (!_isRepeatEnabled) {
      return 'Không lặp lại';
    }
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

    if (_reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin nhắc nhở'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('Before navigate: $_times');

    // ✅ Navigate và CHỜ kết quả trả về
    final result = await Navigator.pushNamed(
      context,
      '/select_time',
      arguments: {
        'isEditMode': true,
        'existingTimes': _times, // Truyền danh sách thời gian hiện tại
      },
    );

    print('Result from select_time: $result');

    // ✅ Cập nhật _times nếu có kết quả trả về
    if (result != null && result is List<String>) {
      setState(() {
        _times = result;
      });
      print('✅ Times updated: $_times');
    } else {
      print('❌ No result returned'); // ✅ THÊM
    }
  }

  Future<void> _updateReminder() async {
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

    if (_reminder == null || _reminder!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin nhắc nhở'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Lấy Firebase UID (không phải numeric_user_id)
      final userId = await ApiService.instance.getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      print('=== UPDATE REMINDER DEBUG ===');
      print('Using Firebase UID: $userId');
      print('Reminder ID: ${_reminder!.id}');

      // Get custom days list
      List<int> customDays = [];
      if (_isRepeatEnabled && _repeatMode == 'Tùy chỉnh') {
        for (int i = 0; i < _selectedDays.length; i++) {
          if (_selectedDays[i]) {
            customDays.add(i);
          }
        }
      }

      // ✅ Gọi API với Firebase UID
      final result = await ApiService.instance.updateReminder(
        userId: userId, // ✅ Truyền Firebase UID
        id: _reminder!.id!, // ✅ ID đã là String, không cần .toString()
        medicineName: _nameController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        isRepeatEnabled: _isRepeatEnabled && _repeatMode != 'Một lần',
        repeatMode: _repeatMode,
        customDays: customDays,
        times: _times,
        isEnabled: _reminder!.isEnabled, // Giữ nguyên trạng thái enabled
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật nhắc nhở "${_nameController.text}"!'),
            backgroundColor: const Color(0xFF5F9F7A),
          ),
        );

        // Navigate back to home
        Navigator.of(context).pop(true); // Trả về true để báo đã update thành công
      } else {
        throw Exception(result['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      if (!mounted) return;

      print('Update error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi cập nhật: $e'),
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

  void _showDeleteConfirmation() {
    if (_reminder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy thông tin nhắc nhở'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
              Text(
                'Bạn có chắc muốn xóa nhắc nhở "${_reminder!.medicineName}"?',
                style: const TextStyle(color: Color(0xFF2D5F3F)),
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
                      _deleteReminder();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
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

  Future<void> _deleteReminder() async {
    if (_reminder == null || _reminder!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi: Không tìm thấy ID của nhắc nhở'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ Lấy Firebase UID (không phải numeric_user_id)
      final userId = await ApiService.instance.getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      print('=== DELETE REMINDER DEBUG ===');
      print('Using Firebase UID: $userId');
      print('Reminder ID: ${_reminder!.id}');

      // ✅ Gọi API với Firebase UID
      final result = await ApiService.instance.deleteReminder(
        userId, // ✅ Truyền Firebase UID
        _reminder!.id!, // ✅ ID đã là String, không cần .toString()
      );

      if (!mounted) return;

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa nhắc nhở "${_reminder!.medicineName}"'),
            backgroundColor: const Color(0xFF5F9F7A),
          ),
        );

        // Navigate back to home
        Navigator.of(context).pop(true); // Trả về true để báo đã xóa thành công
      } else {
        throw Exception(result['message'] ?? 'Xóa thất bại');
      }
    } catch (e) {
      if (!mounted) return;

      print('Delete error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa: $e'),
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
                        'Sửa nhắc nhở',
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

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Tên thuốc
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

                    // Mô tả
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

                    // Lặp lại toggle
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
                                // Khi tắt lặp lại, set về "Một lần"
                                _repeatMode = 'Một lần';
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

                    const SizedBox(height: 30),

                    // Calendar button
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
                              const Icon(Icons.calendar_today, size: 24),
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

                    // Update button
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
                          onPressed: _isLoading ? null : _updateReminder,
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
                                      'Cập nhật',
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

                    // Delete button
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
                          onPressed: _isLoading ? null : _showDeleteConfirmation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Xóa nhắc nhở',
                                style: TextStyle(
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