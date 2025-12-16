import 'package:flutter/material.dart';
import 'dart:convert';
import '../database/auth_service.dart';
import '../utils/avatar_presets.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _username = 'Đang tải...';
  String _email = '';
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = AuthService.instance.currentUser;
      final userInfo = await AuthService.instance.getUserInfo();

      if (mounted) {
        setState(() {
          _username = userInfo?['username'] ?? user?.displayName ?? 'Người dùng';
          _email = user?.email ?? '';
          _avatarUrl = userInfo?['avatar_url'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _username = 'Người dùng';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToAvatarSelection() async {
    final result = await Navigator.pushNamed(
      context,
      '/avatar_selection',
      arguments: _avatarUrl,
    );

    if (result != null) {
      _loadUserInfo();
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(
              color: Color(0xFF2D5F3F),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Bạn có chắc muốn đăng xuất?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Hủy',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 50,
            right: -30,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/Them_Thuoc.png',
                width: 241.55,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -20,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/images/co4la2.png',
                width: 241.55,
                errorBuilder: (context, error, stackTrace) {
                  return Container();
                },
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
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
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Cài đặt',
                            style: TextStyle(
                              fontSize: 32,
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

                Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF5F9F7A),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : _buildAvatar(),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _navigateToAvatarSelection,
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5F9F7A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D5F3F),
                        ),
                      ),

                if (_email.isNotEmpty && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _buildSettingsButton(context, 'Thông tin tài khoản', () {
                        Navigator.pushNamed(context, '/user_info');
                      }),

                      const SizedBox(height: 20),

                      _buildSettingsButton(context, 'Liên hệ', () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              'Liên hệ',
                              style: TextStyle(
                                color: Color(0xFF2D5F3F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('📧 Email: support@nhacuongthuoc.com'),
                                SizedBox(height: 10),
                                Text('📱 Hotline: 1900 xxxx'),
                                SizedBox(height: 10),
                                Text('🌐 Website: www.nhacuongthuoc.com'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Đóng'),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 80),

                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (_avatarUrl == null || _avatarUrl!.isEmpty) {
      return _buildDefaultAvatar();
    }

    // Check if it's a preset avatar
    if (_avatarUrl!.startsWith('preset_')) {
      final index = int.tryParse(_avatarUrl!.replaceFirst('preset_', ''));
      if (index != null && index >= 0 && index < AvatarPresets.presets.length) {
        return AvatarPresets.buildAvatar(
          index: index,
          size: 140,
          backgroundColor: const Color(0xFF5F9F7A),
        );
      }
    }

    // Check if it's Base64 image
    if (_avatarUrl!.startsWith('data:image')) {
      try {
        final base64String = _avatarUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipOval(
          child: Image.memory(
            bytes,
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error displaying base64 avatar: $error');
              return _buildDefaultAvatar();
            },
          ),
        );
      } catch (e) {
        print('Error decoding base64 avatar: $e');
      }
    }

    // Network image
    if (_avatarUrl!.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          _avatarUrl!,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF5F9F7A),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAvatar();
          },
        ),
      );
    }

    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: Color(0xFF5F9F7A),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSettingsButton(
    BuildContext context,
    String text,
    VoidCallback onPressed,
  ) {
    return Container(
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
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5F9F7A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
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
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D5F3F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Đăng xuất',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}