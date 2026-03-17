import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_preferences.dart';

final themePreferencesStoreProvider = Provider<ThemePreferencesStore>((ref) {
  return ThemePreferencesStore();
});

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.light;
});

Future<void> loadThemeModePreference(WidgetRef ref) async {
  final store = ref.read(themePreferencesStoreProvider);
  final savedThemeMode = await store.loadThemeMode();
  ref.read(themeModeProvider.notifier).state = savedThemeMode;
}
