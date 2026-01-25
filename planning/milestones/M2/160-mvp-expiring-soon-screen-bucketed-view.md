## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Expiring Soon screen (bucketed view) with tests and telemetry.

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
- Cloud sync, receipt scanning, household sharing
- Sorting customization (use fixed order: TODAY → THIS_WEEK → EXPIRED)
- Item editing from Expiring Soon screen (route to Item Detail for edits)

## Implementation notes
- Create `ExpiringTodayScreen` widget in presentation/screens/
- Use Riverpod to watch itemRepositoryProvider and compute buckets on-the-fly
- Leverage ExpiryClassifier from domain/utils/expiry_classifier.dart
- Sections: TODAY (red alert emoji ⚠️), THIS_WEEK (clock emoji ⏰), EXPIRED (red circle emoji 🔴)
- Reuse ItemCard widget from inventory screen with tap routing to Item Detail
- Empty state: positive messaging with celebration emoji 🎉 + "Review Inventory" CTA button
- Pull-to-refresh to recalculate buckets (triggers itemRepository.getAllItems())
- Track telemetry: screen_viewed, item_tapped_from_expiring_soon, pull_to_refresh
- Accessibility: section headers have semantic labels; tap targets ≥44pt

## Test plan

**Automated:**
- Widget test: renders empty state when no items
- Widget test: renders empty state when no items expiring within 7 days
- Widget test: renders TODAY section with correct item count
- Widget test: renders THIS_WEEK section with correct item count
- Widget test: renders EXPIRED section with correct item count
- Widget test: tapping item navigates to Item Detail screen with correct item ID
- Widget test: pull-to-refresh triggers repository.getAllItems()
- Widget test: emits screen_viewed telemetry on init
- Widget test: emits item_tapped_from_expiring_soon telemetry when tapping item
- Widget test: empty state CTA button navigates to inventory screen
- Unit test: verifies sections sorted correctly (TODAY before THIS_WEEK before EXPIRED)
- Integration test: add item, navigate to Expiring Soon, verify bucket assignment

**Manual:**
1. Fresh install; add items with various expiry dates (today, tomorrow, 3 days, 8 days, no date, past date)
2. Open Expiring Soon tab → should show 3 sections with correct items
3. Tap item in TODAY section → navigates to Item Detail
4. Edit item expiry date to 10 days away; return to Expiring Soon → item should be gone
5. Pull-to-refresh → buckets recalculate smoothly
6. Restart app → verify sections remain consistent
7. Delete all expiring items → verify empty state displays
8. Test on physical device in airplane mode → verify offline-first behavior

## Dependencies
- M2/110 (Expiry bucketing logic)
