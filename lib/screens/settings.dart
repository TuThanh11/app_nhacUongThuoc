import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations - clovers
          Positioned(
            top: 50,
            right: -30,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/Them_Thuoc.png', width: 241.55),
            ),
          ),
          Positioned(
            bottom: 200,
            right: -20,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/images/co4la2.png', width: 241.55),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with back button and title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Back button
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
                      const SizedBox(width: 50), // Balance the layout
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Profile avatar
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F9F7A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 20),

                // Username
                const Text(
                  'Tên người dùng',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D5F3F),
                  ),
                ),

                const SizedBox(height: 40),

                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      // Thông tin tài khoản button
                      _buildSettingsButton(context, 'Thông tin tài khoản', () {
                        Navigator.pushNamed(context, '/user_info');
                      }),

                      const SizedBox(height: 20),

                      // Liên hệ button
                      _buildSettingsButton(context, 'Liên hệ', () {
                        // Navigate to contact
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Liên hệ')),
                        );
                      }),

                      const SizedBox(height: 80),

                      // Đăng xuất button (different style)
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
        onPressed: () {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Đăng xuất'),
                content: const Text('Bạn có chắc muốn đăng xuất?'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Hủy'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('Đăng xuất'),
                  ),
                ],
              );
            },
          );
        },
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
