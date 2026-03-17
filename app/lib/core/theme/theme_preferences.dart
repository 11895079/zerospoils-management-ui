import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferencesStore {
  static const String darkModeEnabledKey = 'dark_mode_enabled';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkModeEnabled = prefs.getBool(darkModeEnabledKey) ?? false;
    return isDarkModeEnabled ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeEnabledKey, themeMode == ThemeMode.dark);
  }
}
