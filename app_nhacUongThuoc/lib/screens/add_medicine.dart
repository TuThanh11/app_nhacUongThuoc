import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/medicine.dart';

class AddMedicine extends StatefulWidget {
  const AddMedicine({super.key});

  @override
  State<AddMedicine> createState() => _AddMedicineState();
}

class _AddMedicineState extends State<AddMedicine> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _usageController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _usageController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
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
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
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
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _createMedicine() async {
    // Validate tên thuốc
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên thuốc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate ngày hết hạn
    if (_expiryDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hạn sử dụng phải sau ngày bắt đầu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy Firebase UID từ ApiService
      final userId = await ApiService.instance.getUserId();
      
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      print('=== CREATE MEDICINE DEBUG ===');
      print('Using Firebase UID: $userId');

      // Gọi API để tạo medicine
      final result = await ApiService.instance.createMedicine(
        userId: userId,
        name: _nameController.text.trim(),
        description: _descController.text.trim().isEmpty 
            ? null 
            : _descController.text.trim(),
        usage: _usageController.text.trim().isEmpty 
            ? null 
            : _usageController.text.trim(),
        startDate: _startDate.toIso8601String(),
        expiryDate: _expiryDate.toIso8601String(),
      );
      
      print('Medicine creation result: ${result['success']}');

      if (!mounted) return;

      // Kiểm tra kết quả
      if (result['success']) {
        // ✅ Schedule expiry notifications
        if (result['medicine'] != null) {
          try {
            final medicine = Medicine.fromMap(result['medicine']);
            await NotificationService().scheduleMedicineExpiryNotification(medicine);
            print('✅ Scheduled expiry notifications for new medicine');
          } catch (e) {
            print('Error scheduling expiry notifications: $e');
          }
        }
        
        // Trả về true để báo hiệu thêm thành công
        Navigator.pop(context, true);
        
        // Thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã thêm thuốc "${_nameController.text}"!'),
            backgroundColor: const Color(0xFF5F9F7A),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Tạo thuốc thất bại');
      }
    } catch (e) {
      print('Create medicine error: $e');
      
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
                        'Thêm thuốc',
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

            const SizedBox(height: 30),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tên thuốc
                    const Text(
                      'Tên thuốc',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F9F7A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _nameController,
                      hintText: 'Nhập tên thuốc',
                    ),

                    const SizedBox(height: 25),

                    // Mô tả
                    const Text(
                      'Mô Tả',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F9F7A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _descController,
                      hintText: 'Nhập mô tả',
                    ),

                    const SizedBox(height: 25),

                    // Công dụng
                    const Text(
                      'Công dụng',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5F9F7A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _usageController,
                      hintText: 'Nhập công dụng',
                    ),

                    const SizedBox(height: 25),

                    // Ngày bắt đầu
                    GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F9F7A),
                          borderRadius: BorderRadius.circular(20),
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
                            const Text(
                              'Ngày bắt đầu : ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_startDate.day.toString().padLeft(2, '0')}/${_startDate.month.toString().padLeft(2, '0')}/${_startDate.year}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // HSD
                    GestureDetector(
                      onTap: () => _selectExpiryDate(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5F9F7A),
                          borderRadius: BorderRadius.circular(20),
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
                            const Text(
                              'HSD : ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_expiryDate.day.toString().padLeft(2, '0')}/${_expiryDate.month.toString().padLeft(2, '0')}/${_expiryDate.year}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
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
                onPressed: _isLoading ? null : _createMedicine,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Tạo',
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