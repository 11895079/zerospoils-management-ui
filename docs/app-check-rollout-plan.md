# App Check Rollout Plan (No-Downtime)

**Goal:** Enable App Check enforcement on feedback ingestion and Firestore with zero downtime for internal testers.

**Timeline:**
- **Phase 1 (Day 1):** Debug app registration + internal tester validation (2 hours)
- **Phase 2 (Day 2):** Release signature registration + closed testing (24 hours monitoring)
- **Phase 3 (Day 3):** Cloud Functions enforcement (low blast radius, feedback feature only)
- **Phase 4 (Day 4+):** Firestore enforcement (after 24h+ function monitoring)

---

## Pre-Rollout Checklist

## Current Status (2026-05-15)

- Local verification completed:
   - `submitFeedbackIngest` is deployed (`firebase functions:list`)
   - Function code enforces App Check (`enforceAppCheck: true`)
   - App bootstrap activates App Check on Android/iOS
   - Feedback client attaches `X-Firebase-AppCheck` when ingest URL is set
   - Android debug SHA-256 matches documented value
- Release keystore located and verified:
  - Path: `/Users/oba/keystores/zerospoils-release-key.jks`
  - Release SHA-256: `DE:C7:AC:1D:B8:56:DC:AC:D1:F7:F3:78:6C:4B:81:33:9A:7A:0C:72:DA:4E:15:91:DD:F3:FF:4E:81:1B:62:F5`
  - Credentials loaded from `app/android/key.properties`
- [x] Feedback ingestion Cloud Function deployed: https://submitfeedbackingest-c7nfsmjnbq-uc.a.run.app
- [ ] Firestore rules deployed with non-anonymous auth requirement

### Extract Release SHA-256

If release keystore exists at `~/zerospoils-release-key.jks`:

```bash
keytool -list -v -keystore ~/zerospoils-release-key.jks | grep SHA256
```

**Result format:** `XX:XX:XX:XX:...` (copy this for Phase 2, step 2.3)

---

## Phase 1: Debug App Registration + Internal Tester Validation (Day 1)

**Duration:** ~2 hours  
**Testers affected:** None yet (debug builds only)  
**Blast radius:** Zero (no enforcement)

### Step 1.1: Register Android Debug App

1. Firebase Console → Build → App Check → **Apps tab**
2. Click "Register" for **Zerospoils Android** (com.zerospoils.zerospoils)
3. Select **Play Integrity** as attestation provider
4. Paste debug SHA-256 fingerprint:
   ```
   DD:BA:D5:DA:19:E5:C2:73:58:27:9B:E5:88:80:41:0C:44:A4:CE:82:C1:B4:F9:72:51:80:20:FF:86:E0:6D:56
   ```
5. Click **Register**

### Step 1.2: Register iOS Debug App

1. Firebase Console → Build → App Check → **Apps tab**
2. Click "Register" for **ZeroSpoils iOS** (com.zerospoils.zerospoils)
3. Select **App Attest with DeviceCheck Fallback**
4. Click **Register**

### Step 1.3: Validate Debug Builds

**On Android:**
```bash
# Build debug APK
flutter build apk --debug

# Install on internal tester device
adb install build/app/outputs/flutter-apk/app-debug.apk

# Trigger feedback submission (Settings → Send Feedback)
# Verify no errors in Firebase Console logs
```

**On iOS:**
```bash
# Build debug IPA
flutter build ios --debug

# Deploy via Test Flight or local install
# Trigger feedback submission (Settings → Send Feedback)
# Verify no errors in Firebase Console logs
```

### Step 1.4: Confirm Debug App Check Tokens Flowing

1. Firebase Console → Build → App Check
2. Look for **Zerospoils Android** and **ZeroSpoils iOS** rows
3. If tokens are flowing, you should see token count increasing (may take 5-10 min)
4. If count stays at 0, check app logs for App Check init errors

**Success criteria:**
- ✅ No errors in feedback submission
- ✅ App Check token count > 0 for both platforms
- ✅ Internal tester can submit feedback without issues

---

## Phase 2: Release Signature Registration + Closed Testing (Day 2)

**Duration:** ~24 hours (monitoring)  
**Testers affected:** Closed testing track users  
**Blast radius:** Release builds only (if they use App Check)

