# Closed Testing Release Checklist

## Overview

This checklist ensures the ZeroSpoils app is ready for closed alpha/beta testing on Google Play Console. Complete all items before uploading the first release to the closed testing track.

**Target Milestone**: M4 (Closed Testing)  
**Prerequisites**: M1-M3 features complete, Firebase + Supabase configured, Android release hardening validated

---

## 1. Firebase Configuration

### 1.1 Firebase Project Setup

- [ ] Firebase project created for production (`zerospoils-prod` or similar)
- [ ] Android app registered in Firebase Console
  - Package name: `com.zerospoils.zerospoils`
  - SHA-1 fingerprint: Upload signing key from Play Console
- [ ] iOS app registered in Firebase Console (if applicable)
  - Bundle ID: `com.zerospoils.zerospoils`
  - APNs key configured for push notifications

### 1.2 Firebase Services Enabled

- [ ] **Firebase Auth** enabled
  - Anonymous sign-in enabled
  - Custom claims configured for Pro tier (`pro_tier: true/false`)
- [ ] **Crashlytics** enabled
  - Data retention set to 90 days
  - Test crash report verified in console
- [ ] **Remote Config** enabled
  - Default values set for feature flags
  - Kill-switch parameters configured (see Section 3)
- [ ] **Firebase Messaging** enabled (optional for push notifications)

### 1.3 Firebase Team Access

- [ ] Team members added with appropriate roles:
  - Admin: Full project access
  - Editor: Release management, analytics
  - Viewer: Read-only dashboard access
- [ ] Service account created for backend (if server-side verification needed)

---

## 2. Google Play Console Setup

### 2.1 App Creation

- [ ] App created in Play Console
  - App name: "ZeroSpoils" (or approved variant)
  - Default language: English (US)
  - App type: App
  - Free or Paid: Free (with in-app purchases for Pro tier)

### 2.2 App Signing

- [ ] **Google Play App Signing** enabled (recommended)
  - Upload key generated and registered
  - SHA-1/SHA-256 fingerprints copied to Firebase Console
- [ ] **Alternative**: Manual signing key management configured

### 2.3 Store Listing (Draft)

- [ ] Short description (80 chars max)
- [ ] Full description (4000 chars max)
- [ ] App icon (512x512 PNG)
- [ ] Feature graphic (1024x500 PNG)
- [ ] Screenshots (at least 2):
  - Phone: 1920x1080 or 2560x1440
  - Tablet: 2048x1536 or 3840x2160 (optional)
- [ ] Privacy policy URL uploaded
- [ ] App category selected: "Lifestyle" or "Food & Drink"
- [ ] Content rating questionnaire completed (IARC)

### 2.4 Closed Testing Track Setup

- [ ] **Internal testing track** created (for team testing)
  - Testers list: Add team member emails
  - Opt-in URL shared with team
- [ ] **Closed testing track** created (for external beta)
  - Testers list: Add initial 20-100 beta users
  - Feedback channel configured (email or Google Group)
- [ ] **Release notes** template prepared for updates

---

## 3. Kill-Switch Configuration (Remote Config)

### 3.1 Feature Flag Parameters

Configure these parameters in Firebase Remote Config:

| Parameter | Type | Default Value | Purpose |
|-----------|------|---------------|---------|
| `feature_flags_enabled` | Boolean | `true` | Master kill-switch for all feature flags |
| `receipt_ocr_enabled` | Boolean | `true` | Enable/disable receipt OCR (Pro feature) |
| `batch_photo_capture_enabled` | Boolean | `true` | Enable/disable batch photo capture (Pro) |
| `cloud_sync_enabled` | Boolean | `true` | Enable/disable cloud sync (Pro) |
| `cloud_analytics_export_enabled` | Boolean | `true` | Enable/disable analytics export (Pro) |
| `notifications_enabled` | Boolean | `true` | Enable/disable expiry notifications |
| `shopping_list_enabled` | Boolean | `true` | Enable/disable shopping list feature |

### 3.2 Kill-Switch Testing

- [ ] Toggle `feature_flags_enabled` to `false` in Firebase Console
- [ ] Force-refresh Remote Config in app (restart app)
- [ ] Verify all feature flags resolve to `false` (disabled state)
- [ ] Verify app remains functional in "safe mode" (core inventory only)
- [ ] Reset `feature_flags_enabled` to `true`

### 3.3 Conditional Targeting (Optional)

