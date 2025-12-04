import 'package:flutter/material.dart';
import 'screens/signup.dart';
import 'screens/login.dart';
import 'screens/home.dart';
import 'screens/settings.dart';
import 'screens/add_reminder.dart';
import 'screens/select_time.dart';
import 'screens/medicine_home.dart';
import 'screens/medicine_info.dart';
import 'screens/medicine_edit.dart';
import 'screens/add_medicine.dart';
import 'screens/progress.dart';
import 'screens/user_info.dart';
import 'screens/change_password.dart';

void main() {
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
      initialRoute: '/login',
      routes: {
        '/signup': (context) => const Signup(),
        '/login': (context) => const Login(),
        '/home': (context) => const Home(),
        '/settings': (context) => const Settings(),
        '/add_reminder': (context) => const AddReminder(),
        '/select_time': (context) => const SelectTime(),
        '/medicine_home': (context) => const MedicineHome(),
        '/medicine_info': (context) => const MedicineInfo(),
        '/medicine_edit': (context) => const MedicineEdit(),
        '/add_medicine': (context) => const AddMedicine(),
        '/progress': (context) => const Progress(),
        '/user_info': (context) => const UserInfo(),
        '/change_password': (context) => const ChangePassword(),
      },
    );
  }
}
