## Context
Closed testing is starting soon, and public Play Store launch requires production-grade security hardening. The app now has feature flags, but Pro/paid capabilities cannot rely on client-side checks. We need backend-trusted entitlements, mobile observability, and release hardening before launch.

## Goal
Deliver a launch-ready foundation that combines:
- Firebase mobile tooling (Crashlytics, Remote Config, optional FCM)
- Supabase backend trust boundary (auth, RLS, entitlements)
- Play Store hardening requirements (obfuscation, minification, integrity checks)

## Expected behavior
- Closed-test builds can be distributed with crash visibility and controlled rollouts.
- Feature flags can consume remote, server-trusted entitlements.
- Pro feature access is enforced server-side (not bypassable by local flag tampering).
- Android release artifacts are hardened for launch.

## Acceptance criteria (Definition of Done)
- [ ] Add Firebase SDK integration for Android + iOS with Crashlytics enabled for non-debug builds.
- [ ] Add Remote Config adapter that feeds `FeatureFlagsService` remote overrides (no vendor lock in service layer).
- [ ] Add Supabase integration (`supabase_flutter`) with authenticated session bootstrap.
- [ ] Create `entitlements` model/path in backend contract and map it to feature flags (`cloud_sync`, `receipt_ocr`, etc.).
- [ ] Enforce server-side authorization for at least one Pro endpoint (example: OCR or cloud export) using authenticated user + entitlement check.
- [ ] Enable Android release hardening: Flutter obfuscation + split debug symbols + R8/proguard minify/shrink.
- [ ] Add Play Integrity check gate for high-value actions (Pro endpoint calls/export), with graceful handling for failed attestation.
- [ ] Add secure token handling path (platform-secure storage for session/refresh tokens; no plaintext storage in SharedPreferences).
- [ ] Add kill-switch behavior via Remote Config for at least one feature flag and validate fallback behavior.
- [ ] Document closed-testing release checklist (config parity, crash dashboard, rollout rollback steps, symbol upload process).

## Out of scope
- Full growth analytics/dashboard work beyond launch-critical telemetry.
- Advanced anti-tamper/anti-debug countermeasures beyond integrity + server validation.
- Multi-region backend architecture and scale optimization.

## Implementation notes
- Keep `FeatureFlagsService` precedence unchanged: `local_override > remote_override > default`.
- For production, local overrides remain debug/internal only; release builds rely on remote/default.
- Treat backend as source of truth for Pro access; client flags only control UX visibility.
- Keep Firebase usage focused on mobile concerns (crash reporting, remote config, push). Keep product data/auth in Supabase.
- Avoid embedding secrets in app binary; use platform config + CI secret injection.

## Test plan
**Automated:**
- Unit test: remote override adapter converts Firebase + Supabase entitlement payload into `Map<String, bool>` correctly.
- Unit test: Pro entitlement false -> server request returns 403 for gated endpoint.
- Unit test: Pro entitlement true -> gated endpoint succeeds.
- Unit test: token persistence uses secure storage adapter (not SharedPreferences).
- Integration test: startup bootstrap loads auth session, applies remote flags, and updates gated UI.
- Build validation: Android release build command with obfuscation/minify succeeds in CI.

**Manual:**
1. Install closed-test build on Android internal track; trigger test crash and verify Crashlytics event received.
2. Toggle Remote Config flag off for a gated feature; relaunch app and verify feature hides without app update.
3. Log in as non-Pro test user; attempt Pro flow and verify clear blocked state + no server-side success.
4. Log in as Pro test user; verify same flow succeeds and telemetry event is recorded.
5. Validate release artifact: inspect build config to confirm obfuscation + minify/shrink are enabled.
6. Simulate integrity failure path and verify high-value action is blocked with user-safe messaging.

## Dependencies
- M3/130 feature flags framework merged.
- Existing M4 beta distribution items (260, 270, 290) available for closed-test track usage.
- M6 subscription strategy/gating alignment for entitlement schema (410).
