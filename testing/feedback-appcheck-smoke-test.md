# Feedback + App Check Smoke Test (10 Minutes)

Audience: Non-technical testers  
Goal: Quick confidence check for feedback submission on iOS/Android  
Time: 8-10 minutes per device

## Tester Info

- Tester name:
- Date/time:
- Platform: Android / iOS
- Device model:
- OS version:
- App version/build:
- Build type: Debug / Internal Testing / Release

## Preconditions

- App is installed and opens normally.
- Device has internet connection.
- Tester can access Settings and app drawer/menu.
- Tester can take screenshots.

## Smoke Steps

### 1) Open feedback from Settings

- [ ] Open app.
- [ ] Go to Settings.
- [ ] Tap Send Feedback.

Expected:
- [ ] Feedback drawer opens.

Evidence:
- [ ] Screenshot taken.

---

### 2) Validate empty message guard

- [ ] Leave message blank.
- [ ] Tap Submit.

Expected:
- [ ] Validation error appears.
- [ ] Feedback is NOT submitted.

Evidence:
- [ ] Screenshot taken.

---

### 3) Submit valid feedback (happy path)

- [ ] Enter a valid message (example: "Testing feedback flow from smoke script.").
- [ ] Select any category.
- [ ] Tap Submit.

Expected:
- [ ] Success snackbar appears OR clear queued/retry message appears.
- [ ] Drawer closes after successful submit.

Evidence:
- [ ] Screenshot taken.
- [ ] Timestamp noted:

---

### 4) Open feedback from app drawer/menu

- [ ] Open app drawer/menu.
- [ ] Tap Send Feedback.

Expected:
- [ ] Feedback drawer opens from this entry point too.

Evidence:
- [ ] Screenshot taken.

---

### 5) Repeat submit quickly (rate-limit behavior)

- [ ] Submit another valid feedback message immediately.

Expected:
- [ ] App handles response gracefully (success, queued, or retry message).
- [ ] No crash, freeze, or broken UI.

Evidence:
- [ ] Screenshot taken.

## Pass/Fail Summary

- [ ] PASS: All critical checks completed without crash/blocker.
- [ ] FAIL: Any blocker found.

If FAIL, list blocker:
- Step #:
- What happened:
- Expected behavior:
- Reproducible? Yes/No

## Attachments To Share

- [ ] All screenshots
- [ ] Device/platform details
- [ ] Timestamp of each submit attempt

## Notes for QA/Engineering

- This smoke script is intentionally minimal.
- Full validation (auth, App Check rejection, offline queue, schema checks) is in:
  testing/feedback-appcheck-crossplatform-test-script.md
