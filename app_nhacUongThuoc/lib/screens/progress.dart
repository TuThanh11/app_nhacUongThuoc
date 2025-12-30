import 'package:flutter/material.dart';
import 'dart:math' as math;

class Progress extends StatefulWidget {
  const Progress({super.key});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  final List<Map<String, dynamic>> _records = [
    {
      'date': '15/11/2024',
      'time': '8:00',
      'status': 'completed', // Hoàn thành
      'color': const Color(0xFF5F9F7A),
    },
    {
      'date': '15/11/2024',
      'time': '8:00',
      'status': 'missed', // Không làm
      'color': const Color(0xFFE57373),
    },
    {
      'date': '15/11/2024',
      'time': '8:00',
      'status': 'late', // Trễ
      'color': const Color(0xFFCDDC39),
    },
  ];

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
                        'Tiến độ uống thuốc',
                        style: TextStyle(
                          fontSize: 22,
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

            // Pie Chart
            SizedBox(
              height: 200,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: PieChartPainter(),
              ),
            ),

            const SizedBox(height: 20),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _buildLegendItem('Hoàn thành', const Color(0xFF2D5F3F)),
                  const SizedBox(height: 10),
                  _buildLegendItem('Không làm', const Color(0xFFE57373)),
                  const SizedBox(height: 10),
                  _buildLegendItem('Trễ', const Color(0xFFCDDC39)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Records list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                itemCount: _records.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _records[index]['color'],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _records[index]['date'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _records[index]['time'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D5F3F),
          ),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Data: 50% completed, 25% missed, 25% late
    final List<Map<String, dynamic>> data = [
      {'percent': 0.5, 'color': const Color(0xFF5F9F7A)}, // Hoàn thành
      {'percent': 0.25, 'color': const Color(0xFFE57373)}, // Không làm
      {'percent': 0.25, 'color': const Color(0xFFCDDC39)}, // Trễ
    ];

    double startAngle = -math.pi / 2;

    for (var segment in data) {
      final sweepAngle = 2 * math.pi * segment['percent'];

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = segment['color'];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw white border between segments
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFD4EBD4)
        ..strokeWidth = 4;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw outer circle border
    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF2D5F3F)
      ..strokeWidth = 3;

    canvas.drawCircle(center, radius, outerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
