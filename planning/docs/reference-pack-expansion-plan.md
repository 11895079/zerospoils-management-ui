# Reference Pack Expansion Plan

## Purpose
Extend M3/206 from barcode packs into a broader reference-data system for categories, locations, and other app-managed lists, while adding a consent-based loop so previously unknown user-entered values can be reviewed and promoted into backend packs for all users.

## Scope
This plan covers:
- Barcode catalogs
- Categories
- Locations
- Generic reference lists
- Consent-based unknown-value feedback from users

Out of scope:
- Full cloud sync of user data
- Per-user targeting or A/B testing for reference packs
- Direct editing of downloaded packs in the app
- Executable code delivery

## Proposed Pack Model
Use one manifest and one pack schema family across all reference data types.

Supported types:
- `barcode_catalog`
- `categories`
- `locations`
- `reference_list`

Common pack attributes:
- `type`
- `region`
- `version`
- `checksum`
- `minimum_app_version`
- `download_url`
- optional `generated_at`

Principles:
- Versioned pack files are immutable.
- Manifest is the only mutable pointer.
- Client precedence stays: `user-defined / learned local data -> downloaded pack -> bundled default`.
- Remote Config only points to the manifest URL; it never carries the actual data payload.

## Unknown-Value Bubble-Up Flow
When a user enters a value that the app cannot resolve locally:
1. App shows the normal unknown-value fallback UI.
2. App asks for explicit opt-in to submit the value for catalog improvement.
3. If the user consents, the app submits a minimal suggestion payload.
4. Backend stores the suggestion separately from the authoritative pack.
5. Data ops review, normalize, dedupe, and promote accepted values into the next pack release.
6. The updated pack is published and becomes available to all users on next sync.

### Consent Rules
- Consent must be explicit and revocable.
- Submission is opt-in only; default is no upload.
- Payload must avoid PII unless the user explicitly provides it and it is needed for follow-up.
- Unknown-value submissions are for product catalog improvement, not for telemetry.

### Suggested Minimal Payload
- `value`
- `value_type` (`barcode`, `category`, `location`, `other`)
- `region`
- `context` (screen or workflow name)
- `app_version`
- `locale`
- `consent_granted` (`true`)
- optional `user_comment`

## Backend Workflow
Recommended backend flow:
- Store consented unknown-value submissions in a separate review collection or queue.
- Add moderation / curation tooling to approve, reject, or merge suggestions.
- Convert accepted entries into the canonical reference-data source of truth.
- Regenerate the affected pack and manifest entry.
- Publish the new pack version and update the manifest pointer.

## Firebase Guidance
Because the project is already using Firebase for manifest discovery:
- Use Firebase Storage for hosting pack files and manifests.
- Use Remote Config for the manifest URL pointer only.
- Use App Check gradually for any protected submission or review endpoints.
- Keep public pack reads until the delivery path is moved behind an App Check-aware flow.

## Security and Privacy Controls
- Enforce user consent before any upload.
- Strip PII from suggestion payloads by default.
- Apply rate limiting for suggestion submission.
- Require auth for submission if the payload can be tied to a user account.
- Keep moderation and promotion outside the client app.
- Log upload and promotion events for auditability.

## Rollout Phases
### Phase 1: Categories and Locations Packs
- Add manifest support for `categories` and `locations`.
- Keep barcode pack delivery unchanged.
- Add diagnostics to show active pack version per type.
- Add tests for precedence and offline fallback.

### Phase 2: Consent-Based Unknown-Value Suggestions
- Add a suggestion submission endpoint or Firestore queue.
- Add user consent UI in the unknown-value flow.
- Add moderation workflow for suggested values.
- Track promotion rate from suggestions into packs.

### Phase 3: Pack Promotion Pipeline
- Automate manifest generation for all pack types.
- Add lifecycle rules for old pack versions.
- Add publish checks for checksum, schema version, and minimum app version.
- Add rollback by repointing manifest to the last known-good version.

### Phase 4: Hardening and Scale
- Introduce App Check-aware protected delivery path if abuse warrants it.
- Add anomaly alerts for suggestion spikes and pack download spikes.
- Add admin tooling for curation and rollback.

## Open Decisions
- Whether unknown-value submissions should use the existing feedback pipeline or a dedicated collection/endpoint.
- Whether categories/locations should be curated manually first or bootstrapped from seeded lookup tables.
- Whether pack promotion should be manual, scheduled, or partially automated.

## Immediate Next Steps
1. Define the minimal schema for unknown-value suggestions.
2. Choose the submission path: reuse feedback storage or create a dedicated collection.
3. Add `categories` and `locations` to the manifest generator and pack publishing flow.
4. Add consent UI and moderation workflow requirements to the relevant issue.
5. Extend security hardening to cover suggestion intake and privacy controls.