- [ ] Create Remote Config conditions for staged rollouts:
  - **Condition**: `app_version >= 1.0.1` → Enable new feature
  - **Condition**: `country in ['US', 'CA']` → Region-specific features
  - **Condition**: `user_id in [test_list]` → Dogfood testing

---

## 4. Custom Claims Setup (Pro Tier)

### 4.1 Test User Accounts

Create Firebase test users with custom claims:

- [ ] **Free tier user** (default):
  - Email: `test-free@zerospoils.com` (or anonymous)
  - Custom claims: `{}`
  - Expected behavior: Pro features disabled

- [ ] **Pro tier user**:
  - Email: `test-pro@zerospoils.com`
  - Custom claims: `{"pro_tier": true}`
  - Expected behavior: Pro features enabled

### 4.2 Custom Claims Verification

```bash
# Set custom claims via Firebase Admin SDK (Node.js example)
const admin = require('firebase-admin');
admin.initializeApp();

const uid = 'USER_UID_HERE';
admin.auth().setCustomUserClaims(uid, { pro_tier: true });
```

- [ ] Set `pro_tier: true` for test Pro user
- [ ] Sign in as Pro user in app
- [ ] Verify feature flags reflect Pro status:
  - `receipt_ocr` → enabled
  - `batch_photo_capture` → enabled
  - `cloud_sync` → enabled
  - `cloud_analytics_export` → enabled

- [ ] Sign in as free user
- [ ] Verify Pro features disabled in UI

---

## 5. Android Release Build

### 5.1 Build Configuration

- [ ] `android/app/build.gradle.kts` configured:
  - `applicationId`: `com.zerospoils.zerospoils`
  - `versionCode`: `1` (increment for each release)
  - `versionName`: `1.0.0`
  - `minSdkVersion`: `21` (Android 5.0+)
  - `targetSdkVersion`: `36` (latest stable)

- [ ] ProGuard rules configured (`proguard-rules.pro`):
  - Firebase classes preserved
  - Supabase classes preserved
  - Flutter embedding preserved

### 5.2 Build Commands

```bash
# Clean build
cd app
flutter clean
flutter pub get

# Release build with obfuscation
flutter build apk --release --obfuscate --split-debug-info=./debug-info

# Verify output
ls -lh build/app/outputs/flutter-apk/app-release.apk
ls -lh debug-info/
```

- [ ] Release APK generated: `build/app/outputs/flutter-apk/app-release.apk`
- [ ] Debug symbols generated: `debug-info/*.symbols` (3 architecture variants)
- [ ] APK size acceptable (< 100MB for initial release)

### 5.3 Upload Debug Symbols to Firebase

```bash
# Upload symbols to Crashlytics for deobfuscation
firebase crashlytics:symbols:upload --app=ANDROID_APP_ID debug-info/
```

- [ ] Android app ID copied from Firebase Console
- [ ] Debug symbols uploaded to Crashlytics
- [ ] Crash report validation: Force crash in test build → verify in console

---

## 6. Release Validation

### 6.1 Pre-Upload Smoke Tests

Install release APK on physical device (not emulator):

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

- [ ] **App launches** without crashes
- [ ] **Firebase Auth** initializes (check logcat for bootstrap message)
- [ ] **Crashlytics** reports test crash (intentional crash button)
- [ ] **Remote Config** loads default values
- [ ] **Feature flags** resolve correctly (Pro features disabled for anonymous user)
- [ ] **Notifications** work (schedule test reminder)
- [ ] **Shopping list** CRUD operations functional
- [ ] **Inventory** CRUD operations functional
- [ ] **Batch photo capture** accessible (Pro users only)

### 6.2 Post-Upload Validation (Internal Testing)

After uploading to Play Console internal testing track:

- [ ] **Tester access**: Install app from Play Store opt-in URL
- [ ] **First launch**: Firebase bootstrap completes successfully
- [ ] **Token persistence**: Close and reopen app → user session restored
- [ ] **Custom claims**: Sign in as Pro user → Pro features enabled
- [ ] **Kill-switch test**: Disable feature in Remote Config → app respects change
- [ ] **Crashlytics**: After 24 hours, verify crash-free rate in Firebase Console

---

## 7. Monitoring & Analytics

### 7.1 Firebase Crashlytics

- [ ] Crash-free rate target: **> 99%**
- [ ] Alert configured for crash rate spike (> 1% within 1 hour)
- [ ] Team email notifications enabled for new crash types

### 7.2 Remote Config Metrics

