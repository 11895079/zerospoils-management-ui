import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../auth/firebase_auth_service.dart';
import '../auth/secure_token_service.dart';
import '../distribution/app_distribution_service.dart';
import '../reference/reference_pack_fetchers.dart';

/// Handle FCM background messages. Must be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }

  // Background messages arrive here when the app is terminated or in the
  // background. Minimal processing only — avoid heavy I/O.
  debugPrint(
    '[FCM] Background message received: ${message.messageId} '
    'title="${message.notification?.title}"',
  );
}

/// Bootstrap Firebase services for telemetry, auth, and remote configuration.
///
/// Initializes:
/// - Firebase Core (required for all Firebase services)
/// - Firebase Authentication (anonymous sign-in for baseline auth)
/// - Secure Token Storage (persists ID tokens across app restarts)
/// - Crash Reporting (firebase_crashlytics)
/// - Remote Config (for feature flag remote overrides)
/// - Cloud Messaging / FCM (push notifications for expiry alerts)
class FirebaseBootstrapService {
  static void recordStartupBreadcrumb(String message) {
    debugPrint('[Startup] $message');
    if (!kDebugMode && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.log('[Startup] $message');
    }
  }

  static void recordStartupError(
    String step,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('[Startup] $step: $error');
    if (!kDebugMode && Firebase.apps.isNotEmpty) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: step,
        fatal: false,
      );
    }
  }

  static Future<void> initialize() async {
    try {
      // Initialize Firebase Core
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // Initialize App Check as early as possible so Firestore/Auth requests
      // include attestation tokens.
      await _initializeAppCheck();

      // Initialize Firebase Authentication (anonymous sign-in with token caching)
      final authService = FirebaseAuthService();
      final tokenService = SecureTokenService();

      // Try to restore user from cached token first
      final cachedToken = await tokenService.getIdToken();
      if (cachedToken != null) {
        debugPrint(
          '[Firebase] Cached ID token found, attempting to restore session',
        );
        // Firebase Auth will auto-restore if token is valid
        // If expired, sign in anonymously below will refresh
      }

      // Sign in anonymously (creates new user or refreshes existing session)
      await authService.signInAnonymously();

      // Cache the fresh ID token for next app launch
      final user = authService.currentUser;
      if (user != null) {
        final idTokenResult = await authService.getIdToken();
        if (idTokenResult != null) {
          await tokenService.saveIdToken(
            idToken: idTokenResult.token ?? '',
            userId: user.uid,
          );
        }
      }

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
      await remoteConfig.setDefaults({
        ReferencePackRemoteConfigKeys.manifestUrl: '',
      });

      // Fetch/activate in background so first frame is never blocked.
      // Errors are handled here so a failed fetch never becomes an unhandled
      // async exception (which can crash debug builds / flake tests).
      unawaited(
        remoteConfig.fetchAndActivate().catchError((Object e) {
          debugPrint('[Firebase] Remote Config fetch/activate failed: $e');
          return false;
        }),
      );

      // Initialize Firebase Cloud Messaging (FCM) for push notifications.
      // Keep this async from app startup to avoid pre-runApp stalls.
      unawaited(
        _initializeFcm().catchError((Object e) {
          debugPrint('[Firebase] FCM initialization failed: $e');
        }),
      );

      // Initialize App Distribution Tester SDK (beta/debug builds only).
      // This is a no-op in production builds and never blocks startup.
      unawaited(
        AppDistributionService.instance.initialize().catchError((Object e) {
          debugPrint('[Firebase] App Distribution init failed: $e');
        }),
      );

      debugPrint(
        '[Firebase] Bootstrap complete: Core + Auth (anonymous, token cached) '
        '+ Crashlytics + Remote Config + FCM initialized',
      );
    } catch (e) {
      debugPrint('[Firebase] Bootstrap failed: $e');
      // Continue app startup even if Firebase fails (graceful degradation)
    }
  }

  /// Set up FCM background handler, request permission, and log the device token.
  static Future<void> _initializeFcm() async {
    // Register the top-level background message handler.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // Never prompt during bootstrap. The app already exposes an explicit
    // in-app permission flow; prompting here can block first-frame rendering
    // on iOS and produce a blank native window before Flutter paints.
    final settings = await messaging.getNotificationSettings();

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      try {
        final token = await messaging.getToken();
        if (kDebugMode) {
          final redactedToken = token == null
              ? 'null'
              : token.length <= 12
              ? '[redacted]'
              : '${token.substring(0, 8)}...${token.substring(token.length - 4)}';
          debugPrint('[FCM] Device token (redacted): $redactedToken');
        }
      } on FirebaseException catch (e) {
        if (e.code == 'apns-token-not-set') {
          debugPrint(
            '[FCM] APNS token not available yet; skipping token fetch for now',
          );
        } else {
          rethrow;
        }
      }
    } else {
      debugPrint(
        '[FCM] Notifications not authorized: ${settings.authorizationStatus}',
      );
    }

    // Handle messages received while the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '[FCM] Foreground message: ${message.messageId} '
        'title="${message.notification?.title}"',
      );
      // Local notification display for foreground messages is handled by the
      // notification_service.dart layer; no direct UI push here.
    });

    // Handle taps on notifications that opened the app from terminated state.
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '[FCM] App opened from terminated state via notification: '
        '${initialMessage.messageId}',
      );
    }

    // Handle notification taps when the app is in the background (not terminated).
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[FCM] App opened from background via notification: '
        '${message.messageId}',
      );
    });
  }

  static Future<void> _initializeAppCheck() async {
    try {
      if (kIsWeb) {
        debugPrint(
          '[Firebase] App Check on web requires reCAPTCHA config; skipping activation here.',
        );
        return;
      }

      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttestWithDeviceCheckFallback,
      );

      debugPrint('[Firebase] App Check activated');
    } catch (e) {
      debugPrint('[Firebase] App Check activation failed: $e');
    }
  }
}
