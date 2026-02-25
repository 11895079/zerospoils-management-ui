# 360: Firebase Integration — Crashlytics, Remote Config, FCM

**Epic:** Infrastructure  
**Milestone:** M3 (MVP Features)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 090 (Flutter app skeleton), 130 (feature flags framework), 250 (telemetry instrumentation)

---

## Context

ZeroSpoils is offline-first for M3 MVP, but needs mobile-specific infrastructure for crash reporting, feature flag management, and push notifications. Firebase provides free, battle-tested solutions for these needs without requiring a backend database.

**Architecture Decision:**
- **Firebase:** Mobile tooling (crashes, feature flags, push notifications, distribution)
- **Supabase:** Backend database for Pro tier cloud sync (M6+)
- **Local DB (Hive/sqflite):** Primary storage for offline-first MVP (M3)

This integration focuses on **Firebase Spark Plan (free tier)** services only. No Firestore or Cloud Functions needed — Supabase handles backend data in M6.

---

## Goal

Integrate Firebase SDK with Flutter app for crash reporting (M3/390 observability), feature flag management (M3/130), and push notification infrastructure (M3/190). Configure Firebase project, add dependencies, implement initialization, and validate with test events.

---

## Expected behavior

### Firebase Project Setup
1. Create Firebase project at https://console.firebase.google.com/
2. Register Android app with package name `com.zerospoils.app`
3. Register iOS app with bundle ID `com.zerospoils.app`
4. Download configuration files:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
5. Add files to `.gitignore` (sensitive configuration)

### Flutter Integration
1. Add dependencies to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^3.8.1
     firebase_crashlytics: ^4.1.7
     firebase_remote_config: ^5.1.8
     firebase_messaging: ^15.1.7
     firebase_performance: ^0.10.1+8
   ```
2. Configure FlutterFire CLI: `flutterfire configure`
3. Generate `firebase_options.dart` with platform configurations

### App Initialization
1. Initialize Firebase in `main.dart` before `runApp()`:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```
2. Initialize Crashlytics:
   ```dart
   FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
   PlatformDispatcher.instance.onError = (error, stack) {
     FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
     return true;
   };
   ```
3. Initialize Remote Config with defaults:
   ```dart
   final remoteConfig = FirebaseRemoteConfig.instance;
   await remoteConfig.setConfigSettings(RemoteConfigSettings(
     fetchTimeout: const Duration(seconds: 10),
     minimumFetchInterval: const Duration(hours: 1),
   ));
   await remoteConfig.setDefaults({
     'feature_badges_enabled': true,
     'feature_zesto_enabled': true,
     'feature_receipt_ocr_enabled': false, // Pro tier, gated
   });
   await remoteConfig.fetchAndActivate();
   ```
4. Request FCM permission (iOS) and get device token

### Crashlytics Integration
1. Record custom keys for debugging context:
   ```dart
   FirebaseCrashlytics.instance.setCustomKey('user_tier', 'free');
   FirebaseCrashlytics.instance.setCustomKey('items_count', inventory.length);
   FirebaseCrashlytics.instance.setCustomKey('app_version', '1.0.0');
   ```
2. Record non-fatal errors for monitoring:
   ```dart
   try {
     await riskyOperation();
   } catch (e, stackTrace) {
     FirebaseCrashlytics.instance.recordError(e, stackTrace, reason: 'Risky operation failed');
   }
   ```

### Remote Config Integration (M3/130 Feature Flags)
1. Create `FeatureFlagService` that reads from Remote Config:
   ```dart
   class FeatureFlagService {
     final FirebaseRemoteConfig _remoteConfig;
     
     bool isBadgesEnabled() => _remoteConfig.getBool('feature_badges_enabled');
     bool isZestoEnabled() => _remoteConfig.getBool('feature_zesto_enabled');
     bool isReceiptOcrEnabled() => _remoteConfig.getBool('feature_receipt_ocr_enabled');
   }
   ```
2. Add Riverpod provider for feature flags:
   ```dart
   final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
     return FeatureFlagService(FirebaseRemoteConfig.instance);
   });
   ```
3. Gate features in UI using flags:
   ```dart
   if (ref.watch(featureFlagServiceProvider).isBadgesEnabled()) {
     // Show badges UI
   }
   ```

