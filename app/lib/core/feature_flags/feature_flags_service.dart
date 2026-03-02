import 'package:shared_preferences/shared_preferences.dart';
import 'feature_flag_key.dart';

/// Service that manages feature flag resolution with override support
///
/// Resolution order: local_override > remote_override (optional) > default
class FeatureFlagsService {
  final SharedPreferences _prefs;

  /// Optional remote config provider (e.g., Firebase Remote Config)
  /// Allows extending the service later without changing core logic
  final Map<String, bool> Function()? _getRemoteOverrides;

  /// Prefix for storing flag overrides in shared preferences
  static const String _overridePrefix = 'feature_flag_override_';

  FeatureFlagsService({
    required SharedPreferences prefs,
    Map<String, bool> Function()? getRemoteOverrides,
  }) : _prefs = prefs,
       _getRemoteOverrides = getRemoteOverrides;

  /// Check if a feature flag is enabled
  ///
  /// Precedence:
  /// 1. Local override (user toggled in debug)
  /// 2. Remote override (Firebase Remote Config, etc.)
  /// 3. Code default
  bool isEnabled(FeatureFlagKey flag) {
    // Check local override first
    final localOverride = _getLocalOverride(flag);
    if (localOverride != null) {
      return localOverride;
    }

    // Check remote override (if available)
    final remoteOverrides = _getRemoteOverrides?.call() ?? {};
    if (remoteOverrides.containsKey(flag.key)) {
      return remoteOverrides[flag.key]!;
    }

    // Fall back to default
    return flag.defaultValue;
  }

  /// Set a local override for a flag (persists to SharedPreferences)
  ///
  /// Returns true if the override was successfully persisted
  Future<bool> setLocalOverride(FeatureFlagKey flag, bool value) async {
    return _prefs.setBool(_overridePrefix + flag.key, value);
  }

  /// Remove a local override for a flag (restores to remote/default behavior)
  ///
  /// Returns true if the override was successfully removed
  Future<bool> removeLocalOverride(FeatureFlagKey flag) async {
    return _prefs.remove(_overridePrefix + flag.key);
  }

  /// Get the local override for a flag, if set
  ///
  /// Returns null if no local override is set (will fall through to remote/default)
  bool? _getLocalOverride(FeatureFlagKey flag) {
    final key = _overridePrefix + flag.key;
    if (_prefs.containsKey(key)) {
      return _prefs.getBool(key);
    }
    return null;
  }

  /// Check if a flag has a local override set
  bool hasLocalOverride(FeatureFlagKey flag) {
    return _prefs.containsKey(_overridePrefix + flag.key);
  }

  /// Reset all local overrides to their defaults
  ///
  /// Returns true if all overrides were successfully cleared
  Future<bool> resetAllOverrides() async {
    final keys = _prefs.getKeys();
    bool success = true;
    for (final key in keys) {
      if (key.startsWith(_overridePrefix)) {
        final removed = await _prefs.remove(key);
        if (!removed) success = false;
      }
    }
    return success;
  }

  /// Get map of all flags and their current values (for debugging/UI)
  Map<FeatureFlagKey, bool> getAllFlags() {
    return {for (final flag in FeatureFlagKey.all) flag: isEnabled(flag)};
  }

  /// Get map of all flags with their override status
  ///
  /// Useful for UI that shows which flags are using overrides vs defaults
  Map<FeatureFlagKey, ({bool value, bool isOverridden})>
  getAllFlagsWithStatus() {
    return {
      for (final flag in FeatureFlagKey.all)
        flag: (value: isEnabled(flag), isOverridden: hasLocalOverride(flag)),
    };
  }
}
