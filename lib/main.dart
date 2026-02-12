import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/database/hive_initializer.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/dashboard/presentation/pages/home_page.dart';
import 'features/auth/presentation/pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open all boxes
  await setupHive();

  // Check authentication status
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