### Step 2.1: Extract Release SHA-256

```bash
keytool -list -v -keystore ~/zerospoils-release-key.jks | grep "SHA256:"
```

**Result (extracted 2026-05-15):** `DE:C7:AC:1D:B8:56:DC:AC:D1:F7:F3:78:6C:4B:81:33:9A:7A:0C:72:DA:4E:15:91:DD:F3:FF:4E:81:1B:62:F5`

### Step 2.2: Add Release Fingerprint to Android App Check

1. Firebase Console → Build → App Check → **Apps tab**
2. Click **Zerospoils Android** (should show as "Registered")
3. Under **Play Integrity**, click **Add another fingerprint**
4. Paste release SHA-256 from step 2.1
5. Click **Add**

### Step 2.3: Deploy Release Build to Closed Testing

```bash
cd app
flutter build apk --release
```

Then upload to Play Console → Internal Testing (or Closed Testing track).

### Step 2.4: Testers Install from Play Store

1. Internal testers install from Play Store (not sideload)
2. Testers trigger feedback submission
3. Monitor Firebase Console for errors (may take 30 min for first tokens)

### Step 2.5: Monitor for 24 Hours

**Success criteria:**
- ✅ Release app submits feedback without errors
- ✅ Release app generates App Check tokens
- ✅ No 401/403 errors in Cloud Functions logs
- ✅ Feedback submissions appear in Firestore with `app_check_enforced: true` and `ingest_source: 'cloud_function'`

**Failure signs:**
- ❌ Feedback submissions fail with "App Check token invalid" errors
- ❌ Function logs show 401 Unauthorized
- ❌ No tokens in App Check metrics after 30 min

**If failures occur:**
- Check Android signing matches Play Console registered key
- Verify iOS app signed with correct team ID
- Confirm device has Play Services (Android) or App Attest support (iOS)

---

## Phase 3: Enforce Cloud Functions (Day 3)

**Duration:** Immediate (functions already enforce in code)  
**Testers affected:** Anyone calling submitFeedbackIngest endpoint  
**Blast radius:** Minimal (feedback feature only, fallback to direct Firestore if needed)

### Step 3.1: Confirm Function Enforcement is Active

Your deployed function already has `enforceAppCheck: true` in code:

```javascript
exports.submitFeedbackIngest = onRequest(
  {
    enforceAppCheck: true,  // ← Already enabled
    invoker: 'public',
  },
  async (req, res) => { ... }
);
```

This means the function will reject requests without valid App Check tokens starting now.

### Step 3.2: Update App to Use Ingest Endpoint

If not already done, build with the ingest URL:

```bash
flutter run --dart-define=FEEDBACK_INGEST_URL=https://submitfeedbackingest-c7nfsmjnbq-uc.a.run.app
```

Or add to your build config/CI for all builds.

### Step 3.3: Monitor Function Errors (24 Hours)

1. Firebase Console → Functions → **submitFeedbackIngest**
2. Watch **Execution count**, **Error rate**, **Response time**
3. Check logs for:
   - 401 errors (missing Auth token) → app issue
   - 403 errors (App Check invalid) → attestation issue
   - 429 errors (rate limited) → expected for repeated submissions within 10 min window

**Success criteria:**
- ✅ Error rate < 1%
- ✅ No systematic 401/403 errors
- ✅ Feedback appears in Firestore with `ingest_source: 'cloud_function'`

**Rollback if needed:**
```bash
# Revert to direct Firestore write (no ingest endpoint)
flutter run  # Without --dart-define
```

---

## Phase 4: Enforce Firestore (Day 4+)

**Duration:** Immediate  
**Testers affected:** All feedback submissions (direct Firestore or via ingest)  
**Blast radius:** Firestore, but already protected by auth rules + ingest function

### Step 4.1: Prerequisites Met?

Before proceeding, confirm:
- [ ] Phase 3 monitoring complete (24+ hours with 0 functional errors)
- [ ] Error rate on Cloud Functions < 1%
- [ ] Both Android and iOS apps generating tokens

### Step 4.2: Enable App Check Enforcement for Firestore

1. Firebase Console → Build → App Check → **APIs tab**
2. Find **Cloud Firestore**
3. Click **Enforce** (or toggle if already present)
4. Select:
   - **Enforcement level:** Enforce (not monitor-only)
   - **Affected services:** Cloud Firestore

