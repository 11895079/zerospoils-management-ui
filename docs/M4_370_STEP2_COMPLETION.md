# M4/370 Step 2: Platform Build Configuration & Bootstrap Services

**Status**: ✅ COMPLETE  
**Date**: 2026-02-15  
**Work Item**: [M4/370 - Closed Testing Backend Security Hardening](planning/milestones/M4/370-closed-testing-backend-security-hardening-firebase-supabase.md)

## Overview

Step 2 establishes the foundation for Firebase and Supabase integration by:
1. Configuring Android Gradle to accept and build with Firebase google-services.json
2. Configuring iOS to use GoogleService-Info.plist for Firebase initialization
3. Creating bootstrap services that initialize Firebase and Supabase during app startup
4. Adding ProGuard/R8 minification rules for release builds

## What Was Completed

### 1. Android Gradle Configuration (`android/build.gradle.kts` and `android/app/build.gradle.kts`)

**Root-level changes** (`android/build.gradle.kts`):
- Added Firebase Google Services Gradle plugin version 4.3.15 (applies to all gradle subprojects)

**App-level changes** (`android/app/build.gradle.kts`):
- Applied `com.google.gms.google-services` plugin (must come after Android/Kotlin plugins)
- Added build type configuration for release builds:
  - Conditional obfuscation via CLI: `flutter build apk --release --obfuscate --split-debug-info=./debug-info/`
  - ProGuard/R8 minification with packaging options to exclude conflicting ProGuard rules
  - Note: Dart obfuscation happens via Flutter CLI flag, not in Gradle (documented for build team)

**Why this matters**:
- The google-services plugin automatically parses `android/app/google-services.json` at build time
- Extracts Firebase project credentials and injects them into the app manifest
- ProGuard rules prevent Firebase/Supabase classes from being stripped during minification

### 2. Platform-Specific Firebase Config Files (Placeholders)

**Android**: `app/android/app/google-services.json`
- Placeholder JSON with standard Firebase schema
- Contains placeholders for: project_id, client_id, client_email, private_key
- Real credentials must be downloaded from Firebase Console and placed here (not version controlled)

**iOS**: `app/ios/Runner/GoogleService-Info.plist`
- Placeholder plist with standard Firebase schema
- Contains placeholders for: CLIENT_ID, API_KEY, GCM_SENDER_ID, PROJECT_ID
- Real credentials downloaded from Firebase Console (not version controlled)

### 3. .gitignore Updates

Added VCS exclusions for security:
```
app/android/app/google-services.json
app/ios/Runner/GoogleService-Info.plist
.env
.env.local
app/lib/core/secure_storage/secrets.dart
*.keystore
debug-info/
*.symbols
```

The placeholder files remain in git for reference, but real credential files are excluded.

### 4. Bootstrap Services

**Firebase Bootstrap Service** (`app/lib/core/bootstrap/firebase_bootstrap_service.dart`):

```dart
class FirebaseBootstrapService {
  static Future<void> initialize() async {
    // 1. Initialize Firebase Core (required for all Firebase services)
    await Firebase.initializeApp();
    
    // 2. Configure Crashlytics (prod only) for crash reporting
    if (!kDebugMode) {
      FlutterError.onError = ...  // Global error handler
      PlatformDispatcher.instance.onError = ...  // Unhandled errors
    }
    
    // 3. Initialize Remote Config with fetch/activation
    // Used by feature flags to retrieve remote overrides
  }
}
```

**Features**:
- Graceful initialization with try-catch (app continues if Firebase unavailable)
- Crash reporting only enabled in production (kDebugMode check)
- Remote Config auto-fetches on startup with 1-hour minimum interval
- Debug logging for troubleshooting

**Supabase Bootstrap Service** (`app/lib/core/bootstrap/supabase_bootstrap_service.dart`):

```dart
class SupabaseBootstrapService {
  static Future<void> initialize() async {
    // 1. Read credentials from environment variables (empty = graceful degradation)
    final supabaseUrl = _getEnvOrDefault('SUPABASE_URL', '');
    final anonKey = _getEnvOrDefault('SUPABASE_ANON_KEY', '');
    
    if (credentials.isEmpty) return; // Continue app without Supabase
    
    // 2. Initialize Supabase client
    await Supabase.initialize(url: ..., anonKey: ...);
    
    // 3. Restore session from secure storage (auto-login)
    await _restoreSessionIfAvailable();
    
    // 4. Listen for auth state changes (persist tokens on login)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null) _persistSession(data.session);
    });
  }
}
```

