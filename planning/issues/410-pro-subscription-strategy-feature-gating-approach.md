## Context
You need a clear, implementable plan for Pro feature gating before building Pro features.

## Goal
Define subscription tiers and gating approach that works on iOS/Android.

## Expected behavior
- Pro features are clearly defined and gated
- Team understands payment constraints

## Acceptance criteria (Definition of Done)
- [ ] Define tiers (Free, Pro, Family/Household Pro optional)
- [ ] Decide payment approach (native IAP preferred) and document constraints
- [ ] Define paywall UX states and copy
- [ ] List which features are Pro: receipt scanning, batch photo capture, household sync, advanced insights, IoT/HA hooks
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Implementing purchases (separate issue).

## Implementation notes
- Default to native IAP for app stores.
- Keep a server-side entitlement option for future.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
