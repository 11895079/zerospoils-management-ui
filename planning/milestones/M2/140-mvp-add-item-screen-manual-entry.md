## Context
Implement the MVP feature as specified in docs/mvp.md and wireframes.

## Goal
Deliver Add Item screen (manual entry) with tests and telemetry.

## Expected behavior
- Behavior matches wireframes and MVP spec
- Works offline without requiring login
- Error and empty states handled
- Expiry entry minimizes keystrokes via quick chips, category presets, and simple NL/relative inputs (no ML)

## Acceptance criteria (Definition of Done)
- [ ] UI implemented and integrated into navigation
- [ ] State management implemented with repository layer
- [ ] CRUD persists to local storage (where applicable)
- [ ] Telemetry events emitted for key actions (as applicable)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)
- [ ] Expiry entry supports quick chips (Today, Tomorrow, +3d, +7d, +14d, +21d) and category-specific presets (e.g., Produce +3/+7, Meat +2/+5, Bread +3/+7, Dairy +7/+14)
- [ ] Relative/NL inputs parsed deterministically (e.g., "+3d", "in 2 weeks", "next fri", "this fri") with documented rules; failures fall back gracefully
- [ ] Numeric keypad entry path available for manual date with auto-formatting
- [ ] Recently used preset remembered per category (optional, capped list)

## Out of scope
- Cloud sync
- Receipt scanning
- Household sharing

## Implementation notes
- Follow design tokens in theme.
- Keep domain/data/ui separation.
- Add widget tests where feasible.
- Expiry helper widget: chips row + NL/relative text field + keypad entry; deterministic parser (no generative AI) using weekday math and relative offsets
- Category presets sourced from data model; apply closest match when category selected; allow override
- Timezone/DST safe: compute on date-only objects at local midnight
- Persist last-used presets per category (in local settings store) for fast reuse

## Test plan

**Automated:**
- Unit tests for deterministic parser: today/tomorrow/this fri/next fri/+Nd/+Nw/in N days/weeks; end-of-week and next-week rules documented
- Unit tests for category presets: produce/meat/bread/dairy map to correct day offsets
- Widget tests: chips apply correct dates; NL field parses valid phrases; invalid phrases show fallback hint without crashing
- Widget tests: keypad entry auto-inserts separators and saves; recently used preset list updates
- Persistence test: last-used preset per category restored on reopen

**Manual:**
1. Fresh install; add an item with chip +3d; verify stored date matches calculation
2. Enter "next fri" and confirm expected date given today; verify failure message on unsupported phrase (e.g., "next weekend")
3. Switch category (e.g., Meat) and apply preset; verify offsets; repeat after app restart
4. Offline mode: add item with chips and NL entry; verify persistence after restart
5. Accessibility: verify focus order, labels, and contrast on chips/text fields/button

## Dependencies
- None
