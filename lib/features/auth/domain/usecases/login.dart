import 'package:fz_task_1/features/auth/domain/entities/user.dart';
import 'package:fz_task_1/features/auth/domain/repositories/auth_repository.dart';

/// Use case for user login.
/// Encapsulates the business logic for authentication.
class Login {
  final AuthRepository repository;

  Login(this.repository);

  /// Attempts to login with the provided credentials.
  /// Returns the authenticated user if successful, null otherwise.
  Future<User?> call(String username, String password) async {
    // Validate input
    if (username.trim().isEmpty || password.isEmpty) {
      return null;
    }

    // Delegate to repository
    return await repository.login(username.trim(), password);
  }
}
