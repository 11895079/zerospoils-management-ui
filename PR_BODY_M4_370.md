## Summary
This PR completes M4/370 launch hardening work (Steps 3-6) for closed testing readiness.

### Step 3 — Firebase Auth + Entitlements
- Added Firebase Authentication as primary auth (anonymous bootstrap)
- Added custom-claims-based entitlements resolution (`pro_tier`)
- Wired entitlements into feature flag evaluation path

### Step 4 — Android Release Hardening
- Validated release build with obfuscation and split debug info
- Hardened Android release configuration for R8/minification compatibility
- Preserved symbol generation workflow for deobfuscation

### Step 5 — Secure Token Storage
- Added secure ID token persistence with `flutter_secure_storage`
- Added token caching/restoration in Firebase bootstrap path
- Added integration coverage for token persistence and clear behavior

### Step 6 — Kill-Switch + Closed Testing Readiness
- Added integration coverage for bootstrap flow (Auth → Token → Entitlements → Remote Config)
- Documented Play-track closed testing checklist
- Added dedicated Firebase App Distribution closed testing checklist

## Key Files
- `app/lib/core/auth/firebase_auth_service.dart`
- `app/lib/core/auth/entitlements_service.dart`
- `app/lib/core/auth/secure_token_service.dart`
- `app/lib/core/bootstrap/firebase_bootstrap_service.dart`
- `app/lib/core/feature_flags/feature_flags_provider.dart`
- `app/integration_test/bootstrap_flow_test.dart`
- `app/integration_test/secure_token_service_test.dart`
- `docs/closed-testing-checklist.md`
- `docs/closed-testing-checklist-firebase-app-distribution.md`
- `docs/play-integrity-setup.md`
- `planning/milestones/M4/370-closed-testing-backend-security-hardening-firebase-supabase.md`

## Validation
- Flutter analyze: clean
- Full pre-commit test suite passed during commit workflow
- Release build validated with obfuscation/symbol output

## Notes
- Play Integrity implementation is documented and intentionally deferred to M6/public-launch phase.
- Firebase App Distribution checklist is added as separate operational guidance for closed testing outside Play tracks.
