import 'package:flutter/material.dart';

class AvatarPresets {
  static const List<Map<String, dynamic>> presets = [
    {'image': 'assets/images/avatar1.jpg', 'name': 'Cute Cat 1'},
    {'image': 'assets/images/avatar2.jpg', 'name': 'Cute Cat 2'},
    {'image': 'assets/images/avatar3.jpg', 'name': 'Cute Cat 3'},
    {'image': 'assets/images/avatar4.jpg', 'name': 'Cute Cat 4'},
    {'image': 'assets/images/avatar5.jpg', 'name': 'Cute Cat 5'},
    {'image': 'assets/images/avatar6.jpg', 'name': 'Cute Cat 6'},
    {'image': 'assets/images/avatar7.jpg', 'name': 'Cute Cat 7'},
    {'image': 'assets/images/avatar8.jpg', 'name': 'Cute Cat 8'},
    {'image': 'assets/images/avatar9.jpg', 'name': 'Cute Cat 9'},
    {'image': 'assets/images/avatar10.jpg', 'name': 'Cute Cat 10'},
    {'image': 'assets/images/avatar11.jpg', 'name': 'Cute Cat 11'},
    {'image': 'assets/images/avatar12.jpg', 'name': 'Cute Cat 12'},
  ];
  
  static Widget buildAvatar({
    required int index,
    required double size,
    Color? backgroundColor,
  }) {
    if (index < 0 || index >= presets.length) {
      return _buildDefaultAvatar(size, backgroundColor);
    }
    
    return ClipOval(
      child: Image.asset(
        presets[index]['image'] as String,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAvatar(size, backgroundColor);
        },
      ),
    );
  }
  
  static Widget _buildDefaultAvatar(double size, Color? backgroundColor) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF5F9F7A),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}