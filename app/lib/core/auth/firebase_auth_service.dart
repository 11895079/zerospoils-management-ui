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
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
        debugPrint('[FirebaseAuth] Signed in anonymously');
      } else {
        debugPrint(
          '[FirebaseAuth] Already signed in as ${_auth.currentUser?.uid}',
        );
      }
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

  /// Listen to auth state changes (for reactive UI updates).
  ///
  /// Returns a stream of [User?] that emits when user logs in/out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
