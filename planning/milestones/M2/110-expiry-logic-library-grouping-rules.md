## Context
We need consistent grouping: expiring today/soon/expired.

## Goal
Implement a testable expiry classification library.

## Expected behavior
- Items classified into buckets based on today() and settings
- Timezone and date-only comparisons handled

## Acceptance criteria (Definition of Done)
- [ ] Unit tests cover boundary cases
- [ ] Buckets configurable (Today, 1–3, 4–7, Expired)
- [ ] Consistent behavior on iOS/Android
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Not defined

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
