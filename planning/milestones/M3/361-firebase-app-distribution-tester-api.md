# 361: Firebase App Distribution — Tester API Integration for Beta Feedback

**Epic:** Infrastructure  
**Milestone:** M3 (MVP Quality & Shopping)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 360 (Firebase integration — Crashlytics, Remote Config, FCM), 280 (in-app feedback entry point), 030 (build pipelines — Android/iOS)

---

## Context

Issue 360 integrated Firebase Crashlytics, Remote Config, and FCM. The app now has crash visibility and feature-flag control. The next step toward beta readiness is closing the tester feedback loop: testers need a frictionless way to submit feedback on builds they receive, and the team needs a way to distribute new builds and collect structured feedback without requiring App Store or Play Store submissions.

Firebase App Distribution provides managed build delivery to named tester groups plus an optional Tester API (and its companion Tester SDK) that surfaces an in-app experience for testers: version update notifications, a release notes display, and a feedback-capture entry point. This issue integrates App Distribution into the CI delivery pipeline and wires the Tester SDK into the Flutter app so feedback flows through automatically on beta builds.

---

## Goal

Integrate Firebase App Distribution into the CI/CD pipeline for beta build delivery, and embed the Firebase App Distribution Tester SDK in the app so that beta testers receive in-app update notifications, can read release notes, and can submit structured feedback without leaving the app.

---

## Expected behavior

