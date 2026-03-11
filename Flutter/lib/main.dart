import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Load persisted auth token
  await AuthService().loadFromStorage();
  runApp(const LexNovaApp());
}

class LexNovaApp extends StatelessWidget {
  const LexNovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LexNova',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routes: {
        '/home': (_) => const MainShell(),
        '/login': (_) => const LoginScreen(),
      },
      home: const SplashScreen(),
    );
  }
}