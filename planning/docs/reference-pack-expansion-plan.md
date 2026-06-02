# Reference Pack Expansion Plan

## Purpose
Build on the shipped M3/206 reference-pack system and extend it into a broader consent-based reference-data loop for categories, locations, and other app-managed lists, while adding a path for previously unknown user-entered values to be reviewed and promoted into backend packs for all users.

## Scope
This plan covers:
- Barcode catalogs
- Categories
- Locations
- Generic reference lists
- Consent-based unknown-value telemetry capture from users
- Western Hemisphere regional coverage for barcode and reference packs
- Locale-aware reference labels aligned with supported app language packages

Current implementation status:
- M3/206 now covers barcode catalogs, categories, and locations with manifest-backed download, validation, activation, rollback, and offline reuse.
- This plan now focuses on the remaining generic `reference_list` and consent-based unknown-value promotion work.

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

Regionalization and localization model:
- Region code follows BCP-47 country form where possible (examples: `ca`, `us`, `mx`, `br`, `ar`, `cl`, `co`, `pe`).
- Locale uses app-supported language tags (examples: `en`, `fr-CA`, `es-419`, `pt-BR`).
- Packs may include one or both dimensions:
	- region-specific data packs (barcode sets, location defaults)
	- locale-specific label packs (category/location display strings and synonyms)

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
- Rollout is staged by region to control quality and payload growth.

## Unknown-Value Bubble-Up Flow
When a user enters a value that the app cannot resolve locally:
1. App shows the normal unknown-value fallback UI.
2. If anonymous data collection is enabled, app emits a minimal telemetry event for the unknown value.
3. Backend telemetry store captures unknown-value events separately from authoritative packs.
4. Data ops review, normalize, dedupe, and promote accepted values into the next pack release.
5. The updated pack is published and becomes available to all users on next sync.

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

## Telemetry Event Contract

Canonical event names:
- `unknown_category_entered`
- `unknown_location_entered`
- `unknown_reference_value_entered`

Emit points:
- Inventory add/edit flows when category input is not recognized
- Inventory add/edit flows when location input is not recognized
- Any future reference-list field where value resolution fails

Required event properties:
- `value_type`: `category` | `location` | `reference_list` | `other`
- `value_normalized`: normalized lowercase value with collapsed whitespace
- `value_hash`: SHA-256 hash of normalized value (for safe aggregation)
- `context`: `inventory_add` | `inventory_edit` | `quick_add` | `other`
- `locale`
- `region`
- `app_version`
- `platform`
- `analytics_consent`: `true`

Optional event properties:
- `value_raw`: raw input value (only if policy approves and still non-PII)
- `source_pack_version`: currently active pack version for this value type

Do not include:
- User identifiers, email, phone, IP address, precise location, free-form notes with potential PII.

Dedup guidance:
- Client-side: emit once per normalized value per session/context.
- Backend-side: aggregate by `value_hash + value_type + region + locale`.

## Western Hemisphere Expansion Plan

Target regions (initial):
- `ca`, `us`, `mx`, `br`, `ar`, `cl`, `co`, `pe`

Target locale packs (initial):
- `en`
- `fr-CA`
- `es-419`
- `pt-BR`

Rollout waves:
1. Wave A: `ca`, `us` with `en`, `fr-CA`, `es-419`
2. Wave B: `mx`, `co`, `pe`, `cl` with `es-419`
3. Wave C: `br`, `ar` with `pt-BR`, `es-419`

Data quality gates per wave:
- Unknown-value telemetry volume trending down in target region.
- Curation backlog for region below threshold.
- Pack activation failure rate below threshold.
- Pack size budget within mobile constraints.

## Artifact Strategy for Regional + Locale Packs

Recommended object paths:
- `reference-packs/barcode_catalog/{region}/{version}.json`
- `reference-packs/categories/{region}/{locale}/{version}.json`
- `reference-packs/locations/{region}/{locale}/{version}.json`
- `reference-packs/reference_list/{list_id}/{region}/{locale}/{version}.json`

Manifest entry guidance:
- Keep one descriptor per `(type, region, locale)` tuple where locale is relevant.
- Continue using checksum + minimum app version per descriptor.
- Introduce optional `locale` field in descriptor for locale-scoped packs.

Backward compatibility:
- If locale-scoped pack is unavailable, fallback order is:
	1) region + locale
	2) region default locale
	3) global default pack
	4) bundled defaults

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
- Add locale-aware category/location display labels with region fallback.

### Phase 2: Consent-Based Unknown-Value Suggestions
- Add unknown-value telemetry events in inventory/category/location edit and add flows.
- Gate event emission on anonymous analytics consent.
- Add extraction workflow to review unknown values from telemetry exports.
- Track promotion rate from unknown-value telemetry into packs.

### Phase 2a: Implementation Tasks (Telemetry)
- [ ] Add event emitters in inventory add/edit flows for unknown category and location values.
- [ ] Add normalization + hashing utility for unknown reference values.
- [ ] Add consent gate check (`analytics_consent == true`) before emission.
- [ ] Add unit tests for emitter guardrails (consent off => no event; consent on => event emitted).
- [ ] Add analytics extraction query templates for top unknown values by region and locale.
- [ ] Add manual curation SOP: export -> review -> dedupe -> promote -> republish.

### Phase 2b: Western Hemisphere Coverage
- [ ] Add region-aware manifest selection in the app bootstrap path.
- [ ] Add locale-aware category/location pack loading with fallback chain.
- [ ] Define per-region artifact generation jobs and release cadence.
- [ ] Add pack-size budgets and CI checks per region/locale pack.
- [ ] Add rollout feature flag/kill-switch per region wave.

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
- Whether locale labels live in the same pack payload as value definitions or in separate locale overlay packs.

## Immediate Next Steps
1. Define unknown-value telemetry event schema and naming for inventory/category/location interactions.
2. Implement event emission in relevant add/edit flows, gated by anonymous analytics consent.
3. Add `categories` and `locations` to the manifest generator and pack publishing flow.
4. Add optional `locale` support to manifest descriptors and pack selectors.
5. Define Wave A (`ca`, `us`) data sourcing and curation process.
6. Define manual extraction and curation workflow from telemetry exports.
7. Extend security hardening to cover telemetry-based unknown-value intake and privacy controls.
