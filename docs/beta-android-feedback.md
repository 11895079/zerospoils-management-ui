# Firebase App Distribution — Tester Feedback Workflow

## Overview

This document defines the repeatable workflow for collecting Firebase App Distribution tester feedback, normalising it into actionable triage records, and linking it to ZeroSpoils beta operations.

Firebase App Distribution allows testers to **submit in-app feedback with screenshots** directly from installed beta builds (Android 8+ / iOS). This guide covers the full lifecycle from build distribution to triage.

---

## 1. Firebase Capabilities & Limitations

### What Firebase App Distribution Supports
- In-app feedback with screenshots via the SDK's shake gesture or overlay widget
- Tester invitation management (email-based groups)
- Build metadata: version code, version name, distribution ID
- Feedback visible in the Firebase Console under **App Distribution → Feedback**

### Known Limitations (as of 2026-04)
- The Firebase App Distribution REST API does **not** expose tester feedback records for automated bulk export
- Feedback must be accessed via the Firebase Console UI or the console export mechanism
- Per-feedback screenshot URLs in the console expire — screenshots should be downloaded promptly
- There is no official webhook for real-time feedback notifications

### Recommended Retrieval Path
Given the API gap, the chosen retrieval path is:

1. **Manual console review** — team member visits Firebase Console → App Distribution → Feedback tab on a defined cadence (e.g., every beta cycle or weekly)
2. **CSV export** — use the Firebase Console "Export" button to download feedback as a CSV when the volume justifies scripted normalisation
3. **Scripted normalisation** — run `scripts/normalize_firebase_feedback.py` on exported CSV to produce the standard triage schema

---

## 2. Normalised Feedback Schema

Each tester feedback record is normalised into the following schema. Fields marked `*` are required.

```json
{
  "feedback_id": "f2a9b61ddbe79f0bb4e2",
  "platform": "android",
  "build_version": "1.2.3",
  "build_number": "42",
  "release_channel": "internal_beta",
  "message": "The expiry scan button crashes on my Pixel 6.",
  "screenshot_reference": "screenshots/feedback-2026-04-11-001.png",
  "submitted_at": "2026-04-11T14:23:00Z",
  "triage_status": "new",
  "tester_id_hash": "sha256:abc123..."
}
```

| Field | Type | Notes |
|---|---|---|
| `feedback_id` * | string | Stable ID derived from the composite deduplication key |
| `platform` * | string | `android` or `ios` |
| `build_version` * | string | Semantic version string from the build (e.g. `1.2.3`) |
| `build_number` * | string | Monotonic build number (Android `versionCode` / iOS `CFBundleVersion`) |
| `release_channel` | string | `internal_beta`, `external_beta`, or `closed_test` |
| `message` * | string | Tester's feedback text, verbatim |
| `screenshot_reference` | string | Relative path to downloaded screenshot, or empty string |
| `submitted_at` * | ISO 8601 string | UTC timestamp of submission |
| `triage_status` * | string | `new`, `in_progress`, `resolved`, `wont_fix` |
| `tester_id_hash` | string | SHA-256 of tester email — not the raw email |

**Privacy note:** Raw tester email addresses are **never** stored in the normalised schema. Only the SHA-256 hash is retained to allow deduplication without exposing PII.

---

## 3. Tester Instructions (Android Beta)

Include the following in your Firebase App Distribution release notes for every beta build:

```
──────────────────────────────────────────────
How to submit feedback from this beta build:

1. Open the ZeroSpoils app.
2. Shake your device gently OR tap the floating feedback icon
   (enabled in Settings → Developer → Beta Feedback).
3. A screenshot is taken automatically. Draw or annotate if helpful.
4. Add a short message describing what you saw or experienced.
5. Tap "Send Feedback" — your report goes directly to the team.

Please include:
• What you were trying to do
• What happened instead
• Your device model and Android version (shown under Settings → About)

Thank you for helping make ZeroSpoils better!
──────────────────────────────────────────────
```

---

## 4. Step-by-Step Retrieval Runbook

### Prerequisites
- Firebase CLI installed: `npm install -g firebase-tools`
- Authenticated: `firebase login`
- Python 3.9+ with `planning/requirements.txt` dependencies installed:
  ```bash
  cd planning && python3 -m venv .venv && source .venv/bin/activate
  pip install -r requirements.txt
  ```

### Step 1 — Export feedback from Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com) → select ZeroSpoils project
2. Navigate to **App Distribution → Feedback**
3. Set the date range to the current beta cycle
4. Click **Export to CSV** (top-right)
5. Save the file as `tmp/firebase_feedback_<YYYYMMDD>.csv`

### Step 2 — Download screenshots
1. For each feedback record with a screenshot, click the thumbnail in the console
2. Right-click → Save image to `docs/user_feedback/screenshots/feedback-<YYYYMMDD>-<NNN>.png`
3. Note the filename for the `screenshot_reference` field

### Step 3 — Normalise feedback records
```bash
cd /path/to/zerospoils
python scripts/normalize_firebase_feedback.py \
  --input tmp/firebase_feedback_20260411.csv \
  --output tmp/triage_20260411.json \
  --screenshot-dir docs/user_feedback/screenshots
```

Output is a JSON array of normalised feedback objects conforming to the schema in §2.

### Step 4 — Create GitHub issues from triage output
For each `new` record in the triage JSON that warrants a bug report or feature request:
1. Review the message and screenshot
2. File a GitHub issue with label `tester-feedback` and milestone `MX`
3. Link the composite deduplication key in the issue body for traceability: `platform|build_number|submitted_at|message_hash`
  Prefer linking `feedback_id` directly, and include the composite key only when debugging dedup collisions.
4. Update `triage_status` to `in_progress` in the triage JSON

### Step 5 — Archive triage output
```bash
mv tmp/triage_20260411.json docs/user_feedback/triage_20260411.json
git add docs/user_feedback/triage_20260411.json
git commit -m "chore: archive tester feedback triage for 2026-04-11"
```

---

## 5. Security & Privacy Guidance

| Concern | Mitigation |
|---|---|
| Tester PII in feedback messages | Do not log or store raw tester emails; use SHA-256 hash only |
| Screenshot data retention | Delete raw screenshots after triage cycle; keep only issue-linked ones |
| Firebase Console access | Restrict App Distribution admin role to the team; use IAM |
| CSV export contents | Treat exported CSVs as confidential; add `tmp/*.csv` to `.gitignore` |
| Feedback script outputs | Store normalised JSON under `docs/user_feedback/` (no raw PII) |

---

## 6. Mapping Feedback to Triage Surfaces

| Feedback type | Triage surface | Label |
|---|---|---|
| Crash / unexpected close | GitHub Issue (link Crashlytics report) | `bug`, `tester-feedback` |
| Confusing UI | GitHub Issue or planning issue comment | `ux`, `tester-feedback` |
| Feature request | Planning issue or new backlog issue | `enhancement`, `tester-feedback` |
| Performance complaint | GitHub Issue with profiling label | `performance`, `tester-feedback` |
| Positive feedback | No action required; log in release notes | — |

---

## Dependencies

- M4/270 Android beta distribution setup (Firebase project and google-services.json)
- M4/280 In-app feedback entry point (shake gesture + overlay widget)
- M4/285 Settings feedback entry
- M4/370 Closed-testing backend security hardening (Firebase IAM and access controls)