### FCM Integration (M3/190 Notification Foundation)
1. Request notification permission (iOS):
   ```dart
   final messaging = FirebaseMessaging.instance;
   final settings = await messaging.requestPermission(
     alert: true,
     badge: true,
     sound: true,
   );
   ```
2. Get FCM token for future server-side targeting:
   ```dart
   final token = await messaging.getToken();
   debugPrint('FCM Token: $token'); // Store for Pro tier server-side targeting
   ```
3. Handle foreground messages:
   ```dart
   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
     debugPrint('Foreground message: ${message.notification?.title}');
     // Show local notification
   });
   ```

### Performance Monitoring
1. Automatic app startup tracking (no code needed)
2. Custom traces for key flows:
   ```dart
   final trace = FirebasePerformance.instance.newTrace('inventory_load');
   await trace.start();
   await loadInventory();
   trace.stop();
   ```

### Validation
1. Test crash reporting: throw deliberate exception in debug mode
2. Verify crash appears in Firebase Console → Crashlytics within 5 minutes
3. Test Remote Config: change flag value in console, force fetch, verify app reads new value
4. Test FCM: obtain token, verify it's valid format
5. Test Performance: verify app startup trace appears in console

---

## Acceptance criteria (Definition of Done)

- [ ] Firebase project created with Android + iOS apps registered
- [ ] `google-services.json` and `GoogleService-Info.plist` added (git-ignored)
- [ ] Firebase dependencies added to `pubspec.yaml` (core, crashlytics, remote_config, messaging, performance)
- [ ] FlutterFire CLI configured, `firebase_options.dart` generated
- [ ] Firebase initialized in `main.dart` before `runApp()`
- [ ] Crashlytics initialized with Flutter error handlers
- [ ] Remote Config initialized with default feature flags (badges, zesto, receipt_ocr)
- [ ] `FeatureFlagService` created with Remote Config integration
- [ ] Riverpod provider for feature flags added to `service_locator.dart`
- [ ] FCM permission requested (iOS), token obtained and logged
- [ ] FCM foreground message handler registered
- [ ] Performance Monitoring enabled (automatic startup tracking)
- [ ] Test crash recorded and visible in Firebase Console
- [ ] Test Remote Config fetch working (manual flag change → app reads new value)
- [ ] Test FCM token obtained successfully
- [ ] Unit tests for `FeatureFlagService` (mock Remote Config, verify flag reads)
- [ ] Widget test for feature flag gating (verify UI shows/hides based on flag)
- [ ] Integration test for Firebase initialization (verify no errors on startup)
- [ ] Telemetry event on Remote Config fetch: `remote_config_fetched` { flags_changed: bool }
- [ ] Privacy: no PII sent to Firebase (device_id, email, etc.)
- [ ] Documentation: Firebase setup guide in `docs/firebase-setup.md`

---

## Out of scope

- Firestore database (using local Hive/sqflite for M3; Supabase for Pro tier in M6)
- Cloud Functions (no server-side logic needed for M3)
- Firebase Authentication (local-only MVP; Pro tier auth in M6 via Supabase)
- Firebase Storage (no cloud file uploads in M3; Supabase Storage for Pro tier receipts)
- Firebase Test Lab integration (separate issue for CI enhancement)
- Firebase App Distribution (separate issue for closed testing setup)
- Advanced Remote Config targeting (A/B testing, user segments — defer to M4)
- Custom FCM notification templates (defer to M3/190 full notification implementation)

---

## Implementation notes

### Architecture Pattern
```
Firebase (Mobile Tooling)
├── Crashlytics → FeatureFlagService (reads Remote Config)
├── Remote Config → Crash reporting + custom keys
├── FCM → Push notification infrastructure (M3/190)
└── Performance → App startup + custom traces

Local DB (Primary Storage — M3)
└── Hive/sqflite → Offline-first inventory, shopping list, badges

Supabase (Backend Sync — M6)
└── PostgreSQL → Pro tier cloud sync, multi-device support
```

