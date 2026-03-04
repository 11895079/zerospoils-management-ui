## Context
Closed testing is starting soon, and public Play Store launch requires production-grade security hardening. The app now has feature flags, but Pro/paid capabilities cannot rely on client-side checks. We need backend-trusted entitlements, mobile observability, and release hardening before launch.

## Goal
Deliver a launch-ready foundation that combines:
- Firebase (Crashlytics, Remote Config, Auth, Custom Claims for Pro tier)
- Supabase (relational data storage with RLS, read-only for app)
- Play Store hardening requirements (obfuscation, minification, integrity checks)

## Expected behavior
- Closed-test builds can be distributed with crash visibility and controlled rollouts.
- Feature flags can consume remote, server-trusted entitlements.
- Pro feature access is enforced server-side (not bypassable by local flag tampering).
- Android release artifacts are hardened for launch.

## Acceptance criteria (Definition of Done)
- [x] Step 1: Add Firebase SDK integration for Android + iOS with Crashlytics enabled for non-debug builds.
- [x] Step 2: Add Remote Config adapter + Supabase bootstrap + Android Gradle/iOS config + ProGuard rules.
- [ ] Step 3: Add Firebase Authentication + Custom Claims for Pro tier; wire into FeatureFlagsService.
- [ ] Step 4: Implement Android release hardening (obfuscation, R8/proguard minify).
- [ ] Step 5: Add Play Integrity check gate + secure token storage (flutter_secure_storage) for JWTs.
- [ ] Step 6: Add kill-switch behavior via Remote Config; validate fallback + closed-testing checklist.
- [ ] Server-side endpoint gating (Post-Step-6): OCR/export endpoints check Firebase ID token + custom claims before processing.

## Out of scope
- Full growth analytics/dashboard work beyond launch-critical telemetry.
- Advanced anti-tamper/anti-debug countermeasures beyond integrity + server validation.
- Multi-region backend architecture and scale optimization.

## Implementation notes
- Keep `FeatureFlagsService` precedence unchanged: `local_override > remote_override > default`.
- For production, local overrides remain debug/internal only; release builds rely on remote/default.
- **Firebase is primary auth**: Use Firebase Authentication + Custom Claims for Pro tier gating. Custom claims embedded in ID token (no extra RPC).
- **Supabase is relational data layer**: Items, receipts, shopping lists stored in Supabase with RLS policies enforcing user_id filtering.
- Avoid embedding secrets in app binary; use platform config + CI secret injection.
- Pro gating: Check Firebase Auth custom claims `pro_tier == true` at client (UX layer); server-side validation on first call to gated endpoint.

## Test plan
**Automated:**
- Unit test: remote override adapter converts Firebase + Supabase entitlement payload into `Map<String, bool>` correctly.
- Unit test: Pro entitlement false -> server request returns 403 for gated endpoint.
- Unit test (Step 3):**
- Unit test: FirebaseAuthService returns user UID and ID token.
- Unit test: EntitlementsService extracts `pro_tier` custom claim from ID token.
- Unit test: Pro entitlement false -> `isFlagEnabled('receipt_ocr')` returns false.
- Unit test: Pro entitlement true -> `isFlagEnabled('receipt_ocr')` returns true.
- Integration test: Startup flow: Firebase Auth → fetch ID token → extract claims → update feature flags → UI reflects Pro status.

**Manual (Step 3):**
1. Log in as non-Pro user (Firebase Console: custom claims `pro_tier: false`).
2. Verify OCR/batch photo capture disabled in UI (feature flags read false).
3. Log in as Pro user (Firebase Console: custom claims `pro_tier: true`).
4. Verify OCR/batch photo capture enabled in UI (feature flags read true).
5. Change Firebase Console custom claims and restart app; flags update immediately (tied to ID token refresh).

**Automated (Step 4+):**
- Build validation: Android release build with obfuscation/minify succeeds.
- Crashlytics mock test: verify errors reach Firebase (non-debug builds only).
- Remote Config kill-switch test: flag disabled in console → feature hides on app restart
- Existing M4 beta distribution items (260, 270, 290) available for closed-test track usage.
- M6 subscription strategy/gating alignment for entitlement schema (410).
