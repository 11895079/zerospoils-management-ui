import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import '../auth/firebase_auth_service.dart';

/// Bootstrap Firebase services for telemetry, auth, and remote configuration.
///
/// Initializes:
/// - Firebase Core (required for all Firebase services)
/// - Firebase Authentication (anonymous sign-in for baseline auth)
/// - Crash Reporting (firebase_crashlytics)
/// - Remote Config (for feature flag remote overrides)
class FirebaseBootstrapService {
  static Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      await Firebase.initializeApp();

      // Initialize Firebase Authentication (anonymous sign-in)
      final authService = FirebaseAuthService();
      await authService.signInAnonymously();

      // Configure Crashlytics for production telemetry
      if (!kDebugMode) {
        FlutterError.onError = (errorDetails) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Initialize Remote Config for feature flag overrides
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Fetch and activate remote config
      await remoteConfig.fetchAndActivate();

      debugPrint(
        '[Firebase] Bootstrap complete: Core + Auth (anonymous) + Crashlytics + Remote Config initialized',
      );
    } catch (e) {
      debugPrint('[Firebase] Bootstrap failed: $e');
      // Continue app startup even if Firebase fails (graceful degradation)
    }
  }
}
