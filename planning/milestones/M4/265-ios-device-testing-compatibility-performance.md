# 265: iOS Device Testing — Compatibility and Performance Validation

**Epic:** Quality Assurance  
**Milestone:** M4 (Beta Testing)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 030 (build pipelines — Android/iOS), 260 (TestFlight internal setup), 361 (Firebase App Distribution — Tester API), 360 (Firebase integration)

---

## Context

Issue 030 established the iOS build pipeline and issue 260 targets TestFlight distribution. Before distributing to external beta testers, the team needs a structured iOS testing pass that validates:

1. App correctness across the supported iOS version range (minimum deployment target through the latest iOS release)
2. Device-class compatibility (iPhone SE/mini form factor through Pro Max; iPad if in scope)
3. Platform-specific performance baselines (cold start, scroll smoothness, camera/OCR latency on older hardware)
4. iOS-specific permission flows (camera, notifications, local storage) and system integration (background fetch, push notification delivery)

Without this work item the team risks shipping beta builds that crash or perform poorly on older iPhones that make up a significant share of the Canadian grocery-app market (iOS 15/16 devices remain common).

---

## Goal

Deliver a reproducible iOS testing checklist and automated validation suite that confirms the ZeroSpoils app launches, navigates, and performs correctly across the defined iOS version range and device classes before each TestFlight distribution.

---

## Expected behavior

- A documented iOS compatibility matrix defines the minimum iOS version (to be confirmed in implementation — expected iOS 15+), the tested device classes, and known limitations
- CI automatically runs Flutter integration tests against the iOS Simulator for the two most recent major iOS releases on each PR to `main`
- A manual testing runbook guides a human tester through the key iOS-specific scenarios that cannot be automated (camera, push notifications, physical device performance, background behaviour)
- Performance targets are captured and tracked: cold-start time ≤ 3 s on an iPhone 12 (A14 Bionic chip, 4 GB RAM, iOS 15 minimum — use this specific hardware specification as the reference baseline, not a vague "equivalent"); scroll FPS ≥ 55 fps on inventory list with 200 items measured at 60 Hz display refresh; camera-to-OCR latency ≤ 2 s on the same iPhone 12 reference device running iOS 15; note that performance can vary significantly between iOS versions on identical hardware, so baselines must state both chip generation and OS version
- Any iOS-specific crash or rendering defect discovered during testing is logged as a linked issue before the beta build is distributed via TestFlight

---

## Acceptance criteria (Definition of Done)

- [ ] iOS compatibility matrix documented in `docs/ios-compatibility.md`: minimum iOS version, tested device classes (at least 3 form factors), known limitations
- [ ] CI workflow runs Flutter integration test suite on iOS Simulator for at least the two most recent major iOS versions on every PR targeting `main`
- [ ] Manual iOS testing runbook in `docs/ios-testing-runbook.md` covering: cold start, tab navigation, add item (manual and OCR paths), shopping list, notifications permission flow, camera permission flow, offline behaviour, background/foreground cycle
- [ ] Performance baselines captured and documented: cold-start ≤ 3 s, scroll ≥ 55 fps, OCR latency ≤ 2 s (on reference hardware iPhone 12 or newer)
- [ ] Crashlytics (M3/360) confirmed reporting iOS crashes from TestFlight builds
- [ ] All iOS-specific defects found during the testing pass logged as issues before beta distribution
- [ ] Unit/widget tests that previously passed on Android also pass on iOS Simulator in CI
- [ ] Accessibility basics: VoiceOver smoke-test included in manual runbook (inventory list, add-item form, shopping list)

---

## Out of scope

- iPad-specific layout optimisation (phone form factors only for MVP)
- iOS-specific UI customisation beyond standard Flutter theming
- App Clip or iOS widget/extension development
- Apple Watch companion app
- iCloud sync or Apple ID sign-in (Pro tier deferred to M6)
- Automated physical device testing (CI runs on Simulator; physical device testing is manual)

---

## Implementation notes

- **Minimum iOS version:** Flutter 3.x supports iOS 12+; set deployment target to iOS 15 to access modern `UIKit`/`SwiftUI` APIs and match the installed base of the target demographic; confirm in `ios/Podfile` and Xcode project settings
- **CI Simulator matrix:** use `macos-latest` GitHub Actions runner; use `xcrun simctl list` to select available iOS runtimes; run integration tests with `flutter test integration_test/ -d "iPhone 15"` and `flutter test integration_test/ -d "iPhone 14"` (adjust simulator names based on runner availability)
- **Xcode scheme:** ensure a `Beta` scheme is configured that mirrors the `beta` Flutter flavour; use it for TestFlight builds and integration test runs
- **Performance measurement:** use Dart's `Timeline` API (`dart:developer`) in integration tests to measure cold-start time; use `flutter drive --profile` for scroll-performance benchmarks; record results in a `docs/performance-baselines.md` file
- **Camera / OCR on Simulator:** camera-dependent tests (expiry OCR, package OCR, receipt capture) must use mock camera inputs on Simulator; annotate these tests as `@TestOn('ios-simulator')` or use a flag to skip live camera steps in CI
- **Push notifications on Simulator:** iOS Simulator supports simulated push notifications via `xcrun simctl push`; add a step in the manual runbook to send a simulated expiry reminder notification and verify it appears correctly
- **Background behaviour:** test app returning from background (home button → reopen) and from notification tap; verify inventory data is refreshed without a full cold start

---

## Test plan

**Automated:**
- CI integration test: app launches on iOS Simulator (iPhone 15) and renders the inventory list within 5 s of cold start
- CI integration test: tab navigation (Inventory → Shopping → Progress → Settings) completes on iOS Simulator without crash
- CI integration test: add item via manual entry on iOS Simulator; verify item persists and appears in inventory list
- CI integration test: shopping list add / convert to inventory on iOS Simulator
- CI performance test (`flutter drive --profile`): scroll through 200-item inventory list; assert average FPS ≥ 55
- CI smoke test: run the full existing widget test suite on iOS Simulator; assert zero failures

**Manual:**
1. Cold-start the app on a physical iPhone 12 (A14 Bionic, iOS 15); measure startup time with a stopwatch; confirm ≤ 3 s to interactive home screen
2. Navigate all four main tabs; verify no layout overflow, no rendering artefacts, smooth transitions
3. Add an item via expiry date OCR on a physical device; confirm camera opens, haptic feedback fires, date pre-fills
4. Deny camera permission; verify graceful fallback message; re-grant permission via Settings → verify camera works again
5. Add a shopping list item; convert it to inventory; verify item appears in inventory with correct purchase date
6. Send a simulated push notification via `xcrun simctl push`; tap the notification; verify app navigates to the correct screen
7. Enable VoiceOver; navigate inventory list; verify items are announced with name, category, and expiry date; navigate add-item form; verify all fields are labelled
8. Put device in airplane mode; perform add/edit/delete operations; verify all changes persist; reconnect network; verify no sync errors (offline-first)
9. Background the app for 5 minutes; return to foreground; verify session restored with correct state
10. Run app on the oldest supported iOS version (iOS 15) via Simulator; verify all screens render and core flows complete without crash

---

## Dependencies

- M2/030 build pipelines (iOS IPA generation and macOS CI runner)
- M4/260 TestFlight internal setup (beta distribution channel for physical device testing)
- M3/360 Firebase integration (Crashlytics for iOS crash reporting during testing)
- M3/361 Firebase App Distribution (alternative beta distribution for pre-TestFlight builds)
