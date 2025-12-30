import 'package:flutter/material.dart';
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
import 'screens/medicine_call.dart';
import 'screens/alarm_screen.dart';
import 'services/notification_service.dart';
import 'services/alarm_manager_service.dart';

// ✅ Global navigator key để navigate từ bất kỳ đâu
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize NotificationService (backup)
  await NotificationService().initialize();
  
  // ✅ Khởi động AlarmManagerService để tự động hiển thị màn hình
  AlarmManagerService().startMonitoring();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nhắc Uống Thuốc',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // ✅ Set global navigator key
      theme: ThemeData(
        primaryColor: const Color(0xFF5F9F7A),
        scaffoldBackgroundColor: const Color(0xFFD4EBD4),
        fontFamily: 'Roboto',
      ),
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