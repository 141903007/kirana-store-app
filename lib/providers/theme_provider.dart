import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

/// Persists the user's light/dark/system choice across app restarts.
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitializing = true;

  ThemeMode get themeMode => _themeMode;
  bool get isInitializing => _isInitializing;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _themeMode = _fromStoredValue(prefs.getString(AppConstants.prefKeyThemeMode));
    _isInitializing = false;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyThemeMode, mode.name);
  }

  ThemeMode _fromStoredValue(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
