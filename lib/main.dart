import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/signup.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/auth_wrapper.dart';
import 'screens/settings.dart';
import 'screens/add_reminder.dart';
import 'screens/edit_reminder.dart';
import 'screens/select_time.dart';
import 'screens/medicine_home.dart';
import 'screens/medicine_info.dart';
import 'screens/medicine_edit.dart';
import 'screens/add_medicine.dart';
import 'screens/progress.dart';
import 'screens/user_info.dart';
import 'screens/change_password.dart';
import 'screens/avatar_selection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDsNyUZZujExEI5r3HosP61VB9QVlCaA5o",
      authDomain: "app-nhac-uong-thuoc-38214.firebaseapp.com",
      projectId: "app-nhac-uong-thuoc-38214",
      storageBucket: "app-nhac-uong-thuoc-38214.firebasestorage.app",
      messagingSenderId: "147880856538",
      appId: "1:147880856538:web:956d8c95577b984b620ee3"
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhắc Uống Thuốc',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF5F9F7A),
        scaffoldBackgroundColor: const Color(0xFFD4EBD4),
        fontFamily: 'Roboto',
      ),
      // Sử dụng AuthWrapper làm màn hình đầu tiên
      home: const AuthWrapper(),
      routes: {
        '/signup': (context) => const Signup(),
        '/login': (context) => const Login(),
        '/home': (context) => const Home(),
        '/settings': (context) => const Settings(),
        '/add_reminder': (context) => const AddReminder(),
        '/edit_reminder': (context) => const EditReminder(),
        '/select_time': (context) => const SelectTime(),
        '/medicine_home': (context) => const MedicineHome(),
        '/medicine_info': (context) => const MedicineInfo(),
        '/medicine_edit': (context) => const MedicineEdit(),
        '/add_medicine': (context) => const AddMedicine(),
        '/progress': (context) => const Progress(),
        '/user_info': (context) => const UserInfo(),
        '/change_password': (context) => const ChangePassword(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/avatar_selection') {
          final avatarUrl = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => AvatarSelection(currentAvatarUrl: avatarUrl),
          );
        }
        return null;
      },
    );
  }
}