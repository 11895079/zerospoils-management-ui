## Context
IoT is optional/premium; define a stable contract before building devices.

## Goal
Specify how external devices/HA interact with ZeroSpoils.

## Expected behavior
- Clear event model exists
- Auth and trust boundaries defined

## Acceptance criteria (Definition of Done)
- [ ] Define inbound commands (add_item, update_item, mark_used, mark_wasted)
- [ ] Define outbound events (item_expiring_soon, item_expired, shopping_list_changed)
- [ ] Define transport options (HTTP webhooks, MQTT) and pick one for MVP
- [ ] Define authentication (scopes, rotation)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Building device firmware.

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
