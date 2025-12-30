import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import '../services/notification_service.dart';
import '../services/api_service.dart';
import '../services/alarm_manager_service.dart';
import 'dart:async';

class MedicineCallScreen extends StatefulWidget {
  final String reminderId;
  final String medicineName;
  final String time;
  final String? description;

  const MedicineCallScreen({
    super.key,
    required this.reminderId,
    required this.medicineName,
    required this.time,
    this.description,
  });

  @override
  State<MedicineCallScreen> createState() => _MedicineCallScreenState();
}

class _MedicineCallScreenState extends State<MedicineCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  bool _isProcessing = false;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // ✅ Tự động snooze sau 30 giây
    _autoCloseTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_isProcessing) {
        _onSnooze();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  Future<void> _onSnooze() async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⏰ Sẽ nhắc lại sau 5 phút'),
            backgroundColor: Color(0xFF5F9F7A),
            duration: Duration(seconds: 2),
          ),
        );
        
        AlarmManagerService().scheduleSnooze(
          reminderId: widget.reminderId,
          medicineName: widget.medicineName,
          time: widget.time,
          description: widget.description,
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error in snooze: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _onReject() async {
    if (_isProcessing) return;
  
    _autoCloseTimer?.cancel();
    AlarmManagerService().clearSnooze(widget.reminderId); 
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Cancel notification cho reminder này
      await NotificationService().cancelDisplayedNotifications(widget.reminderId);
      
      // Ghi nhận vào lịch sử 
      await _logMedicineHistory('rejected');
      
      if (mounted) {
        // Hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã hủy nhắc nhở'),
            backgroundColor: Color(0xFFE57373),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Đóng màn hình
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error in reject: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _onAccept() async {
    if (_isProcessing) return;

    _autoCloseTimer?.cancel();
    AlarmManagerService().clearSnooze(widget.reminderId);
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Cancel notification cho reminder này
      await NotificationService().cancelDisplayedNotifications(widget.reminderId);
      
      // Ghi nhận đã uống thuốc vào lịch sử
      await _logMedicineHistory('taken');
      
      if (mounted) {
        // Hiển thị thông báo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã ghi nhận uống thuốc'),
            backgroundColor: Color(0xFF5F9F7A),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Đóng màn hình
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Error in accept: $e');
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  // Hàm ghi nhận lịch sử uống thuốc
  Future<void> _logMedicineHistory(String status) async {
    try {
      final userId = await ApiService.instance.getUserId();
      if (userId == null) return;

      // Gọi API để ghi nhận lịch sử
      await ApiService.instance.logMedicineHistory(
        userId: userId,
        reminderId: widget.reminderId,
        medicineName: widget.medicineName,
        time: widget.time,
        status: status, // 'taken' or 'rejected'
        timestamp: DateTime.now().toIso8601String(),
      );
      
      print('Medicine history logged: $status');
    } catch (e) {
      print('Error logging medicine history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !_isProcessing, // Chặn back nếu đang xử lý
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/OIP1.png', 
                  fit: BoxFit.cover,
                ),
              ),

              ..._buildFloatingClovers(),

              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    Column(
                      children: [
                        Text(
                          'HOT Reminder',
                          style: GoogleFonts.pacifico(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D5F3F),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Healthy On Time',
                          style: GoogleFonts.lobster(
                            fontSize: 14,
                            color: Color(0xFF5F9F7A),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // ✅ Hiển thị thời gian
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9F7A).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.time,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F3F),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          Text(
                            widget.medicineName,
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5F3F),
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Sức khỏe của bạn quan trọng lắm ❤️',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              color: const Color(0xFF2D5F3F).withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ✅ Action buttons với loading state
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 85),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Reject button
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                                child: GestureDetector(
                                  onTap: _isProcessing ? null : _onReject,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: _isProcessing 
                                          ? Colors.grey 
                                          : const Color(0xFFE57373),
                                      shape: BoxShape.circle,
                                      boxShadow: _isProcessing ? [] : [
                                        BoxShadow(
                                          color: const Color(0xFFE57373).withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: _isProcessing
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Accept button
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isProcessing ? 1.0 : _pulseAnimation.value,
                                child: GestureDetector(
                                  onTap: _isProcessing ? null : _onAccept,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: _isProcessing 
                                          ? Colors.grey 
                                          : const Color(0xFF5F9F7A),
                                      shape: BoxShape.circle,
                                      boxShadow: _isProcessing ? [] : [
                                        BoxShadow(
                                          color: const Color(0xFF5F9F7A).withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: _isProcessing
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.medication,
                                            color: Colors.white,
                                            size: 35,
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFloatingClovers() {
    final random = math.Random(42);
    List<Widget> clovers = [];

    for (int i = 0; i < 15; i++) {
      final left = random.nextDouble() * 300;
      final top = random.nextDouble() * 800;
      final size = 40.0 + random.nextDouble() * 60;
      final opacity = 0.15 + random.nextDouble() * 0.25;

      clovers.add(
        AnimatedBuilder(
          animation: _floatAnimation,
          builder: (context, child) {
            return Positioned(
              left: left,
              top: top + _floatAnimation.value * (i % 2 == 0 ? 1 : -1),
              child: Opacity(
                opacity: opacity,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: CloverPainter(
                    color: const Color(0xFF5F9F7A),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return clovers;
  }
}

class CloverPainter extends CustomPainter {
  final Color color;

  CloverPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final leafRadius = size.width * 0.3;

    for (int i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 4;
      final leafX = centerX + math.cos(angle) * (size.width * 0.15);
      final leafY = centerY + math.sin(angle) * (size.height * 0.15);

      final path = Path();
      path.moveTo(centerX, centerY);
      path.quadraticBezierTo(
        leafX + math.cos(angle + math.pi / 2) * leafRadius,
        leafY + math.sin(angle + math.pi / 2) * leafRadius,
        leafX + math.cos(angle) * leafRadius,
        leafY + math.sin(angle) * leafRadius,
      );
      path.quadraticBezierTo(
        leafX + math.cos(angle - math.pi / 2) * leafRadius,
        leafY + math.sin(angle - math.pi / 2) * leafRadius,
        centerX,
        centerY,
      );

      canvas.drawPath(path, paint);
    }

    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX, size.height * 0.8),
      stemPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}