library;

/// Zesto Repository - Handles persistence of mascot state
/// Uses shared_preferences for local storage

import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/domain/models/zesto_model.dart';
import '../../core/utils/app_logger.dart';

class ZestoRepository {
  static const String _settingsKey = 'zesto_settings';
  static const String _unlockProgressKey = 'zesto_unlock_progress';

  final SharedPreferences _prefs;

  ZestoRepository(this._prefs);

  /// Get mascot settings (or defaults if not found)
  MascotSettings getSettings() {
    final json = _prefs.getString(_settingsKey);
    if (json == null) {
      return const MascotSettings(); // Return defaults
    }
    try {
      // Assuming simple JSON string storage or JSON decode utility
      final decoded = _jsonDecode(json) as Map<String, dynamic>;
      return MascotSettings.fromJson(decoded);
    } catch (e) {
      appLogger.w('Error loading mascot settings', error: e);
      return const MascotSettings();
    }
  }

  /// Save mascot settings
  Future<void> saveSettings(MascotSettings settings) async {
    final json = _jsonEncode(settings.toJson());
    await _prefs.setString(_settingsKey, json);
  }

  /// Update specific setting
  Future<void> updateSetting({
    bool? enabled,
    MascotFrequency? frequency,
    bool? showCelebrations,
    bool? showTips,
    bool? showDailyWelcome,
  }) async {
    final current = getSettings();
    final updated = current.copyWith(
      enabled: enabled ?? current.enabled,
      frequency: frequency ?? current.frequency,
      showCelebrations: showCelebrations ?? current.showCelebrations,
      showTips: showTips ?? current.showTips,
      showDailyWelcome: showDailyWelcome ?? current.showDailyWelcome,
    );
    await saveSettings(updated);
  }

  /// Get unlock progress (or create new if not found)
  MascotUnlockProgress getUnlockProgress() {
    final json = _prefs.getString(_unlockProgressKey);
    if (json == null) {
      return const MascotUnlockProgress(); // Return defaults (avocado unlocked)
    }
    try {
      final decoded = _jsonDecode(json) as Map<String, dynamic>;
      return MascotUnlockProgress.fromJson(decoded);
    } catch (e) {
      appLogger.w('Error loading mascot unlock progress', error: e);
      return const MascotUnlockProgress();
    }
  }

  /// Save unlock progress
  Future<void> saveUnlockProgress(MascotUnlockProgress progress) async {
    final json = _jsonEncode(progress.toJson());
    await _prefs.setString(_unlockProgressKey, json);
  }

  /// Add consumption for item category
  /// Returns unlocked character if threshold reached, null otherwise
  Future<MascotCharacter?> addConsumption(String category) async {
    final progress = getUnlockProgress();
    final updated = progress.addConsumption(category, 1);

    // Check for unlock
    final newCount = updated.categoryConsumption[category] ?? 0;
    final unlocked = updated.checkForUnlock(category, newCount);

    await saveUnlockProgress(unlocked ?? updated);

    // Return newly unlocked character, if any
    if (unlocked != null) {
      final newlyUnlocked = unlocked.unlockedCharacters
          .where((c) => !progress.unlockedCharacters.contains(c))
          .firstOrNull;
      return newlyUnlocked;
    }
    return null;
  }

  /// Set active mascot
  Future<void> setActiveCharacter(MascotCharacter character) async {
    final progress = getUnlockProgress();
    final updated = progress.setActiveCharacter(character);
    await saveUnlockProgress(updated);
  }

  /// Get current active mascot emoji
  String getActiveMascotEmoji() {
    final progress = getUnlockProgress();
    return MascotUnlockProgress.getCharacterEmoji(progress.activeCharacter);
  }

  /// Clear all Zesto data (for testing/reset)
  Future<void> clear() async {
    await _prefs.remove(_settingsKey);
    await _prefs.remove(_unlockProgressKey);
  }

  /// Helper: Simple JSON encode (placeholder - use json package in real app)
  String _jsonEncode(Map<String, dynamic> data) {
    // In real app, use: import 'dart:convert'; json.encode(data)
    return data.toString(); // Simplified for now
  }

  /// Helper: Simple JSON decode (placeholder - use json package in real app)
  dynamic _jsonDecode(String json) {
    // In real app, use: import 'dart:convert'; json.decode(json)
    // For now, assume it's a Map representation
    return {};
  }
}