- [ ] Monitor fetch success rate in Firebase Console
- [ ] Verify parameter values match intended configuration
- [ ] Track feature flag changes in Remote Config change log

### 7.3 Custom Events (Optional)

- [ ] Key user events instrumented:
  - `app_launched`
  - `item_added`
  - `notification_received`
  - `shopping_item_purchased`
  - `batch_photo_captured` (Pro)
  - `ocr_completed` (Pro)

---

## 8. Rollback Plan

### 8.1 Emergency Kill-Switch

If critical bug discovered:

1. **Immediate action**: Set `feature_flags_enabled = false` in Remote Config
   - Disables all non-essential features
   - App remains functional in "safe mode" (core inventory only)
2. **Within 1 hour**: Identify affected feature → disable specific flag
3. **Within 24 hours**: Upload hotfix build to closed testing track

### 8.2 Rollback to Previous Version

If entire build is broken:

1. **Play Console**: Halt rollout from Releases → Testing → Closed testing
2. **Remove buggy version** from track (or reduce rollout to 0%)
3. **Re-promote previous version** to closed testing track
4. **Notify testers** via email or in-app messaging (if implemented)

---

## 9. Beta Tester Communication

### 9.1 Onboarding Email Template

```
Subject: Welcome to ZeroSpoils Closed Beta!

Hi [Tester Name],

Thank you for joining the ZeroSpoils closed beta! You're helping us build
a better food waste reduction app.

**How to get started:**
1. Join the closed testing track: [Play Store Opt-In URL]
2. Install the app from Google Play
3. Open the app and grant notification permissions
4. Explore the inventory, shopping list, and expiry tracking features

**What to test:**
- Add items to your inventory and set expiry dates
- Schedule expiry reminders
- Convert shopping list items to inventory
- Report any crashes or unexpected behavior

**How to provide feedback:**
[Feedback form link or email address]

**What's next:**
We'll be releasing updates every 2 weeks. You'll get automatic updates
from the Play Store.

Thanks for your support!
- ZeroSpoils Team
```

- [ ] Onboarding email drafted
- [ ] Feedback collection method chosen (Google Form, email, Slack channel)
- [ ] Tester expectations set (update frequency, feedback deadlines)

### 9.2 Release Notes Template

```
Version 1.0.1 (Build 2)
-----------------------
New Features:
- [Feature description]

Bug Fixes:
- Fixed crash when adding items with emoji in name
- Improved notification scheduling reliability

Known Issues:
- [List any known bugs not yet fixed]

What We Need You to Test:
- [Specific testing requests for this release]
```

- [ ] Release notes template saved
- [ ] Update instructions documented (automatic via Play Store)

---

## 10. Success Criteria

### 10.1 Launch Readiness

Closed testing track is ready when:

- [ ] **100+ items added** across all testers (validates core flow)
- [ ] **50+ shopping list conversions** (validates key feature)
- [ ] **Crash-free rate > 98%** after 1 week
- [ ] **No P0/P1 bugs** reported
- [ ] **5+ testers active daily** for 2 weeks
- [ ] **Positive feedback** from initial tester cohort

### 10.2 Graduation to Open Testing

Move to open testing (unrestricted beta) when:

- [ ] All closed testing success criteria met
- [ ] Privacy policy finalized and published
- [ ] Terms of service drafted (if required)
- [ ] App store listing copy finalized
- [ ] Marketing assets ready (website, social media)
- [ ] Support email monitored (hi@zerospoils.com or similar)

---

## 11. Checklist Sign-Off

- [ ] **Technical Lead**: All build + Firebase config complete
- [ ] **QA**: All smoke tests passed
- [ ] **Product Owner**: Feature flags + kill-switch validated
- [ ] **Release Manager**: Play Console setup complete, APK uploaded
- [ ] **Team**: All testers added to internal testing track
- [ ] **Final approval**: Ready to invite external beta testers

**Date completed**: _________________  
**Released by**: _________________  
**Release version**: 1.0.0 (Build 1)

---

## Next Steps After Closed Testing

1. **Analyze feedback** (2-4 weeks of closed testing)
2. **Fix critical bugs** (priority: crashes, data loss, UX blockers)
3. **Prepare for open testing** (scale to 100-1000 users)
4. **Plan production launch** (M6 milestone)

**Related Issues:**
- M4/370: Closed testing backend security hardening
- M4/260: Beta distribution automation
- M4/270: Crashlytics integration validation
- M6/410: Subscription strategy + Pro tier billing
