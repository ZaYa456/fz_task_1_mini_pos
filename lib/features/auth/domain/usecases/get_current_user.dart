import 'package:fz_task_1/features/auth/domain/entities/user.dart';
import 'package:fz_task_1/features/auth/domain/repositories/auth_repository.dart';

/// Use case for getting the currently logged in user.
class GetCurrentUser {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  /// Returns the currently authenticated user, or null if not logged in
  User? call() {
    return repository.getCurrentUser();
  }
}
