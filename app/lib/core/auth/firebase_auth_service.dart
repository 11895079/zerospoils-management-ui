import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Wrapper around Firebase Authentication.
///
/// Provides:
/// - Anonymous sign-in for authenticated baseline
/// - Easy access to current user ID token with custom claims
/// - Isolation from FirebaseAuth details in service layer
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in anonymously (default for non-custom-auth users).
  ///
  /// Anonymous auth provides a stable user UID and allows custom claims
  /// to be set server-side (e.g., Pro tier verification via Firebase Console).
  Future<void> signInAnonymously() async {
    try {
      // On web, persisted auth state may restore asynchronously right after
      // startup. Wait for the first auth emission to avoid replacing an
      // existing signed-in session with a new anonymous user.
      if (kIsWeb) {
        try {
          await _auth.authStateChanges().first.timeout(
            const Duration(seconds: 2),
          );
        } catch (_) {
          // If restoration times out, continue with fallback behavior.
        }
      }

      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        debugPrint('[FirebaseAuth] Signed in anonymously');
      } else {
        debugPrint(
          '[FirebaseAuth] Already signed in as ${_auth.currentUser?.uid}',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'admin-restricted-operation') {
        debugPrint(
          '[FirebaseAuth] Anonymous sign-in unavailable for this environment; continuing without anon auth',
        );
        return;
      }
      debugPrint('[FirebaseAuth] Anonymous sign-in failed: $e');
      // Continue app; auth is optional for offline-first operation
    } catch (e) {
      debugPrint('[FirebaseAuth] Anonymous sign-in failed: $e');
      // Continue app; auth is optional for offline-first operation
    }
  }

  /// Returns the current authenticated user (or null).
  User? get currentUser => _auth.currentUser;

  /// Returns the current user's ID token.
  ///
  /// ID token contains custom claims set server-side, including `pro_tier`.
  /// Token is refreshed on-demand; stale tokens are handled by Firebase SDK.
  Future<IdTokenResult?> getIdToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      return await user.getIdTokenResult();
    } catch (e) {
      debugPrint('[FirebaseAuth] Failed to get ID token: $e');
      return null;
    }
  }

  /// Convenience getter for user UID.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Convenience getter for current user email.
  String? get currentUserEmail => _auth.currentUser?.email;

  /// Whether the current signed-in user is anonymous.
  bool get isSignedInAnonymously => _auth.currentUser?.isAnonymous ?? false;

  /// Sign in with email/password.
  ///
  /// If the current user is anonymous, this attempts to link credentials first
  /// so existing local/user-linked data stays on the same UID.
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final credential = EmailAuthProvider.credential(
      email: normalizedEmail,
      password: password,
    );

    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      try {
        await user.linkWithCredential(credential);
        debugPrint('[FirebaseAuth] Linked anonymous user to email auth');
        return;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') {
          rethrow;
        }
        // Fall through to sign-in when account already exists.
      }
    }

    await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    debugPrint('[FirebaseAuth] Signed in with email/password');
  }

  /// Sign in with Google provider.
  ///
  /// If the current user is anonymous, this attempts to link credentials first
  /// so existing local/user-linked data stays on the same UID.
  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final user = _auth.currentUser;

    if (kIsWeb) {
      if (user != null && user.isAnonymous) {
        try {
          await user.linkWithProvider(provider);
          debugPrint('[FirebaseAuth] Linked anonymous user to Google auth');
          return;
        } on FirebaseAuthException catch (e) {
          if (e.code != 'credential-already-in-use' &&
              e.code != 'operation-not-supported-in-this-environment') {
            rethrow;
          }
          // Fall through to sign-in when account already exists or provider
          // flow requires popup handling on web.
        }
      }

      final authDynamic = _auth as dynamic;
      await authDynamic.signInWithPopup(provider);
      debugPrint('[FirebaseAuth] Signed in with Google (web popup)');
      return;
    }

    if (user != null && user.isAnonymous) {
      try {
        await user.linkWithProvider(provider);
        debugPrint('[FirebaseAuth] Linked anonymous user to Google auth');
        return;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'credential-already-in-use') {
          rethrow;
        }
        // Fall through to sign-in when account already exists.
      }
    }

    await _auth.signInWithProvider(provider);
    debugPrint('[FirebaseAuth] Signed in with Google');
  }

  /// Create an email/password account.
  ///
  /// If the current user is anonymous, this links the anonymous user to avoid
  /// creating a second account and losing linkage to existing UID-scoped data.
  Future<void> createEmailPasswordAccount({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    final credential = EmailAuthProvider.credential(
      email: normalizedEmail,
      password: password,
    );

    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      await user.linkWithCredential(credential);
      debugPrint('[FirebaseAuth] Linked anonymous user to new email account');
      return;
    }

    await _auth.createUserWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    debugPrint('[FirebaseAuth] Created email/password account');
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('[FirebaseAuth] Signed out');
  }

  /// Sends password reset email for an existing email/password account.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalizedEmail = email.trim();
    await _auth.sendPasswordResetEmail(email: normalizedEmail);
    debugPrint('[FirebaseAuth] Password reset email requested');
  }

  /// Listen to auth state changes (for reactive UI updates).
  ///
  /// Returns a stream of [User?] that emits when user logs in/out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Safe auth-state stream for UI contexts where Firebase may be unavailable.
  ///
  /// Some widget tests run without Firebase initialization. In that case,
  /// return a single-value stream instead of throwing.
  Stream<User?> get authStateChangesSafe {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('[FirebaseAuth] authStateChanges unavailable: $e');
      return Stream<User?>.value(_auth.currentUser);
    }
  }
}
