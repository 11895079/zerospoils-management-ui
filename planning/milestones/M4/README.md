# Milestone M4 — Beta Testing

**Objective:** Distribute MVP to beta testers (TestFlight iOS, Google Play internal testing) and gather feedback for launch readiness.

**Scope:**
- TestFlight internal setup and release notes flow (260)
- iOS device testing — compatibility and performance validation (265)
- Google Play internal testing setup (270)
- Firebase App Distribution tester feedback retrieval and triage workflow (275)
- In-app feedback entry point with metadata (280)
- Crash reporting and basic performance monitoring (290)
- Basic metrics dashboard (optional) (300)
- Dark mode theme toggle (295)
- Dark mode contrast/readability remediation (296)
- Settings feedback entry (285)
- Closed-testing backend and launch hardening (Firebase + Supabase + release security) (370)
- Apple individual enrollment now + organization conversion readiness checklist (670)
- **Zesto animated onboarding walkthrough — user activation pillar (204, 350)** *(promoted from M3)*

**Acceptance:** App distributed to 10-50 beta testers on iOS and Android; feedback mechanism working; crash reports visible; performance baseline established; launch hardening checklist completed for production-ready release security; Zesto animated onboarding complete and beta testers experience the full 7-screen flow.

**Out of Scope:** Public launch, store listing copy, brand assets (deferred to M5).

**Issues:** 204, 260, 265, 270, 275, 280, 285, 290, 295, 296, 300, 350, 370, 670

**Dependencies:** M3 complete (all MVP features functional, telemetry instrumented).

---

## M4 Implementation Status

**Last Updated:** May 17, 2026 — **Progress:** 0/14 formally closed (0%); 295 functionally complete pending contrast audit; 296 created for dark-mode readability remediation; 370 ~90% complete; 280 (feedback drawer) shipped via PR #112; 204 and 350 (Zesto animated onboarding) are the new activation priority

### Issues & Completion

| Issue | Title | Status | PR | Notes |
|-------|-------|--------|----|-------|
| **260** | TestFlight internal setup + release notes flow | ⏳ Not Started | — | `docs/beta-ios.md` and release-note workflow doc are not in repo yet |
| **265** | iOS device testing — compatibility and performance | ⏳ Not Started | — | iOS compat matrix (iOS 15+), CI Simulator matrix, manual runbook, performance baselines (cold start ≤ 3 s, scroll ≥ 55 fps) |
| **270** | Google Play internal testing setup | ⚠️ In Progress | — | Closed-testing guidance exists in `docs/closed-testing-checklist.md`, but issue-specific deliverables (`docs/beta-android.md`, AAB release workflow) are not fully tracked as complete |
| **275** | Firebase App Distribution tester feedback retrieval + triage workflow | ⏳ Not Started | — | New M4 follow-up to make Android beta feedback and screenshots operational instead of ad hoc |
| **280** | In-app feedback entry point (email/web form + metadata) | ⏳ Not Started | — | No issue file in M4 folder; Settings has "Send Feedback" entry but taps show `Feedback form coming soon` snack — no form, no metadata, no telemetry |
| **285** | Settings feedback entry | ⚠️ In Progress | — | UI row present (`Icons.feedback_outlined`, 'Send Feedback') in settings_screen.dart; `onTap` shows placeholder snack. Awaiting M4/280 feedback service to wire into |
| **290** | Crash reporting + basic performance monitoring | ⚠️ In Progress | — | Firebase Crashlytics and release symbol flow were added under M4/370 scope; `docs/ops.md` triage workflow remains outstanding |
| **295** | Dark mode theme toggle | ⚠️ Mostly Done | — | Toggle fully live: `ThemePreferencesStore` persists, `themeModeProvider` switches `MaterialApp.themeMode`, telemetry fires `theme_changed`. Widget tests cover persistence + live switching + dark surface colors. Remaining: manual accessibility contrast verification across all screens |
| **296** | Dark mode contrast/readability remediation | ⏳ Not Started | — | Follow-up to 295: audit and fix low-contrast text/states in dark mode across core flows; WCAG AA targets; shared-theme/token-first remediation |
| **300** | Basic metrics dashboard (optional) | ⏳ Not Started | — | No `docs/metrics.md` dashboard artifact found yet |
| **370** | Closed-testing backend security hardening (Firebase + Supabase) | ⚠️ In Progress | — | Steps 1-6 complete per issue DoD (Crashlytics, Remote Config, Firebase Auth + Custom Claims, R8/ProGuard, SecureTokenService, kill-switch). One item open: server-side endpoint gating (OCR/export endpoints check Firebase ID token + custom claims). Launch strategy review recommended before closing |
| **670** | Apple individual now + organization conversion readiness checklist | ⏳ Not Started | — | New cross-functional checklist for immediate iOS beta path and later Apple organization conversion before public launch |
| **350** | Zesto Phase 1 — core service (10 triggers, anti-spam, message pools) | ⏳ Not Started | — | Moved from M3; prerequisite for 204; `ZestoService` skeleton exists in `app/lib/domain/repositories/zesto_service.dart` — needs trigger wiring and anti-spam logic |
| **204** | Zesto animated onboarding walkthrough (7-screen flow) | ⏳ Not Started | — | Moved from M3; user-activation pillar for beta cohort. Sub-work: `ZestoWidget` component (204-A), "Meet Zesto" intro screen (204-B), corner avatar on screens 2–4 (204-C), badge preview + celebration (204-D), send-off animation (204-E), post-onboarding first-item celebration (204-F). All animations use Dart `AnimationController`; Lottie out of scope |

### Commentary

- **295 (Dark Mode)** is functionally complete; only manual contrast verification remains. Can be closed after a QA pass.
- **296 (Dark Mode Readability)** is newly added to explicitly track contrast/readability defects reported during beta usage and close out the remaining accessibility work before launch.
- **370 (Security Hardening)** is ~90% done; server-side endpoint gating is the sole remaining DoD item. Recommend reviewing as part of launch strategy before closing.
- **280/285 (In-App Feedback)** shipped via PR #112 — feedback drawer with Firebase Firestore backend, queue bounds, and platform contract alignment. Issue 280 can be closed; 285 wired to the drawer.
- **275 (Firebase App Distribution tester feedback)** is blocked until the Firebase App Distribution Tester SDK is integrated (M3/361).
- **350 + 204 (Zesto Onboarding)** are the new activation priority. 350 must land first (Zesto service + triggers); 204 layers the animated onboarding UI on top. Treat as a paired delivery. Animation calibration target: 200–400 ms durations, 60 fps, `disableAnimations`-aware.
