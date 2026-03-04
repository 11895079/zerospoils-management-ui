import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zerospoils/core/auth/auth.dart';
import 'package:zerospoils/core/bootstrap/bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bootstrap integration tests', () {
    late FirebaseAuthService authService;
    late EntitlementsService entitlementsService;
    late SecureTokenService tokenService;

    setUpAll(() async {
      // Initialize Firebase for integration tests
      await Firebase.initializeApp();
      authService = FirebaseAuthService();
      tokenService = SecureTokenService();
      entitlementsService = EntitlementsService(authService: authService);
    });

    tearDown(() async {
      // Clean up tokens after each test
      await tokenService.clearTokens();
    });

    testWidgets('Full bootstrap flow: Auth → Token → Entitlements → Flags', (
      tester,
    ) async {
      // Step 1: Initialize Firebase bootstrap (simulates app startup)
      await FirebaseBootstrapService.initialize();

      // Step 2: Verify Firebase Auth is ready
      final user = authService.currentUser;
      expect(
        user,
        isNotNull,
        reason: 'User should be signed in after bootstrap',
      );
      expect(user!.isAnonymous, isTrue, reason: 'User should be anonymous');

      // Step 3: Verify ID token is available
      final idTokenResult = await authService.getIdToken();
      expect(idTokenResult, isNotNull, reason: 'ID token should be available');
      final idToken = idTokenResult!.token;
      expect(idToken, isNotEmpty);

      // Step 4: Verify token is cached in secure storage
      final cachedToken = await tokenService.getIdToken();
      expect(cachedToken, equals(idToken), reason: 'Token should be cached');

      // Step 5: Verify entitlements load correctly
      final entitlements = await entitlementsService.getEntitlements();
      expect(
        entitlements,
        isNotEmpty,
        reason: 'Entitlements should return Pro features',
      );

      // Verify Pro feature keys exist
      expect(entitlements.containsKey('receipt_ocr'), isTrue);
      expect(entitlements.containsKey('batch_photo_capture'), isTrue);
      expect(entitlements.containsKey('cloud_sync'), isTrue);
      expect(entitlements.containsKey('cloud_analytics_export'), isTrue);

      // Step 6: Verify default entitlements (no Pro custom claims)
      // Anonymous users default to free tier (all Pro features = false)
      expect(
        entitlements['receipt_ocr'],
        isFalse,
        reason: 'Receipt OCR should be Pro-only',
      );
    });

    testWidgets('Remote Config initialized after bootstrap', (tester) async {
      // Step 1: Bootstrap Firebase
      await FirebaseBootstrapService.initialize();

      // Step 2: Verify Remote Config is ready
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Remote Config should be initialized (no error on getValue)
      expect(
        () => remoteConfig.getBool('feature_flags_enabled'),
        returnsNormally,
        reason: 'Remote Config should be initialized',
      );
    });

    testWidgets('Bootstrap gracefully handles Firebase failures', (
      tester,
    ) async {
      // Note: This test validates graceful degradation.
      // If Firebase initialization fails, app should continue startup
      // (tested manually by disabling network).

      // For this test, we verify bootstrap succeeds under normal conditions
      await expectLater(
        FirebaseBootstrapService.initialize(),
        completes,
        reason: 'Bootstrap should complete without throwing',
      );
    });

    testWidgets('Kill-switch: Feature flag disabled via Remote Config', (
      tester,
    ) async {
      // Step 1: Bootstrap Firebase
      await FirebaseBootstrapService.initialize();

      // Step 2: Get Remote Config instance
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Step 3: Verify feature flag defaults
      // (Actual kill-switch testing requires Firebase Console config changes)
      final featureFlagsEnabled = remoteConfig.getBool('feature_flags_enabled');

      // Default should be true (feature flags enabled)
      // In production, set to false in Firebase Console to disable all flags
      expect(
        featureFlagsEnabled,
        isTrue,
        reason: 'Feature flags should be enabled by default',
      );

      // Step 4: Verify other kill-switch flags exist
      // These can be toggled in Firebase Console for emergency rollback
      final receiptOcrEnabled = remoteConfig.getBool('receipt_ocr_enabled');
      final cloudSyncEnabled = remoteConfig.getBool('cloud_sync_enabled');

      // Defaults should be true unless explicitly disabled in console
      expect(
        receiptOcrEnabled,
        isTrue,
        reason: 'Receipt OCR should be enabled by default',
      );
      expect(
        cloudSyncEnabled,
        isTrue,
        reason: 'Cloud sync should be enabled by default',
      );
    });

    testWidgets('Token refresh after app restart', (tester) async {
      // Step 1: First app launch - bootstrap and cache token
      await FirebaseBootstrapService.initialize();

      final firstToken = await tokenService.getIdToken();
      expect(firstToken, isNotNull);

      // Step 2: Simulate app restart (don't clear tokens)
      // In real scenario, app process restarts but secure storage persists

      // Step 3: Bootstrap again (simulates second app launch)
      await FirebaseBootstrapService.initialize();

      // Step 4: Verify token is restored (may be refreshed if expired)
      final secondToken = await tokenService.getIdToken();
      expect(
        secondToken,
        isNotNull,
        reason: 'Token should be restored after restart',
      );

      // Token may be different if it was refreshed, but should still be valid
      final idTokenResult = await authService.getIdToken();
      expect(idTokenResult, isNotNull);
    });
  });
}
