import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure token storage service for Firebase ID tokens.
///
/// Uses platform-native secure storage:
/// - Android: EncryptedSharedPreferences with AES encryption in KeyStore
/// - iOS: Keychain Services
///
/// Tokens are persisted across app restarts and survive uninstall-reinstall
/// on iOS (unless user explicitly removes app data).
class SecureTokenService {
  static const String _idTokenKey = 'firebase_id_token';
  static const String _userIdKey = 'firebase_user_id';

  final FlutterSecureStorage _storage;

  SecureTokenService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  /// Save Firebase ID token and user ID to secure storage.
  ///
  /// Call this after successful sign-in or token refresh.
  Future<void> saveIdToken({
    required String idToken,
    required String userId,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _idTokenKey, value: idToken),
        _storage.write(key: _userIdKey, value: userId),
      ]);
      debugPrint('[SecureTokenService] ID token saved for user: $userId');
    } catch (e) {
      debugPrint('[SecureTokenService] Failed to save ID token: $e');
      rethrow;
    }
  }

  /// Retrieve cached Firebase ID token from secure storage.
  ///
  /// Returns null if no token is cached or if storage read fails.
  /// The caller should validate token expiry and refresh if needed.
  Future<String?> getIdToken() async {
    try {
      final token = await _storage.read(key: _idTokenKey);
      if (token != null) {
        debugPrint('[SecureTokenService] ID token retrieved from cache');
      }
      return token;
    } catch (e) {
      debugPrint('[SecureTokenService] Failed to read ID token: $e');
      return null;
    }
  }

  /// Retrieve cached user ID from secure storage.
  ///
  /// Returns null if no user ID is cached or if storage read fails.
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      debugPrint('[SecureTokenService] Failed to read user ID: $e');
      return null;
    }
  }

  /// Clear all cached tokens and user data.
  ///
  /// Call this on explicit sign-out or when switching users.
  Future<void> clearTokens() async {
    try {
      await _storage.deleteAll();
      debugPrint('[SecureTokenService] All tokens cleared');
    } catch (e) {
      debugPrint('[SecureTokenService] Failed to clear tokens: $e');
      rethrow;
    }
  }

  /// Check if cached ID token exists in secure storage.
  ///
  /// Does not validate token expiry; use for quick offline checks only.
  Future<bool> hasIdToken() async {
    try {
      final token = await _storage.read(key: _idTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('[SecureTokenService] Failed to check token existence: $e');
      return false;
    }
  }
}
