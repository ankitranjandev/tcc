import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType {
  light,
  dark,
  system,
}

class ThemeProvider extends ChangeNotifier {
  ThemeType _themeType = ThemeType.system;

  ThemeType get themeType => _themeType;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  String get themeDisplayName {
    switch (_themeType) {
      case ThemeType.light:
        return 'Light mode';
      case ThemeType.dark:
        return 'Dark mode';
      case ThemeType.system:
        return 'System default';
    }
  }

  ThemeMode get themeMode {
    switch (_themeType) {
      case ThemeType.light:
        return ThemeMode.light;
      case ThemeType.dark:
        return ThemeMode.dark;
      case ThemeType.system:
        return ThemeMode.system;
    }
  }

  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt('theme_type') ?? ThemeType.system.index;
      _themeType = ThemeType.values[themeIndex];
      notifyListeners();
    } catch (e) {
      // If SharedPreferences fails, use system default
      _themeType = ThemeType.system;
    }
  }

  Future<void> setTheme(ThemeType type) async {
    if (_themeType == type) return;

    _themeType = type;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_type', type.index);
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> setThemeFromString(String themeName) async {
    ThemeType type;
    switch (themeName) {
      case 'Light mode':
        type = ThemeType.light;
        break;
      case 'Dark mode':
        type = ThemeType.dark;
        break;
      case 'System default':
      default:
        type = ThemeType.system;
        break;
    }
    await setTheme(type);
  }
}
