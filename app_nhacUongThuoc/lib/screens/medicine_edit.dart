import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../services/api_service.dart';
import '../models/medicine.dart';

class MedicineEdit extends StatefulWidget {
  const MedicineEdit({super.key});

  @override
  State<MedicineEdit> createState() => _MedicineEditState();
}

class _MedicineEditState extends State<MedicineEdit> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _usageController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));
  
  Medicine? _medicine;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Chỉ load dữ liệu một lần
    if (!_isInitialized) {
      final medicine = ModalRoute.of(context)?.settings.arguments as Medicine?;
      
      if (medicine != null) {
        _medicine = medicine;
        _nameController.text = medicine.name;
        _descController.text = medicine.description ?? '';
        _usageController.text = medicine.usage ?? '';
        _startDate = medicine.startDate;
        _expiryDate = medicine.expiryDate;
      }
      
      _isInitialized = true;
    }
  }

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

  Future<void> _saveChanges() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập tên thuốc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_medicine == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy thông tin thuốc'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check expiry date
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
      // ✅ Lấy Firebase UID từ ApiService
      final userId = await ApiService.instance.getUserId();
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      if (_medicine!.id == null) {
        throw Exception('Không tìm thấy ID thuốc');
      }

      print('=== UPDATE MEDICINE DEBUG ===');
      print('Using Firebase UID: $userId');
      print('Medicine ID: ${_medicine!.id}');

      // ✅ Gọi API để update medicine
      final result = await ApiService.instance.updateMedicine(
        userId: userId,
        id: _medicine!.id.toString(),
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

      if (!mounted) return;

      // ✅ Kiểm tra kết quả
      if (result['success']) {
        // Show success and go back
        Navigator.pop(context, true); // Return true to indicate success
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu thay đổi!'),
            backgroundColor: Color(0xFF5F9F7A),
          ),
        );
      } else {
        throw Exception(result['message'] ?? 'Cập nhật thất bại');
      }
    } catch (e) {
      print('Update medicine error: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
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

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa thuốc này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true && _medicine?.id != null) {
      try {
        // ✅ Lấy Firebase UID
        final userId = await ApiService.instance.getUserId();
        if (userId == null) {
          throw Exception('Chưa đăng nhập');
        }

        print('=== DELETE MEDICINE DEBUG ===');
        print('Using Firebase UID: $userId');
        print('Medicine ID: ${_medicine!.id}');

        // ✅ Gọi API để delete medicine
        final result = await ApiService.instance.deleteMedicine(
          userId,
          _medicine!.id.toString(),
        );
        
        if (!mounted) return;

        // ✅ Kiểm tra kết quả
        if (result['success']) {
          Navigator.pop(context, true);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa thuốc'),
              backgroundColor: Color(0xFF5F9F7A),
            ),
          );
        } else {
          throw Exception(result['message'] ?? 'Xóa thất bại');
        }
      } catch (e) {
        print('Delete medicine error: $e');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
                        'Chỉnh sửa thuốc',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F3F),
                        ),
                      ),
                    ),
                  ),
                  // Delete button
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
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
                        Icons.delete,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _confirmDelete,
                    ),
                  ),
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

            // Save button
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
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Lưu thay đổi',
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