import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../repository/user_repository.dart';

/// Owns login/session state for the app's single admin account.
///
/// [errorMessage], when set, holds a translation key (e.g.
/// `'auth.invalid_credentials'`) — screens call `.tr()` on it themselves so
/// this provider stays free of any localization/BuildContext dependency.
class AuthProvider extends ChangeNotifier {
  AuthProvider({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepository();

  final UserRepository _userRepository;

  bool _isInitializing = true;
  bool _isLoggedIn = false;
  UserModel? _currentUser;
  String? errorMessage;

  bool get isInitializing => _isInitializing;
  bool get isLoggedIn => _isLoggedIn;
  UserModel? get currentUser => _currentUser;

  /// Restores a previously-persisted session, if any. Called once when the
  /// app starts, before deciding whether to show the Login screen.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool(AppConstants.prefKeyIsLoggedIn) ?? false;

    if (wasLoggedIn) {
      _currentUser = await _userRepository.getPrimaryUser();
      _isLoggedIn = _currentUser != null;
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    errorMessage = null;
    final user = await _userRepository.verifyCredentials(username, password);

    if (user == null) {
      errorMessage = 'auth.invalid_credentials';
      notifyListeners();
      return false;
    }

    _currentUser = user;
    _isLoggedIn = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyIsLoggedIn, true);
    return true;
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentUser = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyIsLoggedIn, false);
  }

  Future<bool> changeUsername(String newUsername) async {
    final user = _currentUser;
    if (user == null) return false;

    await _userRepository.updateUsername(user.id!, newUsername);
    _currentUser = user.copyWith(username: newUsername);
    notifyListeners();
    return true;
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final user = _currentUser;
    if (user == null) return false;

    final verified =
        await _userRepository.verifyCredentials(user.username, currentPassword);
    if (verified == null) {
      errorMessage = 'auth.current_password_incorrect';
      notifyListeners();
      return false;
    }

    await _userRepository.updatePassword(user.id!, newPassword);
    return true;
  }

  Future<void> setSecurityQuestion(String question, String answer) async {
    final user = _currentUser;
    if (user == null) return;

    await _userRepository.updateSecurityQuestion(user.id!, question, answer);
    _currentUser = user.copyWith(securityQuestion: question);
    notifyListeners();
  }

  /// Forgot-password flow — runs before login, so it reads the user record
  /// directly rather than relying on [currentUser].
  Future<UserModel?> getUserForRecovery() => _userRepository.getPrimaryUser();

  bool verifySecurityAnswer(UserModel user, String answer) =>
      _userRepository.verifySecurityAnswer(user, answer);

  Future<void> resetPasswordViaRecovery(int userId, String newPassword) {
    return _userRepository.updatePassword(userId, newPassword);
  }
}
