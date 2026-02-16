import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'core/theme/app_theme.dart';
import 'core/database/hive_initializer.dart';
import 'app/di.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/state/auth_state.dart';
import 'features/dashboard/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open all boxes
  await setupHive();

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthStateHandler(), // Smart routing based on auth state
    );
  }

  @override
  void dispose() {
    final sessionBox = Hive.box(kSessionBox);
    sessionBox.put(kGracefulShutdownKey, true);
    super.dispose();
  }
}

/// Handles routing based on authentication state
class AuthStateHandler extends ConsumerWidget {
  const AuthStateHandler({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    // Show appropriate screen based on auth state
    return switch (authState) {
      AuthInitial() => const _LoadingScreen(),
      AuthAuthenticated() => const HomePage(),
      AuthUnauthenticated() => const LoginPage(),
      AuthLoading() => const _LoadingScreen(),
      AuthError() => const LoginPage(),
    };
  }
}

/// Simple loading screen shown during auth check
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
