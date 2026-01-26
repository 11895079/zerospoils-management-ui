## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Item detail screen + mark used/wasted with tests and telemetry.

## Expected behavior
- Behavior matches wireframes and MVP spec
- Works offline without requiring login
- Error and empty states handled

## Acceptance criteria (Definition of Done)
- [x] UI implemented and integrated into navigation
- [x] State management implemented with repository layer
- [x] CRUD persists to local storage (where applicable)
- [x] Telemetry events emitted for key actions (as applicable)
- [x] Unit/widget/integration tests added or updated
- [x] Telemetry added/updated (event names + key properties)
- [x] Offline-first behavior verified (where applicable)
- [x] Accessibility basics (labels, contrast, tap targets)
- [ ] Mark As Wasted dialog enhanced: wider dialog (80-90% screen width on mobile), larger tap targets (min 48pt), improved visual hierarchy with clear section labels and spacing

## Implementation Notes (Completed)
**Implemented Features:**
- Full item detail display with all properties (name, category, location, quantity, expiry, etc.)
- Mark as Used action with confirmation dialog
- Mark as Wasted action with waste reason selection (Spoiled, Forgotten, Expired, Damaged, Other)
- Status badges (Available, Consumed, Wasted) with color-coded indicators
- Error and empty states with retry functionality
- Edit button for available items (navigates to edit form)
- Expiry date highlighting for items expiring within 3 days
- Repository integration using HiveItemRepository
- Riverpod state management with provider overrides for testing

**Telemetry Events:**
1. `screen_viewed` - Tracked on screen init with screen_name='item_detail' and item_id
2. `item_marked_used` - Tracked when item marked as consumed (includes item_id, category, location)
3. `item_marked_wasted` - Tracked when item marked as wasted (includes item_id, category, location, waste_reason)

**Test Coverage (12 tests, all passing):**
- Loading states (CircularProgressIndicator)
- Item details display with all fields
- "Item not found" state
- Error state with retry button
- Mark used/wasted buttons (shown for available, hidden for consumed/wasted)
- Mark used confirmation dialog and persistence
- Mark wasted waste reason selection and persistence
- Telemetry event tracking
- Edit button visibility
- Expiry date highlighting

**File Locations:**
- Implementation: `app/lib/presentation/screens/item_detail_screen.dart` (398 lines)
- Tests: `app/test/widget/screens/item_detail_screen_test.dart` (344 lines)
- Dependencies added: `intl: ^0.19.0` for date formatting

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
