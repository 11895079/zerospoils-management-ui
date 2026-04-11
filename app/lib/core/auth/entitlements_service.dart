import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';

/// Entitlements service that resolves Pro tier from Firebase Auth custom claims.
///
/// Acts as the single source of truth for feature entitlements:
/// - Reads `pro_tier` custom claim from ID token
/// - Maps to Pro-only feature flags when `pro_tier=true`
/// - Called on app startup and after auth state changes
class EntitlementsService {
  final FirebaseAuthService authService;

  EntitlementsService({required this.authService});

  /// Get all entitlements as a map (used by FeatureFlagsService).
  ///
  /// Returns a map of feature flags to their entitlement status.
  /// Example: {'batch_photo_capture': true, 'cloud_sync': true}
  ///
  /// For closed testing: Set custom claims in Firebase Console for users:
  /// - Non-Pro user: {} (empty claims)
  /// - Pro user: {"pro_tier": true}
  Future<Map<String, bool>> getEntitlements() async {
    try {
      final idToken = await authService.getIdToken();
      if (idToken == null) {
        debugPrint(
          '[Entitlements] No ID token available; all features disabled',
        );
        return {};
      }

      // Extract pro_tier custom claim (default: false if not present)
      final isPro = (idToken.claims?['pro_tier'] as bool?) ?? false;
      debugPrint('[Entitlements] pro_tier: $isPro');

      // Map custom claims to feature flag entitlements
      // Pro-only features: batch_photo_capture, cloud_sync, cloud_analytics_export
      // Free-tier features should be omitted here so feature flag defaults remain authoritative.
      return {
        'batch_photo_capture': isPro,
        'cloud_sync': isPro,
        'cloud_analytics_export': isPro,
        // Free-tier features remain unaffected
        'household_sync': false, // Deferred to M5+
        'iot_hooks': false, // Deferred to M5+
      };
    } catch (e) {
      debugPrint('[Entitlements] Failed to get entitlements: $e');
      // Graceful degradation: assume no Pro access
      return {};
    }
  }

  /// Convenience: Check if user is Pro tier.
  ///
  /// Used for UI-level gating (e.g., showing Pro badge in settings).
  Future<bool> isPro() async {
    try {
      final idToken = await authService.getIdToken();
      return (idToken?.claims?['pro_tier'] as bool?) ?? false;
    } catch (_) {
      return false;
    }
  }
}