- CI/CD uploads new Android (APK/AAB) and iOS (IPA) builds to Firebase App Distribution automatically on every tag push matching `v*-beta.*` (e.g., `v0.2.0-beta.1`); in Firebase App Distribution terminology a **tester group** (e.g., `beta-internal`) is the distribution target — not a "channel" in the App Store sense; builds are delivered to all testers in the named group, and release notes are attached per build
- CI/CD accepts a release notes artifact (auto-generated from `CHANGELOG.md` or the latest `git log --oneline`) and attaches it to each distributed build
- Beta testers are invited via Firebase Console tester groups; no manual APK sharing via email or Slack needed
- On app launch (beta builds only), the Firebase App Distribution Tester SDK checks for a newer available build in the tester's group and shows the standard Firebase in-app update dialog if a newer build exists
- Tester SDK integration is compiled in only for `debug` and `beta` build flavours; production release builds must NOT include the Tester SDK
- In-app feedback: testers can shake the device (or tap a visible feedback button in the beta app's debug drawer) to open the Firebase App Distribution feedback UI, which captures a screenshot, allows annotation, and submits feedback directly to the Firebase Console
- Submitted feedback is visible in the Firebase Console under App Distribution → Feedback for the team to review
- The CI workflow posts a Slack/GitHub notification when a new build is successfully distributed to testers (optional but recommended)

---

## Acceptance criteria (Definition of Done)

- [ ] Firebase App Distribution is configured in the Firebase Console with at least one tester group (`beta-internal`)
- [ ] CI workflow (`build-and-distribute.yml` or equivalent) uploads APK/AAB and IPA to App Distribution on tag push matching `v*-beta.*`
- [ ] Release notes are attached automatically to each distributed build (extracted from `CHANGELOG.md` or `git log`)
- [ ] `firebase_app_distribution` Flutter package (or Tester SDK native integration) added to `pubspec.yaml` under `dev_dependencies` or behind a build-flavour condition
- [ ] Tester SDK compiled into `debug` and `beta` flavours only; production builds verified to exclude Tester SDK code paths
- [ ] In-app update check runs on app launch for beta builds; shows update dialog when a newer build is available
- [ ] Shake-to-feedback (or debug-drawer feedback button) triggers Firebase App Distribution feedback capture UI on beta builds
- [ ] Feedback submissions visible in Firebase Console under App Distribution → Feedback
- [ ] Unit/widget/integration tests: see test plan
- [ ] Offline-first: Tester SDK update check fails gracefully when device is offline; no crash or blocking dialog
- [ ] Accessibility basics: update dialog and feedback UI meet tap-target and contrast requirements

---

## Out of scope

- TestFlight or Google Play internal testing distribution (tracked in M4/260 and M4/270 respectively)
- Custom in-app feedback forms beyond the Firebase-provided UI (tracked in M4/280)
- Automated crash-to-tester notification workflows (Crashlytics alerting is a separate ops concern)
- Tester authentication / account management beyond Firebase Console configuration
- A/B testing or percentage-based rollouts via App Distribution (use Remote Config for feature rollouts)

---

## Implementation notes

- Firebase App Distribution Flutter integration requires the native Firebase App Distribution SDK on each platform; as of 2026 this is typically included via `firebase_app_distribution` or by calling native SDKs directly from method channels
- Flavour separation strategy:
  - Define `debug`, `beta`, and `release` build flavours in `android/app/build.gradle` and Xcode schemes
  - Conditionally initialise the Tester SDK in `main_beta.dart` / `main_debug.dart`; `main_release.dart` must not call any Tester SDK code
  - Guard with a compile-time constant (e.g., `const bool kBetaBuild = bool.fromEnvironment('BETA_BUILD')`) to ensure tree-shaking removes Tester SDK from production builds
- CI workflow additions:
  - Install the Firebase CLI or use the `wzieba/Firebase-Distribution-Github-Action` GitHub Action
  - Extract release notes: `git log --oneline $(git describe --tags --abbrev=0 HEAD^)..HEAD > release_notes.txt`
  - Upload step: `firebase appdistribution:distribute app-release.apk --app $FIREBASE_APP_ID_ANDROID --groups beta-internal --release-notes-file release_notes.txt`
  - Mirror for iOS: upload `.ipa` with `--app $FIREBASE_APP_ID_IOS`
- Shake-to-feedback: on Android, enable the Firebase App Distribution in-app feedback UI by calling `FirebaseAppDistribution.instance.showFeedbackNotification()` at app start (beta flavour only); on iOS, `UIShakerGestureRecognizer` must be registered in `AppDelegate` to forward shake events to the Tester SDK feedback handler; the `signInWithEmailLink` API is for tester authentication (deep-link sign-in flow) and is unrelated to shake feedback — do not confuse the two
- Store Firebase App IDs (`FIREBASE_APP_ID_ANDROID`, `FIREBASE_APP_ID_IOS`) and service account credentials as GitHub Actions secrets; never embed in source

---

## Test plan

**Automated:**
- Unit test: `AppDistributionService` update-check method returns `noUpdate` gracefully when network is unavailable (mock HTTP failure)
- Widget test: beta build flavour shows feedback FAB or debug-drawer feedback entry; release build flavour hides it (use build constant in test)
- Integration test: mock Tester SDK returns `updateAvailable`; verify app shows update dialog and records `beta_update_available` telemetry event
- CI validation: dry-run upload step in CI (using `--dry-run` flag if supported, or a staging Firebase project) verifies upload command syntax and credentials binding

**Manual:**
1. Tag a commit `v0.2.0-beta.1`; verify GitHub Actions workflow triggers; verify build appears in Firebase Console under App Distribution within 5 minutes
2. Open the distributed build on an enrolled test device; verify in-app update check dialog appears if a newer beta build exists
3. Shake the device while in the app (beta build); verify Firebase feedback capture UI opens with screenshot
4. Submit feedback annotation; verify submission appears in Firebase Console → App Distribution → Feedback
5. Put device in airplane mode; launch app; verify no crash, no blocking dialog, graceful offline message if update check fails
6. Build production release build; verify Firebase App Distribution Tester SDK is absent from the binary (check with `grep -r "FirebaseAppDistribution" build/` or equivalent)
7. Screen reader: verify update dialog and feedback button meet accessibility requirements

---

## Dependencies

- M3/360 Firebase integration (Firebase project configured, `google-services.json` / `GoogleService-Info.plist` in repo)
- M2/030 build pipelines (GitHub Actions CI for APK/AAB and IPA generation on tag push)
- M4/280 in-app feedback (for eventual consolidation of Firebase feedback + custom in-app form)
