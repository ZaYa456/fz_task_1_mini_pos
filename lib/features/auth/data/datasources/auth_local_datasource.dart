import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:fz_task_1/core/database/hive_initializer.dart';
import 'package:fz_task_1/features/auth/data/models/user_model.dart';

/// Abstract interface for auth local data source
abstract class AuthLocalDataSource {
  bool isLoggedIn();
  UserModel? getCurrentUser();
  Future<UserModel?> login(String username, String password);
  Future<void> logout();
  Future<void> ensureDefaultUser();
}

/// Implementation of local authentication using Hive
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box<UserModel> userBox;
  final Box preferencesBox;
  static const String _currentUserKey = 'current_user';

  AuthLocalDataSourceImpl({
    required this.userBox,
    required this.preferencesBox,
  });

  @override
  bool isLoggedIn() {
    final currentUsername = preferencesBox.get(_currentUserKey);
    return currentUsername != null;
  }

  @override
  UserModel? getCurrentUser() {
    final username = preferencesBox.get(_currentUserKey);
    if (username == null) return null;

    return userBox.values.firstWhere(
      (user) => user.name == username,
      orElse: () => throw Exception('User not found'),
    );
  }

  @override
  Future<UserModel?> login(String username, String password) async {
    final hashedPassword = _hashPassword(password);

    try {
      final user = userBox.values.firstWhere(
        (user) => user.name == username && user.passwordHash == hashedPassword,
      );

      // Store current user
      await preferencesBox.put(_currentUserKey, username);
      return user;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    await preferencesBox.delete(_currentUserKey);
  }

  @override
  Future<void> ensureDefaultUser() async {
    // Check if admin user exists
    final adminExists = userBox.values.any((user) => user.name == 'admin');

    if (!adminExists) {
      final admin = UserModel()
        ..name = 'admin'
        ..passwordHash = _hashPassword('1234')
        ..registeredDate = DateTime.now();

      await userBox.add(admin);
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
