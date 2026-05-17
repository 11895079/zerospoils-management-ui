# Firebase Feedback Storage (M4 Feedback Drawer)

This document defines the Firestore storage contract for in-app feedback submitted from the feedback drawer.

## Collection

- Collection: `feedback_submissions`
- Write path: client app (Flutter) via `FeedbackSubmissionService`
- Read path: ops/admin workflows outside the app (Firebase console, export pipeline)

## Document schema

Required fields:

- `message` (`string`, 1-2000 chars)
- `category` (`string`): `bug_report` | `feature_request` | `ux_feedback` | `other`
- `source` (`string`): `settings` | `drawer`
- `device_fingerprint` (`string`, 8-64 chars): locally generated stable device token used for write throttling
- `platform` (`string`): `android` | `ios` | `web` | `macos` | `windows` | `linux` | `fuchsia`
- `app_version` (`string`)
- `build_number` (`string`)
- `locale` (`string`)
- `status` (`string`): `new`
- `user_id` (`string`): must match `request.auth.uid`
- `created_at` (`timestamp`): server timestamp
- `created_at_client` (`string`, ISO-8601)

Optional fields:

- `email` (`string` | `null`)

## Security model

- Client can only `create` feedback docs.
- Client cannot read/update/delete feedback docs.
- Rule validation enforces schema and value constraints.
- Non-anonymous authentication is required: `request.auth != null`, provider is not `anonymous`, and `user_id` must match `request.auth.uid`.
- Write rate-limit is enforced via document id pattern: one submission per 10-minute window per `user_id + device_fingerprint`.
- Firestore rules cannot reliably rate-limit by client IP address because IP is not exposed to rules.
- App Check should be enabled for Firestore in Firebase Console to require valid app attestation tokens.
- Rules live in [app/firestore.rules](../app/firestore.rules).

## Operational notes

- The app includes an offline queue fallback in local preferences. If immediate Firestore write fails, the payload is queued and retried on the next submit attempt.
- The app can use a backend ingestion endpoint when launched with `--dart-define=FEEDBACK_INGEST_URL=<https endpoint>`. This endpoint supports App Check enforcement, per-IP throttling, and bot scoring.
- For analytics and reporting, export feedback from Firestore periodically into your local analysis database.

## IP throttling and bot scoring endpoint

For protections Firestore rules cannot enforce directly (IP-based limits and bot scoring), use:

- Function source: `firebase/functions/index.js`
- Endpoint: `submitFeedbackIngest` (HTTP, App Check enforced)
- Behavior:
	- Verifies Firebase Auth ID token
	- Requires App Check token (`X-Firebase-AppCheck`)
	- Applies per-user+IP 10-minute rate limiting
	- Applies basic bot-risk scoring (honeypot + heuristics)
	- Writes validated feedback to Firestore

## Deployment

This repo includes `firebase.json` for Firebase CLI deployments.

To deploy Firestore rules from the repo root:

1. Authenticate with Firebase CLI (`firebase login`) and select the project (`firebase use <project-id>`).
2. Run `firebase deploy --only firestore:rules`.

Manual fallback in Firebase Console:

1. Open Firestore Database > Rules.
2. Paste contents of [app/firestore.rules](../app/firestore.rules).
3. Publish rules.

For backend ingestion deployment (after `cd firebase/functions && npm install`):

1. From repo root, run `firebase deploy --only functions:submitFeedbackIngest`.
2. Add the deployed HTTPS URL as `FEEDBACK_INGEST_URL` via `--dart-define` in build/run config.
3. In Firebase Console, enable App Check enforcement for both Firestore and Cloud Functions.
