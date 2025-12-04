import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<Signup> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() {
    // Xử lý đăng ký ở đây
    if (_passwordController.text == _confirmPasswordController.text) {
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Mật khẩu không khớp!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -20,
            right: -20,
            child: Opacity(
              opacity: 0.3,
              child: Icon(
                Icons.local_florist,
                size: 150,
                color: Colors.green.shade300,
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -30,
            child: Icon(
              Icons.local_florist,
              size: 120,
              color: Colors.green.shade400,
            ),
          ),
          Positioned(
            bottom: 180,
            left: 10,
            child: Icon(
              Icons.local_florist,
              size: 80,
              color: Colors.green.shade300,
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    const Text(
                      'Nhắc Uống Thuốc',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D5F3F),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5F9F7A),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Tên đăng nhập label
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Tên đăng nhập',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(controller: _usernameController),
                          const SizedBox(height: 20),

                          // Gmail label
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Gmail',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(controller: _emailController),
                          const SizedBox(height: 20),

                          // Mật khẩu label
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Mật khẩu',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _passwordController,
                            obscureText: true,
                          ),
                          const SizedBox(height: 20),

                          // Nhập lại mật khẩu label
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nhập lại mật khẩu',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Đăng ký button
                    ElevatedButton(
                      onPressed: _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5F9F7A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
