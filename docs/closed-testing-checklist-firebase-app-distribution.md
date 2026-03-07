# Closed Testing Checklist — Firebase App Distribution

## Overview

This checklist covers closed testing using **Firebase App Distribution** instead of Google Play closed tracks. It is intended for fast internal/beta validation with invited testers.

**Use this when:**
- You want quick tester access without Play Store review friction.
- You need frequent QA/beta drops.
- You want pre-Play feedback before broader rollout.

**Do not use this alone for Play-specific compliance testing** (install/update flow, Play Integrity behavior, listing metadata, Play policy flow). For those, also run the Play track checklist.

---

## 1) Prerequisites

- [ ] Firebase project exists and app is registered:
  - Android package: `com.zerospoils.zerospoils`
  - iOS bundle (if applicable): `com.zerospoils.zerospoils`
- [ ] `google-services.json` (Android) is configured and valid for package ID.
- [ ] Firebase Crashlytics and Remote Config are enabled.
- [ ] Testers have Google accounts.
- [ ] You have Firebase project permissions (Editor/Admin).

---

## 2) Firebase Console Setup

### 2.1 Enable App Distribution

- [ ] Open Firebase Console → App Distribution.
- [ ] Enable App Distribution for Android app.
- [ ] (Optional) Enable for iOS app.

### 2.2 Create Tester Groups

- [ ] Create at least these groups:
  - `internal-qa`
  - `beta-closed`
- [ ] Add tester emails to each group.
- [ ] Confirm invitation emails are sent.

### 2.3 Optional Integrations

- [ ] Link Crashlytics to release monitoring workflow.
- [ ] Add release notes template for tester guidance.

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

### 4.1 Install/Use Firebase CLI

- [ ] Firebase CLI installed and authenticated:

```bash
firebase login
firebase projects:list
```

### 4.2 Upload Command (Groups)

- [ ] Upload latest build to tester groups:

```bash
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --groups "internal-qa,beta-closed" \
  --release-notes "M4/370: secure token storage + kill-switch validation"
```

### 4.3 Upload Command (Direct Testers)

- [ ] Optional direct tester distribution:

```bash
firebase appdistribution:distribute app/build/app/outputs/flutter-apk/app-release.apk \
  --app <FIREBASE_ANDROID_APP_ID> \
  --testers "tester1@example.com,tester2@example.com"
```

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

## 7) Release Cadence & Governance

- [ ] Define distribution cadence (e.g., twice weekly or on merged milestones).
- [ ] Require release notes on each distribution.
- [ ] Maintain a build changelog mapped to issue IDs/PRs.
- [ ] Retire stale builds and keep only active candidate builds visible.

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

## Quick Start (Minimal Path)

1. Build release APK with obfuscation + symbols.
2. Upload via Firebase CLI to `internal-qa` group.
3. Confirm tester install + app startup.
4. Validate auth, Pro gating, and kill-switch behavior.
5. Monitor Crashlytics for 24–72 hours.
6. Iterate fixes quickly via new distributions.

---

## Related Documents

- [Closed Testing (Play Track)](docs/closed-testing-checklist.md)
- [Play Integrity Setup Guide](docs/play-integrity-setup.md)
- [M4/370 Work Item](planning/milestones/M4/370-closed-testing-backend-security-hardening-firebase-supabase.md)
