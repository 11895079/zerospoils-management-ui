# Firebase Authentication Rollout Checklist (Android + iOS)

Goal: move from anonymous-only usage to real user authentication with no downtime and no data-loss for existing testers.

## Scope

- Backend: Firebase Authentication
- Client: Flutter app (Android + iOS)
- Initial providers: Email/Password
- Next providers: Sign in with Apple (iOS), Google (Android + iOS)

## Prerequisites

- Firebase project selected and accessible
- App Check already configured for Android/iOS apps
- Current app supports anonymous auth and feedback ingestion
- Firestore rules already require non-anonymous auth for feedback writes

## Phase 1: Firebase Console Setup (Email/Password)

1. Open Firebase Console -> Build -> Authentication -> Sign-in method.
2. Enable Email/Password provider.
3. Keep Email Link disabled for now (optional to enable later).
4. Save changes.
5. Open Build -> Authentication -> Settings -> Authorized domains.
6. Verify expected test domains are present for future deep links.

Success criteria:
- Email/Password status is Enabled.
- No console warnings about disabled provider.

## Phase 2: App Integration (Already Implemented)

Implemented in app code:
- Settings account dialog supports:
  - Create account (email/password)
  - Sign in (email/password)
  - Sign out
- Anonymous account upgrade behavior:
  - If user is anonymous, creating/signing in attempts credential linking first.
  - Preserves UID for existing user-linked data.

Files:
- app/lib/core/auth/firebase_auth_service.dart
- app/lib/presentation/screens/settings_screen.dart
- app/test/widget/screens/settings_account_auth_test.dart

## Phase 3: QA Validation

Run:

```bash
cd app
flutter test test/widget/screens/settings_account_auth_test.dart test/widget/screens/settings_screen_test.dart
```

Manual smoke tests:

1. Launch app in debug on Android.
2. Open Settings -> Account.
3. Try invalid email and short password, confirm validation message.
4. Create account with valid email/password.
5. Close and reopen Settings; verify account subtitle shows signed-in state.
6. Sign out and verify subtitle returns to anonymous/not signed-in state.
7. Repeat on iOS simulator/device.

Success criteria:
- Sign-in/create/sign-out works on both platforms.
- No crashes when auth service is unavailable.
- Settings and account widget tests pass.

## Phase 4: Firestore + Feedback End-to-End

1. Sign in with a real account in-app.
2. Submit feedback from drawer and from settings.
3. Verify Cloud Function accepts request (no 401/403 due to auth/app check).
4. Confirm Firestore document appears in feedback_submissions with:
   - app_check_enforced: true
   - ingest_source: cloud_function
5. Confirm submissions by anonymous users are blocked by policy as expected.

Success criteria:
- Authenticated user can submit feedback consistently.
- Anonymous submission is rejected with clear UX message.

## Phase 5: Add Identity Providers

### Apple Sign-In (recommended next)

1. Apple Developer portal:
   - Configure Sign in with Apple capability for iOS bundle ID.
2. Firebase Console -> Authentication -> Sign-in method:
   - Enable Apple provider and configure Service ID / Team details.
3. App implementation:
   - Add Apple sign-in flow in account dialog and link to existing user.
4. Verify on physical iOS device.

### Google Sign-In

1. Firebase Console -> Authentication -> Sign-in method:
   - Enable Google provider.
2. Ensure Android SHA certificates and iOS config are correct.
3. Add Google sign-in in account dialog and link flow.
4. Validate on Android and iOS.

## Security and Reliability Notes

- Always prefer linkWithCredential for anonymous users before creating secondary accounts.
- Keep App Check enabled for Cloud Functions and monitor error rates.
- Do not expose provider-specific errors directly; map to user-safe messages.
- Add rate limiting or lockout policy after repeated failed attempts.

## Operational Monitoring

Monitor daily for first week:

- Authentication success/failure counts
- Common error codes (operation-not-allowed, invalid-credential, email-already-in-use)
- Feedback submit failures after sign-in
- App Check rejection rate for authenticated requests

Escalation triggers:
- Auth failure rate > 5%
- App Check rejects > 1% for signed-in users
- Feedback submission success drops below 99%

## Next Implementation Tasks

1. Add telemetry for auth events:
   - auth_account_created
   - auth_sign_in_succeeded
   - auth_sign_in_failed
   - auth_sign_out
2. Add "Forgot password" flow.
3. Add account deletion flow (GDPR readiness).
4. Add Apple and Google providers in UI.
5. Add integration test for anonymous-to-email linking path.
