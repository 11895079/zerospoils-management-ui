import 'package:firebase_app_distribution/firebase_app_distribution.dart'
    as fad;
import 'package:flutter/foundation.dart';

/// Compile-time flag. Set with `--dart-define=BETA_BUILD=true` for beta/debug
/// CI builds.
const bool kBetaBuild = bool.fromEnvironment('BETA_BUILD');

/// Whether the App Distribution Tester SDK should be active.
///
/// Active in:
/// - Any build where `--dart-define=BETA_BUILD=true` is passed (beta CI)
/// - Debug mode (local development)
///
/// Not active in:
/// - Release builds without `BETA_BUILD=true` (production)
bool get _isActive => kBetaBuild || kDebugMode;

/// Wraps Firebase App Distribution Tester SDK operations for beta builds.
///
/// Provides:
/// - Offline-safe update checks on app launch via [checkForUpdate]
/// - Tester sign-in state check via [isTesterSignedIn]
///
/// All methods are **runtime no-ops** in production builds (when
/// `kBetaBuild` is false and `kDebugMode` is false) and swallow non-fatal
/// errors so that beta tooling never disrupts the user experience.
///
/// Note: The `firebase_app_distribution` plugin and its native
/// Android/iOS platform components are included in every build as a
/// direct dependency. The runtime guard prevents the Tester SDK from
/// activating, but the native binary size impact is present in all builds.
///
/// Note: In-app shake-to-feedback requires native platform integration beyond
/// the Flutter plugin (v1.x). Use [BetaFeedbackButton] for an in-app
/// feedback entry point that testers can tap.
class AppDistributionService {
  AppDistributionService._();

  static final AppDistributionService instance = AppDistributionService._();

  // Injected for testing; defaults to the real Firebase implementation.
  @visibleForTesting
  AppDistributionClient client = const _FirebaseAppDistributionClient();

  /// Initialize the Tester SDK. No-op in production builds.
  ///
  /// Call after [Firebase.initializeApp()]. Errors are swallowed so that
  /// Firebase App Distribution issues never block app startup.
  Future<void> initialize() async {
    if (!_isActive) return;
    try {
      await checkForUpdate();
    } catch (e) {
      debugPrint('[AppDistribution] Initialize failed (non-fatal): $e');
    }
  }

  /// Check for a newer available build and show the Firebase update dialog.
  ///
  /// Returns [true] if the update prompt was shown, [false] when up-to-date,
  /// not active (production build), or offline. Applies a 10-second timeout
  /// so the check never stalls app startup.
  Future<bool> checkForUpdate() async {
    if (!_isActive) return false;
    try {
      final hasUpdate = await client.isNewReleaseAvailable().timeout(
        const Duration(seconds: 10),
      );
      if (hasUpdate) {
        debugPrint(
          '[AppDistribution] New release available — prompting tester',
        );
        await client.updateIfNewReleaseAvailable();
      }
      return hasUpdate;
    } on Exception catch (e) {
      // Covers SocketException (offline), TimeoutException, Firebase errors.
      debugPrint('[AppDistribution] Update check failed (non-fatal): $e');
      return false;
    }
  }

  /// Returns whether the current user is signed in as a Firebase tester.
  Future<bool> isTesterSignedIn() async {
    if (!_isActive) return false;
    try {
      return await client.isTesterSignedIn();
    } catch (e) {
      debugPrint('[AppDistribution] isTesterSignedIn failed (non-fatal): $e');
      return false;
    }
  }
}

// ---------------------------------------------------------------------------
// Client abstraction — enables unit testing without real Firebase
// ---------------------------------------------------------------------------

/// Abstraction over Firebase App Distribution Tester SDK calls.
abstract interface class AppDistributionClient {
  Future<bool> isNewReleaseAvailable();
  Future<void> updateIfNewReleaseAvailable();
  Future<bool> isTesterSignedIn();
}

/// Production implementation — delegates to the firebase_app_distribution
/// top-level functions.
class _FirebaseAppDistributionClient implements AppDistributionClient {
  const _FirebaseAppDistributionClient();

  @override
  Future<bool> isNewReleaseAvailable() => fad.isNewReleaseAvailable();

  @override
  Future<void> updateIfNewReleaseAvailable() =>
      fad.updateIfNewReleaseAvailable();

  @override
  Future<bool> isTesterSignedIn() => fad.isTesterSignedIn();
}
