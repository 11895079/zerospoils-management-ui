import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature_flags_service.dart';
import 'feature_flag_key.dart';

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Provider for the FeatureFlagsService
final featureFlagsServiceProvider = FutureProvider<FeatureFlagsService>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return FeatureFlagsService(prefs: prefs);
});

/// Convenience provider to check if a specific flag is enabled
///
/// Usage: ref.watch(isFlagEnabledProvider(FeatureFlagKey.receiptOcr))
final isFlagEnabledProvider = FutureProvider.family<bool, FeatureFlagKey>((
  ref,
  flag,
) async {
  final service = await ref.watch(featureFlagsServiceProvider.future);
  return service.isEnabled(flag);
});

/// Get all flags and their current values
final allFlagsProvider = FutureProvider<Map<FeatureFlagKey, bool>>((ref) async {
  final service = await ref.watch(featureFlagsServiceProvider.future);
  return service.getAllFlags();
});

/// Get all flags with their override status (for developer settings UI)
final allFlagsWithStatusProvider =
    FutureProvider<Map<FeatureFlagKey, ({bool value, bool isOverridden})>>((
      ref,
    ) async {
      final service = await ref.watch(featureFlagsServiceProvider.future);
      return service.getAllFlagsWithStatus();
    });