### File Structure
```
app/
├── lib/
│   ├── main.dart (Firebase initialization)
│   ├── core/
│   │   └── services/
│   │       └── feature_flag_service.dart (Remote Config wrapper)
│   ├── presentation/
│   │   └── di/
│   │       └── service_locator.dart (add featureFlagServiceProvider)
│   └── firebase_options.dart (generated by FlutterFire CLI)
├── android/
│   └── app/
│       └── google-services.json (git-ignored)
└── ios/
    └── Runner/
        └── GoogleService-Info.plist (git-ignored)
```

### FlutterFire CLI Commands
```bash
# Install FlutterFire CLI globally
dart pub global activate flutterfire_cli

# Configure Firebase (interactive setup)
flutterfire configure

# Generates firebase_options.dart with platform configs
```

### Remote Config Default Values
| Flag | Default | Description |
|------|---------|-------------|
| `feature_badges_enabled` | `true` | M3/300 badge system (free tier) |
| `feature_zesto_enabled` | `true` | M3/350 Zesto mascot (free tier) |
| `feature_receipt_ocr_enabled` | `false` | M6 Pro tier feature (gated) |
| `feature_cloud_sync_enabled` | `false` | M6 Pro tier feature (gated) |
| `feature_advanced_analytics_enabled` | `false` | M6 Pro tier feature (gated) |

### Privacy Considerations
- **No PII in Crashlytics:** Never log `email`, `phone`, `full_name`, `device_id`
- **Custom keys allowed:** `user_tier`, `items_count`, `app_version`, `category`
- **FCM tokens:** Store locally only; do not send to telemetry
- **Remote Config:** Fetch frequency limited to 1 hour to reduce network traffic

### Testing Strategy
1. **Unit tests:** Mock `FirebaseRemoteConfig` to test `FeatureFlagService`
2. **Widget tests:** Override `featureFlagServiceProvider` to test feature gating
3. **Integration tests:** Verify Firebase initializes without errors on app startup
4. **Manual tests:** Force crash, change Remote Config flag, obtain FCM token

### Known Limitations
- **Crashlytics delay:** Crashes appear in console within 5 minutes (not real-time)
- **Remote Config cache:** Default 1-hour minimum fetch interval (configurable)
- **FCM iOS permission:** Requires user acceptance; handle denial gracefully
- **Performance traces:** Custom traces only; no automatic network monitoring for non-Firebase requests

---

## Test plan

### Automated Tests

**Unit tests: `test/unit/core/services/feature_flag_service_test.dart`**
- Test `isBadgesEnabled()` reads correct Remote Config key
- Test `isZestoEnabled()` reads correct Remote Config key
- Test `isReceiptOcrEnabled()` reads correct Remote Config key
- Test default values when Remote Config not initialized
- Mock `FirebaseRemoteConfig` to avoid network calls

**Widget tests: `test/widget/screens/progress_screen_feature_flag_test.dart`**
- Test badge section shows when `feature_badges_enabled = true`
- Test badge section hidden when `feature_badges_enabled = false`
- Override `featureFlagServiceProvider` with mock service

**Integration tests: `test/integration/firebase_initialization_test.dart`**
- Test app launches without errors after Firebase initialization
- Test Crashlytics handler registered (verify `FlutterError.onError` set)
- Test Remote Config fetched and activated on startup

### Manual Tests

1. **Firebase Project Setup**
   - Create project in Firebase Console
   - Register Android app (package: `com.zerospoils.app`)
   - Register iOS app (bundle ID: `com.zerospoils.app`)
   - Download `google-services.json` and `GoogleService-Info.plist`
   - Verify files in correct directories

2. **Crashlytics Validation**
   - Run app in debug mode
   - Trigger deliberate exception (add test button)
   - Wait 5 minutes
   - Verify crash report appears in Firebase Console → Crashlytics
   - Verify custom keys visible (user_tier, items_count, app_version)

3. **Remote Config Validation**
   - Run app, verify default flags loaded
   - Change `feature_badges_enabled` to `false` in Firebase Console
   - Force fetch in app (add debug button or restart)
   - Verify badge section disappears from Progress screen

4. **FCM Token Validation**
   - Run app on iOS, grant notification permission
   - Verify FCM token printed to console
   - Run app on Android, verify token obtained (permission auto-granted)
   - Copy token, verify format: 152+ character alphanumeric string