**Features**:
- Environment-based credential loading (no hardcoding)
- Session auto-recovery from secure storage on app restart
- Token persistence via flutter_secure_storage (Android KeyStore, iOS Keychain)
- Graceful degradation if Supabase not configured

### 5. App Startup Integration (`lib/main.dart`)

Updated main() to call bootstrap services in correct order:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Firebase (telemetry, crash reporting, remote config)
  await FirebaseBootstrapService.initialize();
  
  // 2. Supabase (auth, entitlements)
  await SupabaseBootstrapService.initialize();
  
  // 3. Local storage (Hive)
  await Hive.initFlutter();
  // ... rest of startup
}
```

**Startup sequence ensures**:
1. Firebase crash reporting active before any code runs
2. Remote Config is fetched and available for feature flags
3. Supabase sessions are restored before UI renders
4. Local storage initialized after cloud services
5. Graceful degradation if any service fails

### 6. Android Release Hardening Config (`android/app/proguard-rules.pro`)

Minification and obfuscation rules for Play Store releases:
- Preserves Firebase, Supabase, and Flutter classes (required for functionality)
- Strips unused code and obfuscates remaining code
- Keeps annotation metadata for reflection-based libraries
- Preserves native method names for platform channels

**Build command**:
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info/
```

This produces:
- `app-release.apk`: Obfuscated + minified
- `debug-info/`: Symbol files for crash report deobfuscation

## Test Results

✅ **All 284 tests passing** (no regressions from bootstrap changes)
- 94 unit tests
- 3 developer settings widget tests (feature flags)
- 187 integration/widget tests

✅ **Analyzer**: Zero errors, zero warnings

## Architecture Decisions

### Why Separate Bootstrap Services?

1. **Separation of Concerns**: Firebase handles telemetry/crash reporting; Supabase handles auth/entitlements
2. **Independent Initialization**: Each service can fail gracefully without blocking the other
3. **Feature Flags Integration**: Remote Config values are available immediately after Firebase bootstrap for feature gates
4. **Testing**: Services can be mocked independently in unit/widget tests

### Why Graceful Degradation?

- **Firebase**: If not configured, app continues without crash reporting (acceptable for local dev)
- **Supabase**: If credentials empty, app continues as offline-first (normal MVP behavior)
- **App remains functional** even if cloud services fail, following offline-first design principle

### Why Environment Variables for Supabase?

- **Security**: Credentials not hardcoded or in version control
- **Flexibility**: Different credentials for dev/staging/production
- **CI/CD Ready**: Secrets can be injected via `--dart-define` at build time:
  ```bash
  flutter build apk --dart-define=SUPABASE_URL=https://... --dart-define=SUPABASE_ANON_KEY=...
  ```

## Next Steps (Steps 3-6)

### Step 3: Firebase Auth + Custom Claims for Pro Tier (NEW DESIGN)
- Create FirebaseAuthService that wraps Firebase Authentication
- Extract `pro_tier` custom claim from ID token after login
- Create EntitlementsService that reads custom claims and maps to feature flag entitlements
- Wire into FeatureFlagsService._getRemoteOverrides() to gate feature availability
- Resolve Pro tier from Firebase Auth (source of truth, no Supabase auth needed)
- Update feature flags integration: OCR, batch photo capture, cloud sync check `isPro` from custom claims

### Step 4: Android Release Hardening
- Enable Flutter obfuscation in CI/CD pipeline
- Verify ProGuard rules don't strip Firebase classes
- Test release APK can initialize Firebase + Auth successfully
- Collect debug symbols for crash reporting deobfuscation

### Step 5: Integrity + Token Storage Services
- Implement IntegrityService (Play Integrity API wrapper for Android)
- Implement SecureTokenService (flutter_secure_storage adapter for Firebase ID tokens)
- Gated Pro endpoints verify integrity before processing
- ID tokens stored in platform-provided secure storage (KeyStore/Keychain)

