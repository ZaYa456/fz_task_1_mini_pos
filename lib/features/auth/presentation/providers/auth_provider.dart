import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fz_task_1/features/auth/domain/usecases/get_current_user.dart';
import 'package:fz_task_1/features/auth/domain/usecases/login.dart';
import 'package:fz_task_1/features/auth/domain/usecases/logout.dart';
import 'package:fz_task_1/features/auth/presentation/state/auth_state.dart';

/// Notifier that manages authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final Login loginUseCase;
  final Logout logoutUseCase;
  final GetCurrentUser getCurrentUserUseCase;

  AuthNotifier({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    Future.microtask(_checkAuthStatus);
  }

  /// Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    state = const AuthLoading();

    final user = getCurrentUserUseCase();

    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = const AuthUnauthenticated();
    }
  }

  /// Attempt to login with credentials
  Future<void> login(String username, String password) async {
    state = const AuthLoading();

    try {
      // Add slight delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      final user = await loginUseCase(username, password);

      if (user != null) {
        state = AuthAuthenticated(user);
      } else {
        state = const AuthError('Invalid credentials. Try admin / 1234');
      }
    } catch (e) {
      state = AuthError('Login failed: ${e.toString()}');
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      await logoutUseCase();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError('Logout failed: ${e.toString()}');
    }
  }

  /// Clear error state
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}
