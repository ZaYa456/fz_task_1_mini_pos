import 'package:fz_task_1/features/auth/domain/repositories/auth_repository.dart';

/// Use case for user logout.
/// Handles the business logic for ending a user session.
class Logout {
  final AuthRepository repository;

  Logout(this.repository);

  /// Logs out the current user
  Future<void> call() async {
    await repository.logout();
  }
}
