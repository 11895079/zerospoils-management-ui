# Closed Testing Checklist — Firebase App Distribution

## Overview

This checklist covers closed testing using **Firebase App Distribution** instead of Google Play closed tracks. It is intended for fast internal/beta validation with invited testers.

**Use this when:**
- You want quick tester access without Play Store review friction.
- You need frequent QA/beta drops.
- You want pre-Play feedback before broader rollout.

**Do not use this alone for Play-specific compliance testing** (install/update flow, Play Integrity behavior, listing metadata, Play policy flow). For those, also run the Play track checklist.

---

## 0) Getting Started (First-Time Firebase Setup)

**⚠️ Start here if this is your first time using Firebase.**

### 0.1 Create Firebase Project

- [ ] Visit [Firebase Console](https://console.firebase.google.com/)
- [ ] Click **"Add project"** or **"Create a project"**
- [ ] Enter project name: `zerospoils` (or your preferred name)
- [ ] Choose whether to enable Google Analytics (optional, recommended for later)
- [ ] Wait for project creation (~30 seconds)

### 0.2 Register Android App

- [ ] In Firebase Console, click **"Add app"** → Select Android icon
- [ ] Enter Android package name: `com.zerospoils.zerospoils`
  - ⚠️ **CRITICAL**: This must match `applicationId` in `app/android/app/build.gradle.kts`
  - ⚠️ Cannot be changed later without creating new app registration
- [ ] (Optional) Enter app nickname: "ZeroSpoils Android"
- [ ] (Optional) Debug signing SHA-1: Skip for now (not needed for Firebase Distribution)
- [ ] Click **"Register app"**

### 0.3 Download google-services.json

- [ ] After app registration, click **"Download google-services.json"**
- [ ] Save file to: `app/android/app/google-services.json`
- [ ] Verify file location is correct (must be in `android/app/` directory, not `android/`)
- [ ] Commit this file to git (safe to commit, contains no secrets)

### 0.4 Find Your Firebase App ID

You'll need this for CLI distribution commands.

- [ ] In Firebase Console → Project settings (gear icon) → Scroll to "Your apps"
- [ ] Find your Android app entry
- [ ] Copy the **App ID** (format: `1:123456789:android:abc123def456...`)
- [ ] Save this ID for later (you'll use it in Step 4.2)

**Example App ID**: `1:123456789012:android:abc123def456ghi789`

### 0.5 Enable Firebase Services

- [ ] In Firebase Console left sidebar → **Crashlytics** → Enable
- [ ] In Firebase Console left sidebar → **Remote Config** → Get started
- [ ] (Optional) In Firebase Console → **Authentication** → Get started → Enable Anonymous auth

### 0.6 Verify google-services.json Configuration

- [ ] Open `app/android/app/google-services.json` in text editor
- [ ] Verify `package_name` matches: `"com.zerospoils.zerospoils"`
- [ ] Verify `project_id` matches your Firebase project name
- [ ] Note the `mobilesdk_app_id` (same as App ID from Step 0.4)

**✅ Setup complete!** Continue to Section 1 (Prerequisites).

---

## 1) Prerequisites

**✅ If you completed Section 0 (Getting Started), these should all be done.**

- [ ] Firebase project exists and app is registered:
  - Android package: `com.zerospoils.zerospoils`
  - iOS bundle (if applicable): `com.zerospoils.zerospoils`
- [ ] `google-services.json` (Android) is in `app/android/app/google-services.json`
- [ ] Firebase Crashlytics and Remote Config are enabled
- [ ] Firebase App ID saved somewhere (needed for CLI commands)
- [ ] Testers have Google accounts
- [ ] You have Firebase project permissions (Editor/Admin)
- [ ] **⚠️ CRITICAL**: Release signing configured (merge PR #56 first!)
  - See `docs/ANDROID_SIGNING_GUIDE.md` for keystore setup
  - Without this, every build has different signature → testers must uninstall → lose data

---

## 2) Firebase Console Setup

### 2.1 Enable App Distribution

- [ ] Open Firebase Console → **App Distribution** (left sidebar, under "Release & Monitor")
- [ ] Click **"Get started"** if first time
- [ ] Enable App Distribution for Android app
- [ ] (Optional) Enable for iOS app if supporting iOS

### 2.2 Create Tester Groups (Two-Channel Strategy)

**Your two-channel distribution strategy:**

| Channel | Group Name | Purpose | Who Gets Access | Release Cadence |
|---------|-----------|---------|-----------------|-----------------|
| **🔥 Nightly/Cutting-Edge** | `internal-qa` | Bleeding-edge builds for immediate feedback | You + org trusted testers (2-5 people) | Daily or per-PR merge |
| **✅ Stable Beta** | `beta-closed` | Stable builds for external testing | External beta testers (10-50 people) | Weekly or milestone releases (M4, M5, etc.) |

**Setup both groups:**

- [ ] In Firebase Console → App Distribution → **"Testers & Groups"** tab
- [ ] Click **"Add group"**
- [ ] Create first group:
  - Name: `internal-qa`
  - Description: "Internal trusted testers for cutting-edge builds"
  - Add tester emails (your email + org members)
- [ ] Create second group:
  - Name: `beta-closed`
  - Description: "External beta testers for stable releases"
  - Add tester emails (external beta users)
- [ ] Verify both groups appear in groups list
- [ ] Confirm invitation emails are sent to all testers

**Group Management Tips:**
- Keep `internal-qa` small (2-5 trusted testers who can handle bugs)
- Grow `beta-closed` gradually (start with 10, expand to 50+)
- Remove inactive testers monthly
- Use group names consistently in CLI commands

### 2.3 Set Up Remote Config (Required for Kill-Switch Testing)

**Remote Config allows you to toggle features without rebuilding the app.**

- [ ] In Firebase Console → **Remote Config** (left sidebar)
- [ ] Click **"Create configuration"** (if first time)
- [ ] Add these baseline parameters:

**Parameter 1: Master Kill-Switch**
- [ ] Click **"Add parameter"**
- [ ] Parameter key: `feature_flags_enabled`
- [ ] Default value: `true` (Boolean type)
- [ ] Description: "Master kill-switch: disables all non-essential features"

**Parameter 2: Receipt OCR Feature Flag**
- [ ] Click **"Add parameter"**
- [ ] Parameter key: `receipt_ocr_enabled`
- [ ] Default value: `false` (Boolean type)
- [ ] Description: "Enable receipt OCR feature (Pro tier)"

**Parameter 3: Batch Capture Feature Flag**
- [ ] Click **"Add parameter"**
- [ ] Parameter key: `batch_capture_enabled`
- [ ] Default value: `false` (Boolean type)
- [ ] Description: "Enable batch item detection (Pro tier)"

- [ ] Click **"Publish changes"** at top
- [ ] Confirm publishing to all apps

**Testing Remote Config:**
- Toggle `feature_flags_enabled` to `false` → Publish → Restart app → All Pro features should disable
- Toggle back to `true` → Publish → Restart app → Features re-enable

### 2.4 Optional Integrations

- [ ] Link Crashlytics to release monitoring workflow
  - Firebase Console → Crashlytics → Settings → Enable "New issue alerts"
  - Add your email for crash notifications
- [ ] Add release notes template for tester guidance:
  - Example: "M4/370: Auth hardening + kill-switch validation\n\nWhat to test:\n- Sign in/out flow\n- Pro feature gating\n- Settings toggles"

---

## 3) Build Artifacts (Android)

### 3.1 Build Command

- [ ] Build release APK (or AAB if preferred for your flow):

```bash
cd app
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

### 3.2 Validate Output

- [ ] Artifact exists: `app/build/app/outputs/flutter-apk/app-release.apk`
- [ ] Symbols exist: `app/debug-info/*.symbols`
- [ ] Build installs on at least one physical Android device.

### 3.3 Symbol Upload (Recommended)

- [ ] Upload symbol files for deobfuscation in crash reporting pipeline.
- [ ] Verify at least one test crash can be symbolicated (non-production validation).

---

## 4) Upload to Firebase App Distribution

### 4.0 How the Build File Gets to Firebase (Android)

You have two supported upload paths:

- [ ] **Path A (recommended): Firebase CLI upload from local file**
  - No manual "move" step required.
  - The CLI command reads your local APK at `app/build/app/outputs/flutter-apk/app-release.apk` and uploads it directly to Firebase.

- [ ] **Path B: Firebase Console manual upload**
  1. Open Firebase Console → App Distribution → your Android app.
  2. Click **Distribute** (or **Get started** on first use).
  3. Drag and drop `app-release.apk` (or browse and select it from `app/build/app/outputs/flutter-apk/`).
  4. Select groups (`internal-qa` or `beta-closed`).
  5. Add release notes.
  6. Click **Distribute**.


### 4.1 Install/Use Firebase CLI

- [ ] Firebase CLI installed and authenticated:

```bash
# Install Firebase CLI (if not already installed)
npm install -g firebase-tools

# Login
firebase login

# Verify authentication and list projects
firebase projects:list
# Should show your zerospoils project
```

### 4.2 Upload Commands (Channel-Specific)

**Replace `<FIREBASE_ANDROID_APP_ID>` with your App ID from Section 0.4**

**Example App ID**: `1:123456789012:android:abc123def456ghi789`

#### 🔥 Nightly/Cutting-Edge (Internal QA Only)

Use this for daily builds or per-PR merges that need immediate feedback:

```bash
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --groups "internal-qa" \
  --release-notes "Nightly build $(date +%Y-%m-%d): feature/m6-465 merged - seamless batch capture POC"
```

**When to use**:
- After merging feature branches
- Daily automated builds
- Quick bug fixes for internal validation
- Experimental features not ready for external testing

#### ✅ Stable Beta (External Beta Testers)

Use this for weekly or milestone releases that are stable:

```bash
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --groups "beta-closed" \
  --release-notes "Beta v1.2.0 (M4 Complete)

✅ Auth hardening + secure token storage
✅ Kill-switch validation via Remote Config
✅ Pro tier gating with Firebase custom claims
🧪 Test: Sign in/out, Pro features, Settings toggles"
```

**When to use**:
- After milestone completion (M4, M5, etc.)
- Weekly stable releases (every Friday)
- Release candidates before Play Store submission
- Builds that passed internal QA smoke tests

#### 🚀 Both Channels Simultaneously (Release Candidates)

Use this when promoting a nightly build to stable after 48-hour bake time:

```bash
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --groups "internal-qa,beta-closed" \
  --release-notes "v1.2.0 Release Candidate - 48hr bake complete, promoting to beta"
```

### 4.3 Upload Command (Direct Testers — Emergency Only)

Use this to bypass groups and send to specific individuals:

```bash
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --testers "founder@example.com,lead-tester@example.com" \
  --release-notes "Hotfix: P0 crash in auth flow"
```

**When to use**:
- Emergency hotfixes that need immediate validation
- Testing with specific users who aren't in groups yet
- One-off builds for troubleshooting specific devices

---

## 5) Tester Onboarding Flow

- [ ] Tester receives invitation email from Firebase App Distribution.
- [ ] Tester accepts invite and installs Firebase App Tester app (if prompted).
- [ ] Tester can download and install target build.
- [ ] Tester confirms app launches successfully.
- [ ] Tester confirms update flow works when a newer build is published.

---

## 6) Functional Validation for Closed Testing

### 6.1 Auth + Entitlements

- [ ] Launch app and verify Firebase bootstrap completes.
- [ ] Verify anonymous auth/session persistence across restart.
- [ ] Validate Pro entitlement behavior via custom claims (`pro_tier`).

### 6.2 Feature Flags + Kill-Switch

- [ ] Confirm baseline feature flags resolve correctly.
- [ ] Toggle `feature_flags_enabled` in Remote Config and validate app behavior after restart.
- [ ] Toggle feature-specific flags (e.g., `receipt_ocr_enabled`) and verify only targeted feature changes.

### 6.3 Stability + Observability

- [ ] Verify Crashlytics receives non-debug crash events.
- [ ] Validate no critical startup regressions in release build.
- [ ] Confirm logs/telemetry for critical flows are present.

---

## 7) Release Cadence & Governance (Two-Channel Strategy)

### 7.1 Channel Policies

**🔥 Internal QA (Nightly/Cutting-Edge)**

- [ ] **Distribution cadence**: Daily or per-PR merge (no fixed schedule)
- [ ] **Quality gate**: Code compiles + passes CI tests
- [ ] **Release notes**: Brief commit message summary
- [ ] **Rollback policy**: If P0 crash, halt distribution immediately
- [ ] **Retention**: Keep last 5 builds only, retire older builds

**✅ Beta Closed (Stable)**

- [ ] **Distribution cadence**: Weekly (every Friday) or milestone releases (M4, M5, M6)
- [ ] **Quality gate**: 48-hour bake time in internal-qa + no P0/P1 defects
- [ ] **Release notes**: Detailed with "What's New" + "What to Test" sections
- [ ] **Rollback policy**: If >10% crash rate, halt + revert to previous stable
- [ ] **Retention**: Keep last 10 builds for rollback capability

### 7.2 Promotion Workflow (Nightly → Stable)

**Standard promotion path:**

```
  Day 1: Merge PR → Build → Distribute to internal-qa
         ↓
  Day 2-3: Internal QA testing (48-hour bake)
         ↓ (If stable)
  Day 3: Promote to beta-closed
         ↓
  Day 4-10: External beta feedback collection
         ↓ (If no regressions)
  Week 2: Tag as release candidate for Play Store
```

**Checklist before promoting nightly → stable:**

- [ ] Build has been in `internal-qa` for ≥48 hours
- [ ] No P0 defects reported
- [ ] No P1 defects reported (or all P1s are known + documented)
- [ ] Crashlytics crash-free rate ≥99%
- [ ] At least 2 internal testers tested + approved
- [ ] Release notes updated with user-facing changes
- [ ] Known issues documented in release notes

### 7.3 Version Tagging Convention

**Use semantic versioning for stable releases:**

```bash
# Nightly builds (internal-qa only)
git tag nightly-$(date +%Y%m%d)-${COMMIT_SHORT_SHA}
# Example: nightly-20260307-a1b2c3d

# Stable beta releases (beta-closed)
git tag beta-v1.2.0-m4
# Example: beta-v1.2.0-m4 (version 1.2.0, milestone M4)

# Release candidates (both channels)
git tag rc-v1.2.0
# Example: rc-v1.2.0 (preparing for Play Store)
```

### 7.4 Build Changelog

- [ ] Maintain changelog file: `docs/CHANGELOG_FIREBASE.md`
- [ ] Format:
  ```markdown
  ## [Nightly 2026-03-07] - internal-qa
  - Added: Seamless batch capture POC (M6/465)
  - Fixed: Auth token refresh race condition
  - Known issues: OCR accuracy low in dim lighting
  
  ## [Beta v1.2.0-m4] - 2026-03-05 - beta-closed
  - ✅ M4 Complete: Auth hardening, secure storage, kill-switch
  - Test: Sign in/out, Pro features, Settings toggles
  ```
- [ ] Link build artifacts to issue IDs/PRs for traceability

### 7.5 Retirement Policy

- [ ] **Internal QA**: Delete builds older than 7 days (keep last 5 only)
- [ ] **Beta Closed**: Delete builds older than 30 days (keep last 10 for rollback)
- [ ] Clean up in Firebase Console → App Distribution → Releases → (three dots) → Delete

---

## 8) Security & Access Controls

- [ ] Restrict distribution access to approved tester groups only.
- [ ] Remove inactive testers monthly.
- [ ] Do not embed secrets in app binary.
- [ ] Validate secure token storage remains enabled in release builds.

---

## 9) Exit Criteria (Firebase Distribution Phase)

Promote from Firebase-only closed testing to Play track testing when:

- [ ] Crash-free rate is acceptable for beta target.
- [ ] No P0/P1 defects open.
- [ ] Auth + entitlement gating is stable across test cohort.
- [ ] Kill-switch has been verified at least once in a real tester build.
- [ ] Team is ready for Play policy/store-flow validation.

---

## 10) Known Limits of Firebase App Distribution

- Firebase App Distribution is excellent for pre-release QA/beta velocity.
- It does **not** replace Play Console closed-track validation.
- It does **not** require DUNS number.
- It does **not** by itself validate Play Store install/update/policy flows.

---

## 11) Troubleshooting (Common First-Time Issues)

### 11.1 "Package name mismatch" Error

**Symptom:** Tester installs APK but sees "App not installed" or "Package conflict"

**Cause:** `google-services.json` package name doesn't match APK package name

**Solution:**
```bash
# Check APK package name
aapt dump badging app/build/app/outputs/flutter-apk/app-release.apk | grep package
# Should show: name='com.zerospoils.zerospoils'

# Check google-services.json
cat app/android/app/google-services.json | grep package_name
# Should show: "package_name": "com.zerospoils.zerospoils"

# If mismatch: Re-download google-services.json from Firebase Console with correct package name
```

### 11.2 "Firebase App ID not found" (CLI Upload Fails)

**Symptom:** `firebase appdistribution:distribute` fails with "App not found"

**Cause:** Incorrect App ID or app not registered in Firebase

**Solution:**
1. Get correct App ID from Firebase Console → Project settings → Your apps
2. Format: `1:123456789012:android:abc123def456ghi789`
3. Verify app is registered (should see "ZeroSpoils Android" in apps list)
4. If missing, register app (see Section 0.2)

### 11.3 "Authentication required" (Firebase CLI)

**Symptom:** CLI commands fail with "User not authenticated"

**Solution:**
```bash
# Logout and re-login
firebase logout
firebase login

# Verify authentication
firebase projects:list
# Should show your zerospoils project

# If still failing, try login with different browser
firebase login --reauth
```

### 11.4 "Tester can't install APK"

**Symptom:** Tester receives invitation, downloads APK, but can't install

**Common causes & solutions:**

**Cause 1: "Install unknown apps" permission not granted**
- Solution: On tester's phone → Settings → Security → "Install unknown apps" → Enable for Chrome/Files/Gmail (wherever APK was downloaded)

**Cause 2: Different signing key between old and new build**
- Solution: Follow `docs/ANDROID_SIGNING_GUIDE.md` to set up release signing (PR #56)
- Old build with debug key → New build with release key = must uninstall first
- All future builds with same release key = smooth updates

**Cause 3: Tester already has app installed with different signature**
- Solution: Tester must uninstall old app first (backup data if needed)

### 11.5 "No crash reports in Crashlytics"

**Symptom:** App crashes but Crashlytics shows no data

**Causes:**
1. Crashlytics not enabled in Firebase Console
2. Release build not initialized properly
3. Test crashes in debug mode (Crashlytics disabled)

**Solution:**
```dart
// Verify Crashlytics initialization (in bootstrap)
await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);

// Test crash in release build
if (!kDebugMode) {
  FirebaseCrashlytics.instance.crash(); // Force crash for testing
}
```

```bash
# Build release APK
flutter build apk --release

# Install and test
adb install -r app/build/app/outputs/flutter-apk/app-release.apk

# Force app to crash, then check Crashlytics dashboard in 5 min
```

### 11.6 "Remote Config values not updating"

**Symptom:** Changed Remote Config in console but app still uses old values

**Cause:** App caches Remote Config values, requires restart or fetch

**Solution:**
```dart
// Force fetch in app (for testing only)
await remoteConfig.setConfigSettings(
  RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 10),
    minimumFetchInterval: Duration.zero, // Testing only! Use 12 hours in production
  ),
);
await remoteConfig.fetchAndActivate();
```

**Or restart app:**
- Force close app completely
- Reopen app
- Wait 10 seconds for fetch
- Check if new values applied

### 11.7 "Build fails with signing error"

**Symptom:** `flutter build apk --release` fails with keystore errors

**Common errors:**

**Error: "Keystore file not found"**
```bash
# Check key.properties path is absolute
cat app/android/key.properties
# storeFile should be: /Users/yourname/zerospoils-release-key.jks (absolute path)
# NOT: ../zerospoils-release-key.jks (relative path)

# Verify keystore exists
ls -la ~/zerospoils-release-key.jks
```

**Error: "Wrong password"**
```bash
# Test keystore password
keytool -list -v -keystore ~/zerospoils-release-key.jks
# Enter password → should list certificate details

# If forgotten, must generate new keystore (cannot recover)
```

**Error: "key.properties not found"**
```bash
# Check file exists
ls -la app/android/key.properties

# If missing, create from template
cp app/android/key.properties.template app/android/key.properties
# Edit with your credentials
```

### 11.8 "Symbols not uploading for crash deobfuscation"

**Symptom:** Crashes show obfuscated stack traces (e.g., `a.b.c()`)

**Cause:** Debug symbols not uploaded to Firebase

**Solution:**
```bash
# Build with symbols
flutter build apk --release --obfuscate --split-debug-info=./debug-info

# Upload symbols (if using Firebase Crashlytics Gradle plugin)
# Symbols auto-upload during build

# Manual upload (if auto-upload fails)
# Upload debug-info/*.symbols files via Firebase Console
# Crashlytics → Settings → Upload mapping files
```

### 11.9 "Firebase CLI hangs on 'Uploading APK'"

**Symptom:** CLI shows "Uploading..." but never completes

**Causes:**
1. Large APK size (>100MB)
2. Slow internet connection
3. Firebase API timeout

**Solutions:**
```bash
# 1. Check APK size
ls -lh app/build/app/outputs/flutter-apk/app-release.apk
# If >100MB, reduce by removing unused resources or using App Bundle

# 2. Try split APKs (reduces size)
flutter build apk --release --split-per-abi
# Uploads 3 smaller APKs instead of 1 universal APK

# 3. Increase timeout
firebase appdistribution:distribute app-release.apk \
  --app <APP_ID> \
  --groups "internal-qa" \
  --timeout 600s  # 10-minute timeout
```

### 11.10 "Tester groups not showing up in CLI"

**Symptom:** `--groups "internal-qa"` fails with "Group not found"

**Cause:** Group name mismatch or group not created

**Solution:**
```bash
# List all groups
firebase appdistribution:group:list --app <FIREBASE_APP_ID>

# Should show:
# internal-qa
# beta-closed

# If missing, create in Firebase Console → App Distribution → Testers & Groups
```

---

## iOS Add-On Checklist (Firebase App Distribution)

Use this add-on when you want the same Firebase closed-testing flow on iOS.

### A) Platform Requirements

- [ ] Build machine is macOS (iOS release builds are not supported on Windows/Linux).
- [ ] Apple Developer Program membership is active.
- [ ] Bundle ID matches Firebase app registration: `com.zerospoils.zerospoils`.
- [ ] iOS app is registered in Firebase project (same project as Android).
- [ ] `GoogleService-Info.plist` exists at `app/ios/Runner/GoogleService-Info.plist`.

### B) Signing & Provisioning (Xcode)

- [ ] Open `app/ios/Runner.xcworkspace` in Xcode.
- [ ] Select Runner target → Signing & Capabilities.
- [ ] Team selected correctly.
- [ ] Automatic signing enabled (or manual profiles configured).
- [ ] Distribution certificate valid (Apple Distribution).
- [ ] Provisioning profile supports Ad Hoc / internal distribution as needed.

### C) Build Artifact (IPA)

- [ ] Build iOS release artifact:

```bash
cd app
flutter build ipa --release
```

- [ ] Confirm IPA exists under:
  `app/build/ios/ipa/Runner.ipa`

### D) Upload to Firebase App Distribution

- [ ] Choose one upload path for iOS:
  - **Path A (recommended):** CLI upload of `app/build/ios/ipa/Runner.ipa`.
  - **Path B:** Firebase Console manual upload (App Distribution → iOS app → Distribute → select `Runner.ipa`).

- [ ] Confirm Firebase CLI login:

```bash
firebase login
firebase projects:list
```

- [ ] Distribute to internal iOS testers:

```bash
firebase appdistribution:distribute app/build/ios/ipa/Runner.ipa \
  --app <FIREBASE_IOS_APP_ID> \
  --groups "internal-qa" \
  --release-notes "iOS nightly: auth + feature flag validation"
```

- [ ] Promote stable iOS beta build:

```bash
firebase appdistribution:distribute app/build/ios/ipa/Runner.ipa \
  --app <FIREBASE_IOS_APP_ID> \
  --groups "beta-closed" \
  --release-notes "iOS beta: stable milestone candidate"
```

### E) Tester Onboarding (iOS)

- [ ] Testers accept Firebase invitation email.
- [ ] Testers install Firebase App Tester app (if prompted).
- [ ] Testers trust the distribution profile/device management certificate when prompted.
- [ ] Testers install build and launch app successfully.
- [ ] Testers confirm update flow works from one Firebase iOS build to the next.

### F) iOS Validation Targets

- [ ] Firebase bootstrap succeeds on first launch.
- [ ] Auth/session persistence works across app restart.
- [ ] Remote Config fetches and kill-switch behavior matches Android.
- [ ] Crashlytics receives a non-debug crash event from iOS build.
- [ ] No critical startup or sign-in regressions.

### G) Common iOS Failure Points

- [ ] Bundle ID mismatch between Xcode and Firebase app registration.
- [ ] Expired Apple Distribution certificate.
- [ ] Provisioning profile missing required devices/capabilities.
- [ ] Wrong Firebase app ID used in CLI command (`--app`).
- [ ] Missing `GoogleService-Info.plist` in Runner target.

---

## 12) Getting Help

**First-time setup issues?**
- Review Section 0 (Getting Started) step-by-step
- Check Section 11 (Troubleshooting) for your specific error
- Verify all prerequisites in Section 1 are complete

**Firebase Console resources:**
- [Firebase App Distribution docs](https://firebase.google.com/docs/app-distribution)
- [Firebase CLI reference](https://firebase.google.com/docs/cli)
- [Crashlytics setup guide](https://firebase.google.com/docs/crashlytics)

**Android signing issues:**
- See `docs/ANDROID_SIGNING_GUIDE.md`
- Merge PR #56 before starting

**Data backup/restore:**
- See `docs/DATA_BACKUP_GUIDE.md` (built-in feature)
- See `docs/MANUAL_DATA_BACKUP.md` (ADB method)

---

## Quick Start (Minimal Path)

**For first-time Firebase users:**
1. Complete Section 0 (Getting Started) — 20 min
2. Merge PR #56 and set up release signing — 15 min
3. Continue with steps below

**For existing Firebase setups:**
1. Ensure release signing configured (PR #56)
2. Build release APK with obfuscation + symbols
3. Upload via Firebase CLI to `internal-qa` group
4. Confirm tester install + app startup
5. Validate auth, Pro gating, and kill-switch behavior
6. Monitor Crashlytics for 24–72 hours
7. Iterate fixes quickly via new distributions
8. Promote stable builds to `beta-closed` after 48-hour bake

**Two-channel workflow:**
- **Daily**: Build → `internal-qa` (nightly/cutting-edge)
- **48hr bake**: Monitor crashes + internal feedback
- **Weekly**: Promote → `beta-closed` (stable beta)
- **External feedback**: 7-10 days of beta testing
- **Release**: Tag as RC for Play Store

---

## Related Documents

- **[PR #56: Android Release Signing](https://github.com/11895079/zerospoils/pull/56)** — ⚠️ **Merge before testing!**
- [Closed Testing (Play Track)](closed-testing-checklist.md) — For Play Store validation
- [Android Signing Guide](ANDROID_SIGNING_GUIDE.md) — Keystore setup (from PR #56)
- [Data Backup Guide](DATA_BACKUP_GUIDE.md) — Built-in backup feature
- [Manual Data Backup](MANUAL_DATA_BACKUP.md) — ADB method for data rescue
- [Play Integrity Setup](play-integrity-setup.md) — Anti-tamper protection
- [M4/370 Work Item](../planning/milestones/M4/370-closed-testing-backend-security-hardening-firebase-supabase.md) — Backend security
