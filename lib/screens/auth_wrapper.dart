// Kiểm tra đăng nhập

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../database/auth_service.dart';
import 'login.dart';
import 'home.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        // Đang load
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFD4EBD4),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5F9F7A)),
              ),
            ),
          );
        }

        // Đã đăng nhập
        if (snapshot.hasData) {
          return const Home();
        }

        // Chưa đăng nhập
        return const Login();
      },
    );
  }
}