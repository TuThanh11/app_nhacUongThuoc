import 'package:flutter/material.dart';

class MedicineHome extends StatefulWidget {
  const MedicineHome({super.key});

  @override
  State<MedicineHome> createState() => _MedicineHomeState();
}

class _MedicineHomeState extends State<MedicineHome> {
  final _searchController = TextEditingController();
  List<Map<String, String>> _medicines = [
    {'name': 'Paracetamol', 'desc': 'Giảm đau, hạ sốt'},
    {'name': 'Vitamin C', 'desc': 'Tăng cường sức đề kháng'},
    {'name': 'Amoxicillin', 'desc': 'Kháng sinh'},
  ];

  List<Map<String, String>> _filteredMedicines = [];

  @override
  void initState() {
    super.initState();
    _filteredMedicines = _medicines;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchMedicine(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMedicines = _medicines;
      } else {
        _filteredMedicines = _medicines
            .where(
              (medicine) =>
                  medicine['name']!.toLowerCase().contains(query.toLowerCase()),
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

            const SizedBox(height: 20),

            // Medicine list
            Expanded(
              child: _filteredMedicines.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy thuốc',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFF5F9F7A),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _filteredMedicines.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/medicine_info',
                                      arguments: _filteredMedicines[index],
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
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
                                    child: Text(
                                      _filteredMedicines[index]['name']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/medicine_edit',
                                    arguments: {
                                      'index': index,
                                      'medicine': _filteredMedicines[index],
                                    },
                                  );
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
                                        color: Colors.black.withOpacity(0.1),
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

            // Bottom decoration
            Padding(
              padding: const EdgeInsets.only(bottom: 20),

              child: Opacity(
                opacity: 0.3,
                child: Image.asset(
                  'assets/images/Them_Thuoc.png',
                  width: 241.55,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_medicine');
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
