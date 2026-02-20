## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Shopping list UI (Next Shop) with tests and telemetry.

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
- Follow design tokens in theme; reuse `AppTextStyles`, `AppSpacing`, and `AppColors`.
- Keep domain/data/ui separation; UI reads from repository provider and delegates writes.
- Sections: "Next Shop" (unpurchased) and "Purchased" with clear headers.
- Add quick actions: toggle purchased, delete item, and add new item (bottom sheet or inline form).
- Telemetry events (document properties):
  - `shopping_list_viewed` {source_screen}
  - `shopping_item_added` {item_id}
  - `shopping_item_toggled` {item_id, is_purchased}
  - `shopping_item_deleted` {item_id}
  - `shopping_items_converted` {count}
- Accessibility: ensure checkboxes and action buttons have labels and 44pt tap targets.

## Test plan
**Automated:**
- Widget test: empty state renders with add action
- Widget test: add item creates entry and persists to repository
- Widget test: toggle purchased moves item between sections
- Widget test: delete removes item from list
- Widget test: convert purchased triggers conversion flow and clears purchased section
- Unit test: repository CRUD for shopping list items
- Telemetry test: events emitted for view/add/toggle/delete/convert

**Manual:**
1. Fresh install; open Shopping List; verify empty state
2. Add 2 items; verify they appear in "Next Shop"
3. Toggle one as purchased; verify it moves to "Purchased"
4. Convert purchased items; verify inventory updated and purchased list cleared
5. Restart app; verify list persists
6. Airplane mode; repeat add/toggle/delete flows

## Dependencies
- None
