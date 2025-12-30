import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login.dart';
import 'home.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      print('=== AUTH WRAPPER DEBUG ===');
      
      final userId = await ApiService.instance.getUserId();
      print('User ID from storage: $userId');
      
      if (mounted) {
        setState(() {
          _isLoggedIn = userId != null;
          _isLoading = false; // ✅ QUAN TRỌNG: Phải tắt loading
        });
      }
      
      print('Is logged in: $_isLoggedIn');
      print('Is loading: $_isLoading');
    } catch (e) {
      print('Auth check error: $e');
      
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false; // ✅ QUAN TRỌNG: Phải tắt loading ngay cả khi lỗi
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper build - isLoading: $_isLoading, isLoggedIn: $_isLoggedIn');
    
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFD4EBD4),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F9F7A)),
              ),
              SizedBox(height: 20),
              Text(
                'Đang kiểm tra đăng nhập...',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D5F3F),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const Home() : const Login();
  }
}