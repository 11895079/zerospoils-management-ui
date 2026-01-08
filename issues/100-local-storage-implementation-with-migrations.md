## Context
Offline-first is a core promise; storage must be reliable.

## Goal
Implement local persistence for Items, ShoppingList, and Events.

## Expected behavior
- CRUD persists across restarts
- Migration strategy exists

## Acceptance criteria (Definition of Done)
- [ ] Repository layer abstracts storage
- [ ] Migration mechanism documented + tested
- [ ] Optional encryption-at-rest evaluated and decision recorded
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Not defined

## Implementation notes
- Consider Drift if relational queries needed.
- Add versioned migrations and tests.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
