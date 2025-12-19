import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/reminder.dart';
import '../utils/time_format_helper.dart';

class AlarmScreen extends StatefulWidget {
  final Reminder reminder;
  final String time;

  const AlarmScreen({
    super.key,
    required this.reminder,
    required this.time,
  });

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late AudioPlayer _audioPlayer;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _audioPlayer = AudioPlayer();
    _playAlarmSound();
  }

  Future<void> _playAlarmSound() async {
    try {
      // Phát âm thanh lặp lại
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);
      // Sử dụng âm thanh mặc định hoặc từ assets
      await _audioPlayer.play(AssetSource('sounds/alarm.mp3'));
    } catch (e) {
      print('Error playing alarm sound: $e');
    }
  }

  Future<void> _stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      print('Error stopping alarm sound: $e');
    }
  }

  void _onSnooze() {
    _stopAlarmSound();
    Navigator.pop(context, 'snooze');
  }

  void _onTaken() {
    _stopAlarmSound();
    Navigator.pop(context, 'taken');
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Ngăn không cho back
      child: Scaffold(
        backgroundColor: const Color(0xFF2D5F3F),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated bell icon
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 0.5 - 0.25,
                      child: Icon(
                        Icons.notifications_active,
                        size: 120,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Time display
                Text(
                  TimeFormatHelper.format24To12Hour(widget.time),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 20),

                // Medicine name
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Đến giờ uống thuốc',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.reminder.medicineName,
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (widget.reminder.description != null &&
                          widget.reminder.description!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.reminder.description!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 60),

                // Snooze button
                Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onSnooze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FB896),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.snooze, size: 28),
                        SizedBox(width: 15),
                        Text(
                          'Báo lại (5 phút)',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Taken button
                Container(
                  width: double.infinity,
                  height: 70,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _onTaken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2D5F3F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(35),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle, size: 28),
                        SizedBox(width: 15),
                        Text(
                          'Đã uống',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}