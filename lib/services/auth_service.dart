import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class AuthService {
  final DbHelper _db = DbHelper();

  static const String _setupKey = 'setup_complete';

  /// SHA-256 hash of any input string
  String hashInput(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Returns true if first-launch setup has NOT been completed yet
  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_setupKey) ?? false);
  }

  /// Mark the one-time setup as done
  Future<void> markSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupKey, true);
  }

  /// Create the admin account (first launch only)
  Future<void> setupAccount({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String pin,
  }) async {
    final user = UserModel(
      username: username.trim(),
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      passwordHash: hashInput(password),
      pinHash: hashInput(pin),
    );
    await _db.insertUser(user);
    await markSetupComplete();
  }

  /// Verify username + password → returns [UserModel] on success, null on failure
  Future<UserModel?> login(String username, String password) async {
    final user = await _db.getUser(username.trim());
    if (user == null) return null;
    if (user.passwordHash != hashInput(password)) return null;
    return user;
  }

  /// Check whether the provided username exists in the admin database.
  Future<bool> validateUsername(String username) async {
    final user = await _db.getUser(username.trim());
    return user != null;
  }

  /// Verify PIN for password-reset flow for the given username.
  Future<bool> verifyPin(String username, String pin) async {
    final user = await _db.getUser(username.trim());
    if (user == null) return false;
    return user.pinHash == hashInput(pin);
  }

  Future<bool> verifyPassword(String username, String password) async {
    final user = await login(username, password);
    return user != null;
  }

  Future<void> clearSetupComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_setupKey);
  }

  /// Reset the stored password for the admin user by username.
  Future<void> resetPassword(String username, String newPassword) async {
    final user = await _db.getUser(username.trim());
    if (user == null) return;
    await _db.updatePassword(user.id!, hashInput(newPassword));
  }
}
