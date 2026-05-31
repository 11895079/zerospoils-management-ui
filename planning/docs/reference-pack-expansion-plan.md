# Reference Pack Expansion Plan

## Purpose
Extend M3/206 from barcode packs into a broader reference-data system for categories, locations, and other app-managed lists, while adding a consent-based loop so previously unknown user-entered values can be reviewed and promoted into backend packs for all users.

## Scope
This plan covers:
- Barcode catalogs
- Categories
- Locations
- Generic reference lists
- Consent-based unknown-value telemetry capture from users

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
2. If anonymous data collection is enabled, app emits a minimal telemetry event for the unknown value.
3. Backend telemetry store captures unknown-value events separately from authoritative packs.
5. Data ops review, normalize, dedupe, and promote accepted values into the next pack release.
6. The updated pack is published and becomes available to all users on next sync.

### Consent Rules
- Unknown-value capture is tied to the existing anonymous data collection consent toggle.
- If anonymous data collection is disabled, no unknown-value telemetry is emitted.
- Payload must avoid PII and contain only catalog-improvement fields.
- Unknown-value telemetry is for product catalog improvement, not user profiling.

### Suggested Minimal Payload
- `value`
- `value_type` (`barcode`, `category`, `location`, `other`)
- `region`
- `context` (screen or workflow name)
- `app_version`
- `locale`
- `analytics_consent` (`true`)

## Backend Workflow
Recommended backend flow:
- Store consented unknown-value telemetry in an exportable review dataset.
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
- Strip PII from unknown-value telemetry payloads by default.
- Apply rate limiting and dedupe on ingestion/export processing.
- Keep moderation and promotion outside the client app.
- Log extraction, curation, and promotion events for auditability.

## Rollout Phases
### Phase 1: Categories and Locations Packs
- Add manifest support for `categories` and `locations`.
- Keep barcode pack delivery unchanged.
- Add diagnostics to show active pack version per type.
- Add tests for precedence and offline fallback.

### Phase 2: Consent-Based Unknown-Value Suggestions
- Add unknown-value telemetry events in inventory/category/location edit and add flows.
- Gate event emission on anonymous analytics consent.
- Add extraction workflow to review unknown values from telemetry exports.
- Track promotion rate from unknown-value telemetry into packs.

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
- Whether categories/locations should be curated manually first or bootstrapped from seeded lookup tables.
- Whether pack promotion should be manual, scheduled, or partially automated.

## Immediate Next Steps
1. Define unknown-value telemetry event schema and naming for inventory/category/location interactions.
2. Implement event emission in relevant add/edit flows, gated by anonymous analytics consent.
3. Add `categories` and `locations` to the manifest generator and pack publishing flow.
4. Define manual extraction and curation workflow from telemetry exports.
5. Extend security hardening to cover telemetry-based unknown-value intake and privacy controls.
