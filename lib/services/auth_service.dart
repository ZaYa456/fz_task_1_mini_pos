import 'package:hive/hive.dart';
import '../models/user_model.dart';
import 'hive_setup.dart';

class AuthService {
  final Box<User> _userBox = Hive.box<User>(kUserBox);
  final Box _sessionBox = Hive.box(kSessionBox);

  /// Ensure default admin exists
  Future<void> ensureDefaultUser() async {
    if (_userBox.isEmpty) {
      final defaultUser = User()
        ..name = "admin"
        ..passwordHash = "1234" // TODO: hash in real apps
        ..registeredDate = DateTime.now();

      await _userBox.add(defaultUser);
    }
  }

  /// Login user
  bool login(String username, String password) {
    try {
      final user = _userBox.values.firstWhere(
        (u) => u.name.toLowerCase() == username.toLowerCase(),
      );

      if (user.passwordHash == password) {
        _sessionBox.put(kIsLoggedInKey, true);
        _sessionBox.put(kCurrentUserKey, user.name);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Logout user
  Future<void> logout() async {
    await _sessionBox.put(kIsLoggedInKey, false);
    await _sessionBox.delete(kCurrentUserKey);
  }

  /// Check login state
  bool isLoggedIn() {
    return _sessionBox.get(kIsLoggedInKey, defaultValue: false);
  }

  /// Get current logged-in username (optional helper)
  String? currentUser() {
    return _sessionBox.get(kCurrentUserKey);
  }
}
