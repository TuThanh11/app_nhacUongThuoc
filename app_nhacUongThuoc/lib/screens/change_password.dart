import 'package:flutter/material.dart';
import '../services/api_service.dart';


class ChangePassword extends StatefulWidget {
  const ChangePassword({super.key});

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Validate
    if (_oldPasswordController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu cũ', isError: true);
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showSnackBar('Vui lòng nhập mật khẩu mới', isError: true);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showSnackBar('Mật khẩu mới phải có ít nhất 6 ký tự', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('Mật khẩu mới không khớp', isError: true);
      return;
    }

    if (_oldPasswordController.text == _newPasswordController.text) {
      _showSnackBar('Mật khẩu mới phải khác mật khẩu cũ', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi Firebase Auth để đổi mật khẩu
      final result = await ApiService.instance.changePassword(_newPasswordController.text);

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result['success']) {
        // Thành công
        Navigator.pop(context);
        _showSnackBar(result['message'], isError: false);
      } else {
        // Thất bại
        _showSnackBar(result['message'], isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Đã xảy ra lỗi: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF5F9F7A),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5F9F7A),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2D5F3F),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFB8E6C9),
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF5F9F7A),
              ),
              onPressed: onToggleVisibility,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: 50,
            right: -30,
            child: Opacity(
              opacity: 0.3,
              child: Icon(
                Icons.local_florist,
                size: 120,
                color: Colors.green.shade300,
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -40,
            child: Icon(
              Icons.local_florist,
              size: 140,
              color: Colors.green.shade300,
            ),
          ),

          SafeArea(
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
                            'Đổi mật khẩu',
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

                const SizedBox(height: 40),

                // Form
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mật khẩu cũ
                        _buildPasswordField(
                          controller: _oldPasswordController,
                          obscureText: _obscureOldPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureOldPassword = !_obscureOldPassword;
                            });
                          },
                          label: 'Mật khẩu cũ',
                          hintText: 'Nhập mật khẩu hiện tại',
                        ),

                        const SizedBox(height: 25),

                        // Mật khẩu mới
                        _buildPasswordField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                          label: 'Mật khẩu mới',
                          hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
                        ),

                        const SizedBox(height: 25),

                        // Nhập lại mật khẩu mới
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          onToggleVisibility: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                          label: 'Nhập lại mật khẩu mới',
                          hintText: 'Xác nhận mật khẩu mới',
                        ),

                        const SizedBox(height: 50),

                        // Xác nhận button
                        Center(
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
                              onPressed: _isLoading ? null : _changePassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5F9F7A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Xác nhận',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}