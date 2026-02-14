import 'package:fz_task_1/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:fz_task_1/features/auth/data/models/user_model.dart';
import 'package:fz_task_1/features/auth/domain/entities/user.dart';
import 'package:fz_task_1/features/auth/domain/repositories/auth_repository.dart';

/// Implementation of the auth repository using local Hive datasource.
class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource dataSource;

  AuthRepositoryImpl(this.dataSource);

  @override
  bool isLoggedIn() {
    return dataSource.isLoggedIn();
  }

  @override
  User? getCurrentUser() {
    final userModel = dataSource.getCurrentUser();
    if (userModel == null) return null;

    return _userModelToEntity(userModel);
  }

  @override
  Future<User?> login(String username, String password) async {
    final userModel = await dataSource.login(username, password);
    if (userModel == null) return null;

    return _userModelToEntity(userModel);
  }

  @override
  Future<void> logout() async {
    await dataSource.logout();
  }

  @override
  Future<void> ensureDefaultUser() async {
    await dataSource.ensureDefaultUser();
  }

  /// Convert data model to domain entity
  User _userModelToEntity(UserModel model) {
    return User(
      id: model.key.toString(),
      username: model.name,
      name: model.name,
      registeredDate: model.registeredDate,
    );
  }
}
