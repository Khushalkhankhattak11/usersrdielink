import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppThemeViewModel extends ChangeNotifier {
  AppThemeViewModel() {
    load();
  }

  static const _themeModeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final storedMode = preferences.getString(_themeModeKey);
      _themeMode = switch (storedMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } on Object {
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool enabled) async {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_themeModeKey, enabled ? 'dark' : 'light');
    } on Object {
      // Theme preference should not block the UI.
    }
  }
}
