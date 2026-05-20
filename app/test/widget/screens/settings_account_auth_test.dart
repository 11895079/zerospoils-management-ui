import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerospoils/core/auth/auth_providers.dart';
import 'package:zerospoils/core/auth/firebase_auth_service.dart';
import 'package:zerospoils/presentation/screens/settings_screen.dart';

class _FakeFirebaseAuthService implements FirebaseAuthService {
  final StreamController<User?> _controller =
      StreamController<User?>.broadcast();

  int signInCalls = 0;
  int createCalls = 0;
  int signOutCalls = 0;
  int resetCalls = 0;
  int googleCalls = 0;
  String? lastEmail;
  String? lastPassword;

  void dispose() {
    _controller.close();
  }

  @override
  Stream<User?> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => null;

  @override
  String? get currentUserEmail => null;

  @override
  String? get currentUserId => null;

  @override
  Future<void> createEmailPasswordAccount({
    required String email,
    required String password,
  }) async {
    createCalls += 1;
    lastEmail = email;
    lastPassword = password;
  }

  @override
  Future<IdTokenResult?> getIdToken() async => null;

  @override
  bool get isSignedInAnonymously => false;

  @override
  Future<void> signInAnonymously() async {}

  @override
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    lastEmail = email;
    lastPassword = password;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    resetCalls += 1;
    lastEmail = email;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleCalls += 1;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Account tile opens auth dialog and validates credentials', (
    tester,
  ) async {
    final fakeAuthService = _FakeFirebaseAuthService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            firebaseAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.person),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Account'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('account_signin_button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(fakeAuthService.signInCalls, 0);

    await tester.enterText(
      find.byKey(const Key('account_email_field')),
      'user@example.com',
    );

    await tester.ensureVisible(
      find.byKey(const Key('account_forgot_password_button')),
    );
    await tester.tap(find.byKey(const Key('account_forgot_password_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthService.resetCalls, 1);
    expect(fakeAuthService.lastEmail, 'user@example.com');

    expect(
      find.byKey(const Key('account_apple_signin_button')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('account_password_field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('account_signin_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthService.signInCalls, 1);
    expect(fakeAuthService.lastEmail, 'user@example.com');
    expect(fakeAuthService.lastPassword, 'password123');

    fakeAuthService.dispose();
  });

  testWidgets('Account tile triggers Google sign in', (tester) async {
    final fakeAuthService = _FakeFirebaseAuthService();

    await tester.pumpWidget(
      MaterialApp(
        home: ProviderScope(
          overrides: [
            firebaseAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: const Scaffold(body: SettingsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.person),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('account_google_signin_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('account_google_signin_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthService.googleCalls, 1);

    fakeAuthService.dispose();
  });
}
