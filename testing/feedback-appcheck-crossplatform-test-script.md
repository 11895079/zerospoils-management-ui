# Feedback + App Check Cross-Platform Test Script

Owner: QA / Engineering  
Scope: Feedback drawer flow, App Check behavior, auth requirements, ingest endpoint behavior  
Platforms: iOS and Android  
Build types: Debug and Release/Internal Testing  

## 1. Purpose

Use this script to validate end-to-end feedback submission behavior for:
- UI flow and validation
- Auth-required behavior
- App Check token behavior
- Backend ingest endpoint enforcement
- Firestore write outcomes
- Rate limiting and abuse controls

This script is structured for manual execution today and future automation mapping.

## 2. Preconditions

### 2.1 Environment
- Firebase project: zerospoils-23dae
- Feedback ingest endpoint deployed:
  https://submitfeedbackingest-c7nfsmjnbq-uc.a.run.app
- App build uses:
  FEEDBACK_INGEST_URL=https://submitfeedbackingest-c7nfsmjnbq-uc.a.run.app

### 2.2 Firebase setup
- Android App Check registration: Registered (Play Integrity)
- iOS App Check registration: Registered (DeviceCheck + App Attest)
- Cloud Function deployed: submitFeedbackIngest
- Firestore rules deployed from app/firestore.rules

### 2.3 App assumptions
- Feedback entry points exist in settings and app drawer
- Non-anonymous auth is required for feedback submission
- Offline queue fallback is enabled
- 10-minute submission window per user + device fingerprint is active

## 3. Test Matrix

Run minimum set:

- Android Debug (local device/emulator)
- Android Release/Internal testing build
- iOS Debug (simulator and one physical device if possible)
- iOS Release/Internal testing build

For each run, execute core tests T-01 to T-10.

## 4. Core Test Cases

### T-01 Open feedback drawer from Settings
Objective: Verify entry point opens the drawer.

Steps:
1. Launch app.
2. Go to Settings.
3. Tap Send Feedback.

Expected:
- Drawer opens from right side.
- Category selector, message field, submit button are visible.

Pass/Fail evidence:
- Screenshot of open drawer.

---

### T-02 Open feedback drawer from App Drawer
Objective: Verify second entry point works.

Steps:
1. Launch app.
2. Open app drawer/menu.
3. Tap Send Feedback.

Expected:
- Same feedback drawer opens.

Pass/Fail evidence:
- Screenshot or short recording.

---

### T-03 Required message validation
Objective: Ensure empty message cannot submit.

Steps:
1. Open feedback drawer.
2. Leave message empty.
3. Tap Submit.

Expected:
- Validation error appears.
- Request is not submitted.

Pass/Fail evidence:
- UI validation message screenshot.

---

### T-04 Successful authenticated submission
Objective: Validate happy path through ingest endpoint.

Steps:
1. Ensure user is signed in (non-anonymous).
2. Open drawer.
3. Select category.
4. Enter valid message (>= 12 chars recommended).
5. Tap Submit.

Expected:
- Success snackbar appears.
- Function request returns 200.
- Firestore document created in feedback_submissions.

Pass/Fail evidence:
- App success snackbar screenshot.
- Function log entry with 200 status.
- Firestore document fields include ingest_source=cloud_function.

---

### T-05 Unauthenticated submission is blocked
Objective: Ensure auth requirement is enforced.

Steps:
1. Put app in unauthenticated state (or sign out if possible).
2. Open drawer and submit valid message.

Expected:
- User-facing auth-required message shown.
- No feedback document created.

Pass/Fail evidence:
- App error snackbar screenshot.
- No new Firestore doc.

---

### T-06 App Check token acceptance (debug path)
Objective: Ensure debug builds can submit when debug tokens are configured.

Steps:
1. Run debug build.
2. Submit valid feedback.

Expected:
- Request accepted.
- No App Check rejection in function logs.

Pass/Fail evidence:
- Function logs without App Check invalid errors.

---

### T-07 App Check rejection behavior
Objective: Validate rejection handling when token missing/invalid.

Steps:
1. Use a build/environment where App Check token is not accepted.
2. Submit valid feedback.

Expected:
- Submission fails gracefully.
- User sees retry/failure message.
- Function logs show App Check rejection.

Pass/Fail evidence:
- App error state screenshot.
- Function log snippet.

---

### T-08 Rate limiting (10-minute window)
Objective: Verify repeated submissions are throttled.

Steps:
1. Submit one valid feedback item successfully.
2. Immediately submit a second valid feedback item.

Expected:
- First request accepted.
- Second request gets 429 rate_limited from function.
- App handles failure gracefully (queued or retry message as implemented).

Pass/Fail evidence:
- Function log with 429.
- App behavior screenshot.

---

### T-09 Offline queue and retry
Objective: Validate queue and flush behavior.

Steps:
1. Disable network.
2. Submit valid feedback.
3. Re-enable network.
4. Trigger another submit attempt.

Expected:
- Offline submit is queued.
- Queued payload is retried when network returns.
- Firestore eventually receives submission.

Pass/Fail evidence:
- App message indicating queued behavior.
- Later function/Firestore evidence of successful write.

---

### T-10 Payload schema conformance
Objective: Verify expected fields are written.

Steps:
1. Perform successful submission.
2. Inspect resulting Firestore document.

Expected fields:
- message
- category
- source
- device_fingerprint
- platform
- app_version
- build_number
- locale
- user_id
- created_at_client
- created_at
- status
- ingest_source=cloud_function

Pass/Fail evidence:
- Firestore document export/screenshot.

## 5. Platform-specific Notes

### 5.1 iOS simulator caveat
Current simulator runtime may fail due to Apple Silicon arm64 simulator incompatibility in MLKit pods.

If encountered:
- Prefer testing on physical iOS device for end-to-end validation.
- Or use an iOS simulator runtime compatible with plugin architecture.

### 5.2 Android internal testing
For release validation, prefer Play internal/closed testing install over sideload for attestation realism.

## 6. Observability Checklist

For each test run, collect:
- App-side result (success/failure UI)
- Function log status (200/401/403/429/500)
- Firestore doc presence/absence
- Timestamp and build version

## 7. Evidence Template

Test Run ID:  
Date/Time:  
Tester:  
Platform:  
Build type:  
App version/build:  
Device model/OS:  

Results:
- T-01:
- T-02:
- T-03:
- T-04:
- T-05:
- T-06:
- T-07:
- T-08:
- T-09:
- T-10:

Function logs summary:  
Firestore summary:  
Notes/defects:  

## 8. Automation Mapping Hints

Suggested automation layers:
- Widget/UI tests: T-01, T-02, T-03
- Integration tests with stub backend: T-04, T-05, T-09
- Staging E2E with real Firebase: T-04, T-06, T-08, T-10

Recommended tags:
- smoke
- regression
- security
- appcheck
- offline
- rate-limit
