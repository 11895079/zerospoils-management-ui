import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:zerospoils/core/auth/auth.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SecureTokenService integration tests', () {
    late FirebaseAuthService authService;
    late SecureTokenService tokenService;

    setUpAll(() async {
      // Initialize Firebase for integration tests
      await Firebase.initializeApp();
      authService = FirebaseAuthService();
      tokenService = SecureTokenService();
    });

    tearDown(() async {
      // Clean up tokens after each test
      await tokenService.clearTokens();
    });

    testWidgets('Token persists across app restart simulation', (tester) async {
      // Step 1: Sign in anonymously and cache token
      await authService.signInAnonymously();
      final user = authService.currentUser;
      expect(user, isNotNull);
      expect(user!.uid, isNotEmpty);

      final idTokenResult = await authService.getIdToken();
      expect(idTokenResult, isNotNull);
      final idToken = idTokenResult!.token;
      expect(idToken, isNotNull);
      expect(idToken, isNotEmpty);

      // Step 2: Cache token in secure storage
      await tokenService.saveIdToken(idToken: idToken!, userId: user.uid);

      // Step 3: Verify token is cached
      final hasToken = await tokenService.hasIdToken();
      expect(hasToken, isTrue);

      // Step 4: Retrieve cached token (simulates app restart)
      final cachedToken = await tokenService.getIdToken();
      expect(cachedToken, isNotNull);
      expect(cachedToken, equals(idToken));

      // Step 5: Retrieve cached user ID
      final cachedUserId = await tokenService.getUserId();
      expect(cachedUserId, equals(user.uid));
    });

    testWidgets('Token retrieval returns null when none cached', (
      tester,
    ) async {
      // Verify no token exists initially
      final hasToken = await tokenService.hasIdToken();
      expect(hasToken, isFalse);

      final cachedToken = await tokenService.getIdToken();
      expect(cachedToken, isNull);
    });

    testWidgets('Clear tokens removes all cached data', (tester) async {
      // Step 1: Sign in and cache token
      await authService.signInAnonymously();
      final user = authService.currentUser;
      final idTokenResult = await authService.getIdToken();
      final idToken = idTokenResult?.token;

      await tokenService.saveIdToken(idToken: idToken!, userId: user!.uid);

      // Step 2: Verify token exists
      final hasTokenBefore = await tokenService.hasIdToken();
      expect(hasTokenBefore, isTrue);

      // Step 3: Clear tokens
      await tokenService.clearTokens();

      // Step 4: Verify tokens cleared
      final hasTokenAfter = await tokenService.hasIdToken();
      expect(hasTokenAfter, isFalse);

      final cachedToken = await tokenService.getIdToken();
      expect(cachedToken, isNull);
    });
  });
}
