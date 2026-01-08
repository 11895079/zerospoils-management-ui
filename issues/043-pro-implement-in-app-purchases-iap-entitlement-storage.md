## Context
To sell Pro, you need reliable purchase flows and entitlement checks.

## Goal
Implement IAP purchase, restore, and entitlement verification flows.

## Expected behavior
- User can purchase, restore purchases, and see Pro unlocked
- Entitlements persist across reinstalls (as supported by store)

## Acceptance criteria (Definition of Done)
- [ ] IAP library integrated for iOS and Android
- [ ] Paywall screen implemented (triggered by Pro actions)
- [ ] Restore purchases flow implemented
- [ ] Entitlement state stored locally and refreshed on app start
- [ ] Telemetry for purchase funnel events (paywall_view, purchase_start, purchase_success, purchase_restore)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Discount codes / promotional offers.

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
