import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoggedIn = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;

  Future<bool> login(String username, String password) async {
    final user = await _authService.login(username, password);
    if (user != null) {
      _currentUser = user;
      _isLoggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> setupAccount({
    required String username,
    required String firstName,
    required String lastName,
    required String password,
    required String pin,
  }) async {
    await _authService.setupAccount(
      username: username,
      firstName: firstName,
      lastName: lastName,
      password: password,
      pin: pin,
    );
    // Auto login after setup
    final user = await _authService.login(username, password);
    _currentUser = user;
    _isLoggedIn = user != null;
    notifyListeners();
  }

  Future<bool> validateUsername(String username) async {
    return _authService.validateUsername(username);
  }

  Future<bool> verifyPin(String username, String pin) async {
    return _authService.verifyPin(username, pin);
  }

  Future<bool> verifyPassword(String username, String password) async {
    return _authService.verifyPassword(username, password);
  }

  Future<void> clearSetupComplete() async {
    await _authService.clearSetupComplete();
  }

  Future<void> resetPassword(String username, String newPassword) async {
    await _authService.resetPassword(username, newPassword);
  }
}
