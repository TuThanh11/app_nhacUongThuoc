import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/api_service.dart';
import '../utils/time_format_helper.dart';

class Progress extends StatefulWidget {
  const Progress({super.key});

  @override
  State<Progress> createState() => _ProgressState();
}

class _ProgressState extends State<Progress> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  List<dynamic> _history = [];
  String _selectedPeriod = '7days'; // '7days', '30days', 'all'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await ApiService.instance.getUserId();
      if (userId == null) throw Exception('Chưa đăng nhập');

      // Tính toán khoảng thời gian
      String? startDate;
      String? endDate = DateTime.now().toIso8601String();

      if (_selectedPeriod == '7days') {
        startDate = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
      } else if (_selectedPeriod == '30days') {
        startDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
      }

      // Load statistics và history
      final stats = await ApiService.instance.getMedicineStats(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      final history = await ApiService.instance.getMedicineHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _stats = stats['success'] ? stats['stats'] : null;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Load data error: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPeriodLabel() {
    switch (_selectedPeriod) {
      case '7days':
        return '7 ngày qua';
      case '30days':
        return '30 ngày qua';
      case 'all':
        return 'Tất cả';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'taken':
        return const Color(0xFF5F9F7A);
      case 'rejected':
        return const Color(0xFFE57373);
      case 'missed':
        return const Color(0xFFFFB74D);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'taken':
        return 'Đã uống';
      case 'rejected':
        return 'Bỏ qua';
      case 'missed':
        return 'Bỏ lỡ';
      default:
        return status;
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
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

            // Period selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFB8E6C9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  children: [
                    _buildPeriodButton('7days', '7 ngày'),
                    _buildPeriodButton('30days', '30 ngày'),
                    _buildPeriodButton('all', 'Tất cả'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5F9F7A),
                      ),
                    )
                  : _stats == null || _stats!['total'] == 0
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.analytics_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Chưa có dữ liệu',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xFF5F9F7A),
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              children: [
                                // Statistics Summary Card
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB8E6C9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Tỷ lệ tuân thủ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: const Color(0xFF2D5F3F).withOpacity(0.8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          '${_stats!['adherenceRate'].toStringAsFixed(0)}%',
                                          style: const TextStyle(
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2D5F3F),
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildStatItem(
                                              'Tổng số',
                                              '${_stats!['total']}',
                                              const Color(0xFF5F9F7A),
                                            ),
                                            _buildStatItem(
                                              'Đã uống',
                                              '${_stats!['taken']}',
                                              const Color(0xFF5F9F7A),
                                            ),
                                            _buildStatItem(
                                              'Bỏ qua',
                                              '${_stats!['rejected']}',
                                              const Color(0xFFE57373),
                                            ),
                                            _buildStatItem(
                                              'Bỏ lỡ',
                                              '${_stats!['missed']}',
                                              const Color(0xFFFFB74D),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                // Pie Chart
                                if (_stats!['total'] > 0) ...[
                                  SizedBox(
                                    height: 220,
                                    child: CustomPaint(
                                      size: const Size(220, 220),
                                      painter: PieChartPainter(
                                        taken: _stats!['taken'],
                                        rejected: _stats!['rejected'],
                                        missed: _stats!['missed'],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Legend
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: Column(
                                      children: [
                                        _buildLegendItem('Đã uống', const Color(0xFF5F9F7A)),
                                        const SizedBox(height: 10),
                                        _buildLegendItem('Bỏ qua', const Color(0xFFE57373)),
                                        const SizedBox(height: 10),
                                        _buildLegendItem('Bỏ lỡ', const Color(0xFFFFB74D)),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 30),
                                ],

                                // History title
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 30),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Lịch sử',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2D5F3F),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        '(${_history.length} lần)',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 15),

                                // History list
                                if (_history.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(40),
                                    child: Text(
                                      'Chưa có lịch sử',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _history.length,
                                    itemBuilder: (context, index) {
                                      final record = _history[index];
                                      final status = record['status'] as String;
                                      final color = _getStatusColor(status);

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(15),
                                          border: Border.all(
                                            color: color.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                status == 'taken'
                                                    ? Icons.check_circle
                                                    : status == 'rejected'
                                                        ? Icons.cancel
                                                        : Icons.access_time,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                            const SizedBox(width: 15),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    record['medicine_name'] ?? 'Thuốc',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF2D5F3F),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '${_formatDate(record['timestamp'])} • ${TimeFormatHelper.format24To12Hour(record['scheduled_time'])}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getStatusLabel(status),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String value, String label) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedPeriod != value) {
            setState(() {
              _selectedPeriod = value;
            });
            _loadData();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF5F9F7A) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF2D5F3F),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
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
            borderRadius: BorderRadius.circular(8),
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
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D5F3F),
          ),
        ),
      ],
    );
  }
}

class PieChartPainter extends CustomPainter {
  final int taken;
  final int rejected;
  final int missed;

  PieChartPainter({
    required this.taken,
    required this.rejected,
    required this.missed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final total = taken + rejected + missed;

    if (total == 0) return;

    // Data segments
    final List<Map<String, dynamic>> segments = [
      {
        'value': taken,
        'color': const Color(0xFF5F9F7A),
        'percent': taken / total,
      },
      {
        'value': rejected,
        'color': const Color(0xFFE57373),
        'percent': rejected / total,
      },
      {
        'value': missed,
        'color': const Color(0xFFFFB74D),
        'percent': missed / total,
      },
    ];

    double startAngle = -math.pi / 2;

    // Draw segments
    for (var segment in segments) {
      if (segment['value'] == 0) continue;

      final sweepAngle = 2 * math.pi * segment['percent'];

      // Draw filled arc
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

      // Draw border between segments
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFD4EBD4)
        ..strokeWidth = 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      // Draw percentage text
      if (segment['percent'] > 0.05) {
        final midAngle = startAngle + sweepAngle / 2;
        final textX = center.dx + (radius * 0.65) * math.cos(midAngle);
        final textY = center.dy + (radius * 0.65) * math.sin(midAngle);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${(segment['percent'] * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(1, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            textX - textPainter.width / 2,
            textY - textPainter.height / 2,
          ),
        );
      }

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}