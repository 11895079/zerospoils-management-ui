# Milestone M4 — Beta Testing

**Objective:** Distribute MVP to beta testers (TestFlight iOS, Google Play internal testing) and gather feedback for launch readiness.

**Scope:**
- TestFlight internal setup and release notes flow (260)
- Google Play internal testing setup (270)
- In-app feedback entry point with metadata (280)
- Crash reporting and basic performance monitoring (290)
- Basic metrics dashboard (optional) (300)
- Dark mode theme toggle (295)
- Settings feedback entry (285)
- Closed-testing backend and launch hardening (Firebase + Supabase + release security) (370)

**Acceptance:** App distributed to 10-50 beta testers on iOS and Android; feedback mechanism working; crash reports visible; performance baseline established; launch hardening checklist completed for production-ready release security.

**Out of Scope:** Public launch, store listing copy, brand assets (deferred to M5).

**Issues:** 260, 270, 280, 285, 290, 295, 300, 370

**Dependencies:** M3 complete (all MVP features functional, telemetry instrumented).

---

## M4 Implementation Status

**Last Updated:** March 7, 2026 — **Progress:** 0/8 planned issues complete (0%)

### Issues & Completion

| Issue | Title | Status | PR | Notes |
|-------|-------|--------|----|-------|
| **260** | TestFlight internal setup + release notes flow | ⏳ Not Started | — | `docs/beta-ios.md` and release-note workflow doc are not in repo yet |
| **270** | Google Play internal testing setup | ⚠️ In Progress | — | Closed-testing guidance exists in `docs/closed-testing-checklist.md`, but issue-specific deliverables (`docs/beta-android.md`, AAB release workflow) are not fully tracked as complete |
| **280** | In-app feedback entry point (email/web form + metadata) | ⏳ Not Started | — | Settings has "Send Feedback" entry, but action is still placeholder (`Feedback form coming soon`) |
| **285** | Settings feedback entry | ⚠️ In Progress | — | UI entry exists in `app/lib/presentation/screens/settings_screen.dart`, pending integration to real feedback flow + telemetry per issue DoD |
| **290** | Crash reporting + basic performance monitoring | ⚠️ In Progress | — | Firebase Crashlytics and release symbol flow were added under M4/370 scope; `docs/ops.md` triage workflow remains outstanding |
| **295** | Dark mode theme toggle | ⚠️ In Progress | — | Toggle is present in Settings but currently disabled (`Soon`) and does not switch app theme live |
| **300** | Basic metrics dashboard (optional) | ⏳ Not Started | — | No `docs/metrics.md` dashboard artifact found yet |
| **370** | Closed-testing backend security hardening (Firebase + Supabase) | ⚠️ In Review | [#85](https://github.com/11895079/zerospoils/pull/85) | Steps 1-6 are marked complete in the issue, with server-side endpoint gating still open |

### Commentary

- M4 delivery is active, with the bulk of concrete implementation progress currently concentrated in issue 370.
- No M4 issue is fully closed yet against all documented acceptance criteria, so milestone completion remains at 0/8.
- After PR #85 merges and server-side endpoint gating is completed, M4 completion should be re-baselined.