5. **Performance Monitoring Validation**
   - Run app on physical device
   - Wait 15 minutes for data upload
   - Check Firebase Console → Performance
   - Verify "App start" trace appears with duration

6. **Feature Flag Gating (End-to-End)**
   - Set `feature_receipt_ocr_enabled = false` (default)
   - Verify no receipt OCR option in Settings
   - Change flag to `true` in console
   - Force fetch, verify receipt OCR option appears

---

## Dependencies

### Prerequisite Issues
- **090:** Flutter app skeleton (app structure must exist)
- **130:** Feature flags framework planning (this implements it)
- **250:** Telemetry instrumentation (Remote Config fetch events)

### Dependent Issues (Unblocks)
- **M3/390:** Observability (leverages Crashlytics for crash reporting)
- **M3/190:** Notification scheduling (leverages FCM for push notifications)
- **M3/130:** Feature flags (implements Remote Config-based feature gating)
- **M4:** Performance optimizations (uses Performance Monitoring traces)
- **M6:** Pro tier features (uses Remote Config to gate cloud sync, receipt OCR)

### External Dependencies
- Firebase project created (manual setup, 15 minutes)
- FlutterFire CLI installed (`dart pub global activate flutterfire_cli`)
- Google account with Firebase Console access

---

## Implementation sequence

1. **Firebase Project Setup (Manual — 15 min)**
   - Create project in Firebase Console
   - Register Android + iOS apps
   - Download configuration files

2. **Add Dependencies (5 min)**
   - Update `pubspec.yaml` with Firebase packages
   - Run `flutter pub get`

3. **FlutterFire CLI Configuration (10 min)**
   - Install CLI: `dart pub global activate flutterfire_cli`
   - Run `flutterfire configure` (interactive setup)
   - Generates `firebase_options.dart`

4. **Initialize Firebase (20 min)**
   - Update `main.dart` with Firebase initialization
   - Add Crashlytics error handlers
   - Initialize Remote Config with defaults
   - Request FCM permission (iOS)

5. **Create FeatureFlagService (30 min)**
   - Create `feature_flag_service.dart`
   - Add Riverpod provider in `service_locator.dart`
   - Wire feature flags to Progress screen (badges)

6. **Test & Validate (45 min)**
   - Write unit tests (feature flag service)
   - Write widget tests (feature flag gating)
   - Manual crash test → verify in console
   - Manual Remote Config test → change flag, verify update
   - Manual FCM test → obtain token, verify format

**Total Estimated Time:** 2.5-3 hours

---

## Related issues

- **M3/130:** Feature flags framework (this issue implements it)
- **M3/190:** Notification scheduling (depends on FCM setup)
- **M3/250:** Telemetry instrumentation (Remote Config fetch event)
- **M3/390:** Observability (depends on Crashlytics)
- **M6/470:** Household accounts (uses Remote Config for Pro tier gating)
- **M6/520:** Personalized waste tips (uses Remote Config for opt-in toggle)

---

## Notes

### Why Firebase Spark Plan (Free)?
- **No credit card required**
- **Unlimited:** Crashlytics, Remote Config, FCM, Performance Monitoring
- **Free tier sufficient** for testing + small-scale production (1K-10K users)
- **No vendor lock-in:** Remote Config flags can be migrated to Supabase config table later if needed

### Why Not Use Firebase for Database?
- **Firestore is NoSQL:** Complex queries require Supabase's PostgreSQL
- **Offline-first MVP:** Local Hive/sqflite sufficient for M3
- **Pro tier sync:** Supabase better for relational data (inventory, shopping list, badges)
- **Cost:** Supabase free tier more generous for database storage

### Migration Path to Supabase (M6)
When Pro tier adds cloud sync:
1. Keep Firebase for mobile tooling (Crashlytics, FCM, Remote Config)
2. Add Supabase for backend database (inventory sync, user accounts, receipt storage)
3. Use Remote Config flags to gate Pro features (e.g., `feature_cloud_sync_enabled`)
4. Store Supabase auth tokens locally, sync on Pro tier upgrade

**Hybrid Architecture (M6+):**
```
Firebase: Mobile observability + feature flags + push notifications
Supabase: Backend database + file storage + auth (Pro tier only)
Local DB: Primary storage (offline-first for free + Pro users)
```
