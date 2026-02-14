import 'package:fz_task_1/features/auth/domain/entities/user.dart';

/// Abstract repository interface for authentication operations.
/// The implementation will be in the data layer.
abstract class AuthRepository {
  /// Check if a user is currently logged in
  bool isLoggedIn();

  /// Get the currently logged in user
  User? getCurrentUser();

  /// Attempt to login with credentials
  /// Returns the user if successful, null otherwise
  Future<User?> login(String username, String password);

  /// Logout the current user
  Future<void> logout();

  /// Ensure a default admin user exists in the system
  Future<void> ensureDefaultUser();
}
