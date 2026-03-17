import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/theme/theme_preferences.dart';

void main() {
  group('ThemePreferencesStore', () {
    late ThemePreferencesStore store;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      store = ThemePreferencesStore();
    });

    test('loadThemeMode returns light by default', () async {
      final mode = await store.loadThemeMode();
      expect(mode, ThemeMode.light);
    });

    test('setThemeMode persists dark mode', () async {
      await store.setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ThemePreferencesStore.darkModeEnabledKey), true);

      final loaded = await store.loadThemeMode();
      expect(loaded, ThemeMode.dark);
    });

    test('setThemeMode persists light mode', () async {
      SharedPreferences.setMockInitialValues({
        ThemePreferencesStore.darkModeEnabledKey: true,
      });
      store = ThemePreferencesStore();

      await store.setThemeMode(ThemeMode.light);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(ThemePreferencesStore.darkModeEnabledKey), false);

      final loaded = await store.loadThemeMode();
      expect(loaded, ThemeMode.light);
    });
  });
}
