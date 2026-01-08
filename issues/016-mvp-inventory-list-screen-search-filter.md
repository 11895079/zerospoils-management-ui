## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Inventory list screen (search/filter) with tests and telemetry.

## Expected behavior
- Behavior matches wireframes and MVP spec
- Works offline without requiring login
- Error and empty states handled

## Acceptance criteria (Definition of Done)
- [ ] UI implemented and integrated into navigation
- [ ] State management implemented with repository layer
- [ ] CRUD persists to local storage (where applicable)
- [ ] Telemetry events emitted for key actions (as applicable)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Cloud sync
- Receipt scanning
- Household sharing

## Implementation notes
- Follow design tokens in theme.
- Keep domain/data/ui separation.
- Add widget tests where feasible.

## Test plan
- Steps:
  1. Fresh install.
  2. Use the feature.
  3. Restart app; confirm persistence.
- Scenarios:
  - Airplane mode.
  - Invalid inputs.
  - Date edge cases.

## Dependencies
- None
