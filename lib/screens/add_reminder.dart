import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../database/database_helper_firebase.dart';
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

  Widget _buildRepeatOption(String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (text == 'Tùy chỉnh') {
          Navigator.pop(context);
          _showCustomRepeatDialog();
        } else {
          setState(() {
            _repeatMode = text;
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

  void _navigateToSelectTime() {
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

    // Navigate to select time with reminder data
    Navigator.pushNamed(
      context,
      '/select_time',
      arguments: {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'isRepeatEnabled': _isRepeatEnabled,
        'repeatMode': _repeatMode,
        'selectedDays': _selectedDays,
      },
    );
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
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Icon(Icons.calendar_today, size: 28),
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