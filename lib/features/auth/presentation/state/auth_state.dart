import 'package:fz_task_1/features/auth/domain/entities/user.dart';

/// Represents the different states of authentication
sealed class AuthState {
  const AuthState();
}

/// Initial state - checking authentication status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// User is not authenticated
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);
}

/// Authentication is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authentication failed
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}
