import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/medicine.dart';

class MedicineHome extends StatefulWidget {
  const MedicineHome({super.key});

  @override
  State<MedicineHome> createState() => _MedicineHomeState();
}

class _MedicineHomeState extends State<MedicineHome> {
  final _searchController = TextEditingController();
  List<Medicine> _medicines = [];
  List<Medicine> _filteredMedicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Lấy Firebase UID từ ApiService
      final userId = await ApiService.instance.getUserId();
      
      if (userId == null) {
        throw Exception('Chưa đăng nhập');
      }

      print('=== LOAD MEDICINES DEBUG ===');
      print('Using Firebase UID: $userId');

      // Gọi API để lấy medicines
      final medicinesData = await ApiService.instance.getMedicines(userId);
      
      print('Loaded ${medicinesData.length} medicines');

      // Convert từ dynamic sang Medicine objects
      final medicines = medicinesData.map((data) {
        return Medicine.fromMap(data);
      }).toList();
      
      if (mounted) {
        setState(() {
          _medicines = medicines;
          _filteredMedicines = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Load medicines error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _searchMedicine(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = _medicines;
      } else {
        _filteredMedicines = _medicines
            .where(
              (medicine) =>
                  medicine.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
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
                        'Thông tin thuốc',
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

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 50,
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
                  onChanged: _searchMedicine,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tìm kiếm thuốc...',
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

            const SizedBox(height: 20),

            // Medicine list
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F9F7A),
                      ),
                    )
                  : _filteredMedicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'Chưa có thuốc nào'
                                    : 'Không tìm thấy thuốc',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMedicines,
                          color: const Color(0xFF5F9F7A),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _filteredMedicines.length,
                            itemBuilder: (context, index) {
                              final medicine = _filteredMedicines[index];
                              final DateTime expiryDate = DateTime.tryParse(medicine.expiryDate.toString()) ?? DateTime.now();
                              final bool isExpiringSoon = medicine.expiryDate.difference(DateTime.now()).inDays <= 7;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 15),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () async {
                                          // Chờ kết quả từ màn hình info
                                          final result = await Navigator.pushNamed(
                                            context,
                                            '/medicine_info',
                                            arguments: medicine,
                                          );
                                          
                                          // Reload nếu có thay đổi
                                          if (result == true) {
                                            _loadMedicines();
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isExpiringSoon ? Colors.orange.shade700 : const Color(0xFF5F9F7A),
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 6,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: ListTile(
                                            title: Text(
                                              medicine.name,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold, 
                                                color: Colors.white
                                              ),
                                            ),
                                            subtitle: Text(
                                              isExpiringSoon 
                                                ? "Hết hạn vào: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}" 
                                                : (medicine.description ?? ""),
                                              style: const TextStyle(color: Colors.white70),
                                            ),
                                            trailing: isExpiringSoon 
                                              ? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30) 
                                              : null,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    GestureDetector(
                                      onTap: () async {
                                        // Chờ kết quả trả về từ màn hình edit
                                        final result = await Navigator.pushNamed(
                                          context,
                                          '/medicine_edit',
                                          arguments: medicine,
                                        );
                                        
                                        // Nếu edit hoặc xóa thành công, reload danh sách
                                        if (result == true) {
                                          _loadMedicines();
                                        }
                                      },
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
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Color(0xFF5F9F7A),
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),

            // Bottom decoration
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Opacity(
                opacity: 0.3,
                child: Icon(
                  Icons.local_florist,
                  size: 100,
                  color: Colors.green.shade300,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add_medicine');
          if (result == true) {
            _loadMedicines(); // Refresh list after adding
          }
        },
        backgroundColor: const Color(0xFF5F9F7A),
        child: const Icon(
          Icons.medical_services,
          color: Colors.white,
          size: 28,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}