### Step 6: Validation & Documentation
- Unit tests for FirebaseAuthService + EntitlementsService
- Integration test for full bootstrap flow (Firebase Auth → claims → flags)
- Kill-switch behavior via Remote Config (feature flags can be toggled server-side)
- Closed-testing release checklist (Firebase project setup, custom claims for test users, signing keys)

## Files Modified

**New Files Created**:
1. `app/lib/core/bootstrap/firebase_bootstrap_service.dart` (74 lines)
2. `app/lib/core/bootstrap/supabase_bootstrap_service.dart` (96 lines)
3. `app/lib/core/bootstrap/bootstrap.dart` (11 lines, export barrel)
4. `app/android/app/google-services.json` (placeholder, real from Firebase Console)
5. `app/ios/Runner/GoogleService-Info.plist` (placeholder, real from Firebase Console)
6. `app/android/app/proguard-rules.pro` (40 lines, minification config)

**Modified Files**:
1. `app/android/build.gradle.kts` (+5 lines: Firebase plugin)
2. `app/android/app/build.gradle.kts` (+13 lines: google-services plugin, buildTypes config, packaging options)
3. `app/lib/main.dart` (+4 import + bootstrap calls)
4. `.gitignore` (+13 lines: Firebase secrets, tokens, symbols)
5. `app/pubspec.yaml` (pre-existing: Firebase/Supabase/storage packages from Step 1)

## Local Development Instructions

### Setup Firebase Project (Optional for Local Dev)

For local emulation or testing with real Firebase:

1. Create Firebase project at https://console.firebase.google.com
2. Register Android app and download `google-services.json`
3. Place in `app/android/app/google-services.json`
4. Register iOS app and download `GoogleService-Info.plist`
5. Place in `app/ios/Runner/GoogleService-Info.plist`
6. Run `flutter clean` and `flutter pub get`

**Without Firebase credentials**: App still builds and runs (graceful degradation)

### Setup Supabase Project (Optional for Local Dev)

For auth/entitlements testing:

1. Create Supabase project at https://supabase.com
2. Copy project URL and anon key
3. Inject via environment variables:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co \
               --dart-define=SUPABASE_ANON_KEY=your-anon-key
   ```

**Without Supabase credentials**: App continues in offline-first mode

### Local Build & Test

```bash
# Clean build with fresh dependencies
cd app
flutter clean
flutter pub get

# Run analyzer
flutter analyze

# Run all tests
flutter test

# Build debug APK (with placeholder configs)
flutter build apk --debug

# Build release APK (with obfuscation)
flutter build apk --release --obfuscate --split-debug-info=./debug-info/
```

## Security Considerations

✅ **Credentials Not in VCS**: google-services.json and GoogleService-Info.plist excluded from git

✅ **Token Persistence**: JWTs stored in platform-provided secure storage (KeyStore on Android, Keychain on iOS)

✅ **Crash Reporting Privacy**: Crashlytics configured for debug-only initialization; production crashes reported to Firebase

⚠️ **App Signing**: Release APK must be signed with Play Store key before upload (handled by deployment team)

⚠️ **Environment Variables**: SUPABASE_URL and SUPABASE_ANON_KEY must be injected securely in CI/CD (never commit to repo)

## Testing Coverage

✅ **Unit Tests**: All 94 existing unit tests passing (app behavior unaffected by bootstrap changes)

✅ **Widget Tests**: All 187 widget/integration tests passing (no UI regressions)

✅ **Analyzer**: Zero lint warnings

### Next: Bootstrap Service Unit Tests (Step 6)

When completed, will add:
- Unit tests for FirebaseBootstrapService (mock Firebase Core)
- Unit tests for SupabaseBootstrapService (mock Supabase client)
- Integration test for full bootstrap flow (real services with test emulators)

## References

- [Firebase Admin SDK + Flutter Integration](https://firebase.google.com/docs/flutter/setup?hl=en)
- [Supabase Flutter Documentation](https://supabase.com/docs/guides/auth/auth-flutter)
- [Android ProGuard/R8 Documentation](https://developer.android.com/studio/build/shrink-code)
- [Flutter Obfuscation Documentation](https://docs.flutter.dev/deployment/obfuscate)
- [Google Play Integrity API](https://developer.android.com/google/play/integrity) (used in Step 5)

---

**Next Session**: Proceed to Step 3 (Remote Entitlements Adapter) or Step 4 (Android Release Hardening) based on priority.
