## Context
We need consistent, privacy-first telemetry to measure adoption and validate reminder effectiveness. The taxonomy lives in `docs/telemetry.md`.

## Goal
Implement a telemetry system and instrument the core funnel events across the MVP in a way that:
- Works offline
- Respects consent
- Avoids PII
- Can later support cloud export (Supabase) without rewriting app logic

## Expected behavior
- All events defined in `docs/telemetry.md` are emitted at the correct moments with required properties.
- Telemetry is “local by default”; cloud export is disabled unless explicitly enabled by the user and gated by a feature flag.
- Events persist locally and can be exported/uploaded later.

## Acceptance criteria (Definition of Done)
- [ ] Implement a `TelemetryClient` interface used throughout the app (no direct vendor SDK calls from feature code).
- [ ] Implement a local telemetry sink that persists events offline (DB table or JSONL file).
- [ ] Add consent controls:
  - [ ] “Share anonymous usage data” toggle (controls whether we log at all).
  - [ ] “Enable cloud analytics export” toggle (hidden unless feature flag enabled; default OFF).
- [ ] Instrument the core events from `docs/telemetry.md` at minimum:
  - `app_installed`, `onboarding_completed`
  - `item_added`, `expiry_date_scanned`, `item_edited`
  - `inventory_viewed`, `expiring_viewed`
  - `reminder_opened`
  - `item_consumed`, `item_wasted`
  - `shopping_item_added`, `shopping_item_purchased`, `shopping_converted` (if shopping list is implemented)
- [ ] Enforce standard properties on all events: `platform`, `app_version`, `timestamp`, `session_id`.
- [ ] Add schema validation in debug builds: reject events missing required properties or containing disallowed keys (PII).
- [ ] Update `docs/telemetry.md` if any new event names/properties are introduced during implementation.

## Out of scope
- Production analytics dashboards.
- Differential privacy/anonymization pipeline (separate issue).

## Implementation notes
- Keep event names/property keys exactly as in `docs/telemetry.md`.
- Design for portability: implement cloud export (when added) behind the telemetry sink abstraction.

## Test plan
**Automated:**
- Unit tests: each instrumented event emits correct name + required properties; PII keylist is rejected.
- Widget tests: navigation to Inventory/Expiring screens triggers `inventory_viewed` / `expiring_viewed`.
- Integration test: consent OFF → no events persisted; consent ON → events persisted; cloud export toggle OFF → no network attempted.

**Manual:**
1. Fresh install; complete onboarding; verify `app_installed` and `onboarding_completed` appear in local log.
2. Add/edit items and open screens; verify view + CRUD events logged.
3. Tap a reminder; verify `reminder_opened` logged and item action attribution works.

## Dependencies
- `docs/telemetry.md`
- `200-mvp-reminder-interaction-logging-local.md`
