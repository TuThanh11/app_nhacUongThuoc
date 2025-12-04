import 'package:flutter/material.dart';

class SelectTime extends StatefulWidget {
  const SelectTime({super.key});

  @override
  State<SelectTime> createState() => _SelectTimeScreenState();
}

class _SelectTimeScreenState extends State<SelectTime> {
  List<String> _times = ['8:00', '12:00', '18:00'];
  Map<String, dynamic>? _reminderData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get reminder data from previous screen
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _reminderData = args;
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
      _times.add('9:00');
    });
  }

  void _showTimePicker(int index) {
    int selectedHour = int.parse(_times[index].split(':')[0]);
    int selectedMinute = int.parse(_times[index].split(':')[1]);

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
                height: 300,
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
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Hour selector
                          SizedBox(
                            width: 60,
                            child: ListWheelScrollView.useDelegate(
                              controller: FixedExtentScrollController(
                                initialItem: selectedHour,
                              ),
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (value) {
                                setDialogState(() {
                                  selectedHour = value;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 24,
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const Text(
                            ' : ',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          // Minute selector
                          SizedBox(
                            width: 60,
                            child: ListWheelScrollView.useDelegate(
                              controller: FixedExtentScrollController(
                                initialItem: selectedMinute,
                              ),
                              itemExtent: 40,
                              diameterRatio: 1.5,
                              physics: const FixedExtentScrollPhysics(),
                              onSelectedItemChanged: (value) {
                                setDialogState(() {
                                  selectedMinute = value;
                                });
                              },
                              childDelegate: ListWheelChildBuilderDelegate(
                                childCount: 60,
                                builder: (context, index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            // Set to morning time (8:00)
                            setState(() {
                              _times[index] = '08:00';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Sáng',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Set to afternoon time (14:00)
                            setState(() {
                              _times[index] = '14:00';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Chiều',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      // Update time when dialog closes
      setState(() {
        _times[index] =
            '${selectedHour.toString().padLeft(2, '0')}:${selectedMinute.toString().padLeft(2, '0')}';
      });
    });
  }

  void _createReminder() {
    // Validate
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thêm ít nhất 1 thời gian'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create reminder and go back to home
    Navigator.popUntil(context, ModalRoute.withName('/home'));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã tạo nhắc nhở "${_reminderData?['name'] ?? 'thuốc'}" với ${_times.length} thời gian!',
        ),
        backgroundColor: const Color(0xFF5F9F7A),
      ),
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
                                  _times[index],
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
                onPressed: _createReminder,
                child: const Text(
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
