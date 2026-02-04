import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/hive_setup.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';

void main() async {
  // Ensure Flutter widgets are bound before running async code
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await setupHive();

  // Decide initial route using Hive session
  final authService = AuthService();
  final bool isLoggedIn = authService.isLoggedIn();

  runApp(
    ProviderScope(
      child: MainApp(
        startPage: isLoggedIn ? const HomePage() : const LoginPage(),
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, required this.startPage});

  final Widget startPage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: startPage,
    );
  }
}
