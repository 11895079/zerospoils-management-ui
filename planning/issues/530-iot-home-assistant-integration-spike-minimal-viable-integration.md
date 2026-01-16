## Context
Validate effort and user value before committing to a full HA integration.

## Goal
Build a minimal HA integration that can add an item and display expiring items.

## Expected behavior
- HA can call a ZeroSpoils service to add an item
- HA can display a sensor of expiring count

## Acceptance criteria (Definition of Done)
- [ ] Choose HA delivery model (custom integration / HACS) and document
- [ ] Implement HA service: zerospoils.add_item
- [ ] Implement HA sensor: zerospoils.expiring_count (or similar)
- [ ] Document setup steps and limitations in `docs/iot/home-assistant-spike.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full dashboard/cards polish.

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
