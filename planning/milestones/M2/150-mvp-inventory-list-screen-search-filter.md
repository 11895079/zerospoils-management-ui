## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Inventory list screen (search/filter) with tests and telemetry.

## Expected behavior
- Behavior matches wireframes and MVP spec
- Works offline without requiring login
- Error and empty states handled
- Inventory list surfaces prepared items distinctly (prepared label/badge + prepared date)
- Category chips include a Prepared filter

## Acceptance criteria (Definition of Done)
- [ ] UI implemented and integrated into navigation
- [ ] State management implemented with repository layer
- [ ] CRUD persists to local storage (where applicable)
- [ ] Search bar with clear button (X icon) that resets filter when tapped
- [ ] Prepared items render a Prepared label/badge and show prepared date (e.g., “Prepared Jan 10”)
- [ ] Category chips include Prepared and filter prepared items correctly
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
**Automated:**
- Widget test: prepared item shows Prepared label and prepared date text
- Widget test: Prepared filter chip shows only prepared items
- Widget test: search clear button resets filter

**Manual:**
1. Add prepared item with prepared date
2. Verify list shows Prepared badge + date
3. Tap Prepared chip → only prepared items shown
4. Restart app; prepared item still displays correctly

## Dependencies
- None
