import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_auth_service.dart';
import 'entitlements_service.dart';
import 'secure_token_service.dart';

/// Riverpod provider for FirebaseAuthService (singleton).
final firebaseAuthServiceProvider = Provider((ref) {
  return FirebaseAuthService();
});

/// Riverpod provider for SecureTokenService (singleton).
final secureTokenServiceProvider = Provider((ref) {
  return SecureTokenService();
});

/// Riverpod provider for EntitlementsService (depends on auth service).
final entitlementsServiceProvider = Provider((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return EntitlementsService(authService: authService);
});

/// Riverpod provider for current user entitlements (async, may refresh).
///
/// Use this to subscribe to entitlement changes:
/// ```dart
/// final entitlements = await ref.watch(currentEntitlementsProvider.future);
/// final isPro = entitlements['receipt_ocr'] ?? false;
/// ```
final currentEntitlementsProvider = FutureProvider((ref) async {
  final entitlementsService = ref.watch(entitlementsServiceProvider);
  return await entitlementsService.getEntitlements();
});

/// Riverpod provider for Pro tier status.
///
/// Convenience provider for checking if user has Pro access:
/// ```dart
/// final isPro = await ref.watch(isProProvider.future);
/// ```
final isProProvider = FutureProvider((ref) async {
  final entitlementsService = ref.watch(entitlementsServiceProvider);
  return await entitlementsService.isPro();
});

/// Cached entitlements for synchronous feature flag resolution.
///
/// This is a mutable cache that gets updated asynchronously.
/// Used by FeatureFlagsService for synchronous flag checks.
final _cachedEntitlementsProvider =
    StateNotifierProvider<_CachedEntitlementsNotifier, Map<String, bool>>((
      ref,
    ) {
      return _CachedEntitlementsNotifier();
    });

/// Notifier for managing cached entitlements.
class _CachedEntitlementsNotifier extends StateNotifier<Map<String, bool>> {
  _CachedEntitlementsNotifier() : super({});

  void updateEntitlements(Map<String, bool> entitlements) {
    state = entitlements;
  }
}

/// Get cached entitlements synchronously (for feature flags service).
///
/// Returns the last known entitlements, or empty map if not yet initialized.
/// This is called from FeatureFlagsService during isEnabled() checks.
final getCachedEntitlementsProvider = Provider<Map<String, bool>>((ref) {
  return ref.watch(_cachedEntitlementsProvider);
});

/// Initialize cached entitlements synchronously.
///
/// Should be called during app startup after Firebase Auth is ready.
/// Updates the cache for feature flag resolution.
Future<void> initializeCachedEntitlements(WidgetRef ref) async {
  final entitlements = await ref.watch(currentEntitlementsProvider.future);
  final notifier = ref.read(_cachedEntitlementsProvider.notifier);
  notifier.updateEntitlements(entitlements);
}
