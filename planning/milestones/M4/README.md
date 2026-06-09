# Milestone M4 — Beta Testing

**Objective:** Distribute MVP to beta testers (TestFlight iOS, Google Play internal testing) and gather feedback for launch readiness.

**Scope:**
- App-wide UX baseline and guided first-use flow alignment before onboarding polish (375)
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

**Issues:** 204, 260, 265, 270, 275, 280, 285, 290, 295, 296, 300, 350, 370, 375, 670

**Dependencies:** M3 complete (all MVP features functional, telemetry instrumented).

---

## M4 Implementation Status

**Last Updated:** June 6, 2026 — **Progress:** 0/15 formally closed (0%); 295 functionally complete (manual contrast audit done — ready to close); 296 dark-mode readability shipped via PR #115; 370 one DoD item remaining (server-side endpoint gating); 280/285 (feedback drawer) shipped via PR #112; **350 Zesto Phase 1 merged (PR #119)** — service + 6/10 triggers wired end-to-end, 4/10 deferred to owning subsystems; 375 added to baseline app-wide UX flows before 204 onboarding polish

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
| **295** | Dark mode theme toggle | ✅ Done | — | Toggle fully live: `ThemePreferencesStore` persists, `themeModeProvider` switches `MaterialApp.themeMode`, telemetry fires `theme_changed`. Widget tests cover persistence + live switching + dark surface colors. Manual accessibility contrast verification completed across all screens. Ready to close. |
| **296** | Dark mode contrast/readability remediation | ✅ Done | #115 | Audit + token-level remediation merged via PR #115 ("M4/296: Dark mode contrast and readability remediation") on May 20, 2026. Ready to close. |
| **300** | Basic metrics dashboard (optional) | ⏳ Not Started | — | No `docs/metrics.md` dashboard artifact found yet |
| **370** | Closed-testing backend security hardening (Firebase + Supabase) | ⚠️ In Progress | — | Steps 1–6 complete per issue DoD (Crashlytics, Remote Config, Firebase Auth + Custom Claims, R8/ProGuard, SecureTokenService, kill-switch). **Sole remaining DoD item:** Server-side endpoint gating (Post-Step-6) — OCR/export endpoints must verify Firebase ID token + custom claims (`pro_tier == true`) before processing. Requires backend deploy (no app-side work). Launch strategy review recommended before closing. |
| **375** | App-wide UX baseline + “How this works” guidance model | ⏳ Not Started | — | Define canonical cross-screen flows (inventory, shopping list, receipt batch, progress), identify UX friction, and specify contextual help pattern (inline tips/“How this works” entry points) before finalizing onboarding implementation |
| **670** | Apple individual now + organization conversion readiness checklist | ⏳ Not Started | — | New cross-functional checklist for immediate iOS beta path and later Apple organization conversion before public launch |
| **350** | Zesto Phase 1 — core service (10 triggers, anti-spam, message pools) | ⚠️ In Progress | #119 (merged) | Service complete (`ZestoService`): all 10 trigger methods, 5–6 message variations each, 5s anti-spam with bypass, last-3 message history with re-roll, SharedPreferences persistence (`mascot_last_timestamp`, `mascot_message_history`, `lastDailyWelcomeDate`, unlock progress), `mascot_shown` / `mascot_dismissed` telemetry. `storage_tips.json` bundled with dairy/produce/meat/bread/leftovers/condiments/general. `ZestoOverlay` widget renders with reduced-motion support, Semantics live region, ≥44pt dismiss target, AA contrast. **Wired end-to-end (6/10):** first item, item added, consumed/quick-save, wasted (with category tip), daily welcome (HomeShell), expiry alert. **Deferred pending owning subsystems (4/10):** `onBadgeUnlocked`, `onStreakUpdated`, `onSavingsUpdated`, `onZeroWasteCalculated` — depend on badge system (planning issue 340), streak service, savings calculator, and weekly-stats subsystems respectively. Tests: `test/unit/zesto_service_test.dart` (anti-spam, message history, first-item, quick-save, expiry alert, daily welcome) + widget test coverage in item form/detail flows. |
| **204** | Zesto animated onboarding walkthrough (7-screen flow) | ⏳ Not Started | — | Moved from M3; user-activation pillar for beta cohort. Sub-work: `ZestoWidget` component (204-A), "Meet Zesto" intro screen (204-B), corner avatar on screens 2–4 (204-C), badge preview + celebration (204-D), send-off animation (204-E), post-onboarding first-item celebration (204-F). All animations use Dart `AnimationController`; Lottie out of scope |

### Commentary

- **295 (Dark Mode)** is complete: toggle works, persistence works, telemetry fires, tests cover the surfaces, and the manual contrast audit is done. Ready to close.
- **296 (Dark Mode Readability)** shipped via PR #115 on May 20. Ready to close.
- **370 (Security Hardening)** has exactly one DoD item left: **server-side endpoint gating** for OCR/export endpoints (verify Firebase ID token + `pro_tier` custom claim before processing). This is backend-side work — no further app changes required. Recommend pairing with launch strategy review before closing.
- **280/285 (In-App Feedback)** shipped via PR #112 — feedback drawer with Firebase Firestore backend, queue bounds, and platform contract alignment. Issue 280 can be closed; 285 wired to the drawer.
- **275 (Firebase App Distribution tester feedback)** is blocked until the Firebase App Distribution Tester SDK is integrated (M3/361).
- **350 (Zesto Phase 1)** merged in PR #119. The service is feature-complete (all 10 triggers, anti-spam, message history, persistence, telemetry, storage-tips asset). Six of ten triggers are wired into app screens (item add/edit, item detail consume/waste, home-shell daily welcome, expiry alert). The remaining four (badge / streak / savings / zero-waste) are implemented in the service but await their respective subsystems before they can be invoked end-to-end.
- **375 (App-wide UX Baseline)** should be completed before starting implementation-heavy onboarding polish in 204 so onboarding reflects the finalized “how the app works” model.
- **204 (Zesto Onboarding)** can proceed after 375 baseline alignment is signed off. Animation calibration target: 200–400 ms durations, 60 fps, `disableAnimations`-aware.