### Step 4.3: Confirm Firestore Writes Succeed

1. Internal testers submit feedback again
2. Check Firestore Console → feedback_submissions collection
3. Verify new submissions appear without errors

**Success criteria:**
- ✅ Feedback submissions succeed
- ✅ New documents in Firestore
- ✅ Firebase Console shows 0 blocked requests

### Step 4.4: Monitor for 24+ Hours

Watch for:
- Firestore write errors (401 Unauthorized, 403 App Check invalid)
- User complaints about feedback not being saved
- Offline queue growing (sign of persistent failures)

---

## Rollback Procedures

### If Cloud Functions Enforcement Fails (Phase 3)

```bash
# Option 1: Disable ingest endpoint (revert to direct Firestore)
flutter run  # No --dart-define

# Option 2: Disable function enforcement (requires redeploy)
# Edit firebase/functions/index.js:
# Change enforceAppCheck: true → enforceAppCheck: false
# Then: firebase deploy --only functions:submitFeedbackIngest
```

### If Firestore Enforcement Causes Issues (Phase 4)

1. Firebase Console → Build → App Check → APIs
2. Find **Cloud Firestore**
3. Click **Stop Enforcing**
4. Revert to **Monitor mode** (if available)
5. Investigate root cause before re-enabling

---

## Monitoring Dashboards

### Firebase Console Checks

**Daily checks during rollout:**

1. **App Check → Apps tab**
   - Token count increasing? ✅ Yes = tokens flowing

2. **Functions → submitFeedbackIngest**
   - Error rate < 1%? ✅ Yes = function healthy

3. **Firestore → feedback_submissions collection**
   - Documents being created? ✅ Yes = writes succeeding

4. **Firestore → Rules**
   - Denials = 0? ⚠️ Watch for auth failures

### Log Patterns

**Success pattern (Functions):**
```
200 OK: status=ok, risk_score=0
```

**Failure patterns:**
```
401 Unauthorized: missing_bearer_token     ← Auth missing
403 Forbidden: bot_detected                ← Honeypot filled
429 Too Many Requests: rate_limited        ← Per-IP limit hit
```

---

## Timeline Summary

| Phase | Date | Action | Risk | Duration |
|-------|------|--------|------|----------|
| 1 | Day 1 | Register debug apps, test | None | 2 hours |
| 2 | Day 2 | Register release sig, monitor | Low | 24 hours |
| 3 | Day 3 | Functions enforce (already active) | Low | 24 hours |
| 4 | Day 4+ | Firestore enforce | Low | Immediate |

---

## FAQ

**Q: Can I skip Phase 1?**
A: No. Debug validation catches config issues early without affecting release users.

**Q: What if my release keystore doesn't exist?**
A: Create it first using [docs/ANDROID_SIGNING_GUIDE.md](ANDROID_SIGNING_GUIDE.md#L25). You'll need it for Play Store release anyway.

**Q: Can I enforce Firestore before Functions?**
A: Not recommended. Functions are your enforcement boundary (IP limits, bot scoring). Firestore enforcement comes after Functions prove stable.

**Q: What happens to offline feedback?**
A: Offline submissions are queued in SharedPreferences and retried when online. If they lack App Check tokens, they'll fail after enforcement. The retry logic in `FeedbackSubmissionService` will queue them again.

**Q: Can I test App Check enforcement locally?**
A: Debug provider works locally. Release enforcement requires real Play Store / App Store infrastructure. Test release builds on internal testing track.

---

## References

- [Deployed Cloud Function](https://submitfeedbackingest-c7nfsmjnbq-uc.a.run.app)
- [Firestore Rules](app/firestore.rules)
- [Feedback Service Implementation](app/lib/core/feedback/feedback_submission_service.dart#L138)
- [Firebase Bootstrap (App Check Init)](app/lib/core/bootstrap/firebase_bootstrap_service.dart#L176)
- [Firebase Feedback Storage Docs](firebase-feedback-storage.md#L32)
- [Android Signing Guide](ANDROID_SIGNING_GUIDE.md#L25)
- [Play Integrity Context](play-integrity-setup.md#L1)
