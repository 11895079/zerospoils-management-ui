## Context
We need consistent instrumentation to measure adoption/retention and validate hypotheses.

## Goal
Define MVP event names and properties, with privacy-by-design.

## Expected behavior
- Event list exists for key flows
- No PII in telemetry by default

## Acceptance criteria (Definition of Done)
- [ ] Create `docs/telemetry.md` with event schema
- [ ] Include funnel events: item_add, item_edit, expiring_view, reminder_opened, item_mark_used, item_mark_wasted, shopping_add, shopping_convert
- [ ] Define standard properties (platform, app_version, category, location, lead_time_days)
- [ ] Define opt-in/opt-out strategy
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full analytics dashboard.

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
**Automated:**
- JSON schema validation for `docs/telemetry.md` event definitions
- Script to verify all event names follow naming convention (lowercase_underscore)
- Verify no PII fields (email, phone, exact_location) in standard properties

**Manual:**
1. Review event list with engineering and product teams
2. Trace each MVP feature to at least one telemetry event
3. Validate opt-in/opt-out strategy complies with privacy policy
4. Confirm property types are consistent (e.g., category always enum)

## Dependencies
- None
