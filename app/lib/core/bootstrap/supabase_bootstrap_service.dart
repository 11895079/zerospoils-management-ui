import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Bootstrap Supabase services for backend authentication and entitlements.
///
/// Initializes Supabase client with:
/// - Session restoration from secure storage
/// - Event listeners for auth state changes
/// - Ready state for subsequent services to depend on
class SupabaseBootstrapService {
  static const String _supabaseUrl = 'SUPABASE_URL';
  static const String _supabaseAnonKey = 'SUPABASE_ANON_KEY';
  static const String _sessionStorageKey = 'zerospoils_supabase_session';

  static Future<void> initialize() async {
    try {
      // Read credentials from environment or config (see M4/370 implementation notes)
      final supabaseUrl = _getEnvOrDefault(_supabaseUrl, '');
      final anonKey = _getEnvOrDefault(_supabaseAnonKey, '');

      if (supabaseUrl.isEmpty || anonKey.isEmpty) {
        debugPrint(
          '[Supabase] Credentials not configured. '
          'Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
        );
        return; // Continue app without Supabase (graceful degradation for dev)
      }

      // Initialize Supabase client
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: anonKey,
        // Session auto-recovery enabled by default
      );

      // Restore session from secure storage if available
      await _restoreSessionIfAvailable();

      // Listen for auth state changes
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          // Persist session to secure storage on login
          _persistSession(session);
          debugPrint('[Supabase] Auth state changed: User authenticated');
        } else {
          debugPrint('[Supabase] Auth state changed: User signed out');
        }
      });

      debugPrint(
        '[Supabase] Bootstrap complete: Client initialized, auth listeners active',
      );
    } catch (e) {
      debugPrint('[Supabase] Bootstrap failed: $e');
      // Continue app startup even if Supabase fails (graceful degradation)
    }
  }

  /// Restore user session from secure storage (auto-login)
  static Future<void> _restoreSessionIfAvailable() async {
    try {
      const storage = FlutterSecureStorage();
      final sessionJson = await storage.read(key: _sessionStorageKey);
      if (sessionJson != null) {
        // Session persistence handled by Supabase SDK internally
        // This is placeholder for manual recovery if needed
        debugPrint('[Supabase] Session restoration check complete');
      }
    } catch (e) {
      debugPrint('[Supabase] Session restoration failed: $e');
    }
  }

  /// Persist session to secure storage after login
  static Future<void> _persistSession(Session session) async {
    try {
      const storage = FlutterSecureStorage();
      // Store access token and refresh token
      await Future.wait([
        storage.write(
          key: '${_sessionStorageKey}_access_token',
          value: session.accessToken,
        ),
        storage.write(
          key: '${_sessionStorageKey}_refresh_token',
          value: session.refreshToken ?? '',
        ),
      ]);
    } catch (e) {
      debugPrint('[Supabase] Session persistence failed: $e');
    }
  }

  /// Helper to read environment variable or return default
  static String _getEnvOrDefault(String key, String defaultValue) {
    // In production, use --dart-define at build time or platform-specific methods
    // For now, return default (empty credentials trigger graceful degradation)
    return defaultValue;
  }
}
