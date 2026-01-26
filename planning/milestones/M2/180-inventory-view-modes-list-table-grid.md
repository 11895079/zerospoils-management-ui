## Context
Inventory browsing needs flexible layouts: rapid scanning (grid/cards), dense comparison (table), and default readability (list). Users asked for columnar view for bulk edits and a photo-forward grid for quick recognition. Must align with M2 inventory screen and data model fields (notes, images, category presets, sublocations).

## Goal
Deliver switchable inventory view modes (list, table, grid/cards) with persistence, sorting, filtering compatibility, and telemetry.

## Expected behavior
- View mode toggle available on Inventory screen (list ↔ table ↔ grid/cards)
- Default mode: list. Last-selected mode persists across app restarts (local preference)
- Modes share filters, search, and sorting; switching modes preserves current filters/sorts
- Table view shows dense rows with sortable columns (name, category, location+sublocation, expiry, quantity/unit, status)
- Grid/cards view shows photo (or fallback initial), name, expiry badge, location chip, and status pill; supports 2-3 column responsive layout
- List view matches existing MVP spec; add inline expiry + location chips for parity
- Accessibility: toggle is keyboard/focusable, modes maintain readable semantics (table uses proper roles; cards expose headings/labels)
- Telemetry: event `inventory_view_mode_changed` with properties `{from, to, filters_applied, sort_key, result_count}`
- Offline-first: preference and state stored locally; no network required

## Acceptance criteria (Definition of Done)
- [ ] Add view mode toggle control to Inventory screen; default list mode
- [ ] Persist last-selected mode locally (tied to device/household profile) and restore on open
- [ ] Table view implemented with sortable columns: name, category, location+sublocation, expiry, quantity/unit, status
- [ ] Grid/cards view implemented with photo (or initial), name, expiry badge, location chip, status pill; responsive column count (2+ on phones, 3+ on tablets)
- [ ] Mode switching retains active filters, search query, and sort order without flicker or data refetch
- [ ] Telemetry emitted: `inventory_view_mode_changed` with `{from, to, filters_applied, sort_key, result_count}`; respects telemetry opt-out
- [ ] Unit/widget/integration tests added or updated (cover toggle, persistence, sort retention, telemetry payload)
- [ ] Telemetry added/updated (event names + key properties documented in code or telemetry schema)
- [ ] Offline-first behavior verified (no network dependency, preference stored locally)
- [ ] Accessibility basics (labels for toggle buttons, focus order, table semantics, tap targets)

## Out of scope
- Column reordering/resizing and custom column selection
- Cloud sync of view mode preference
- Bulk inline editing within the table

## Implementation notes
- Reuse shared Inventory state (filters/search/sort) across modes; avoid re-querying on mode switch
- Persist preference via local settings store (e.g., Hive key). Scope to household profile if available; otherwise device-level
- Table view: clickable row opens detail (M2/170); header tap toggles sort; show sort indicators
- Grid view: use cached image if available; otherwise show colored initial avatar with checksum-based color; constrain image size
- List view: add location and expiry chips for parity with other modes
- Ensure empty states render consistently across modes and preserve current filters/search context
- Telemetry: emit once per mode change; include `result_count` from current filtered dataset
- Performance: debounce rapid toggles; avoid rebuilding heavy image widgets unnecessarily

## Test plan
**Automated:**
- Widget test: default mode is list; toggling to table/grid updates UI and persists after restart (mocked settings store)
- Widget test: sort selection retained when switching modes (e.g., sort by expiry, switch to grid, still sorted by expiry)
- Widget test: filters/search applied, switch modes, items set remains filtered
- Widget test: telemetry event fired with correct `{from, to, filters_applied, sort_key, result_count}`
- Widget test: table headers toggle sort and reflect indicator; row tap opens detail intent

**Manual:**
1. Open Inventory: verify default list mode with expiry + location chips
2. Apply filter + search; switch to table and grid; verify same filtered set and sort order
3. In table mode, sort by expiry then by category; switch modes and back; verify sort persists
4. In grid mode, verify images render; missing image shows initial avatar; responsive columns adjust on tablet/rotation
5. Kill and relaunch app; confirm last-selected mode restored
6. Toggle telemetry opt-out (if available); confirm no `inventory_view_mode_changed` events emitted
7. Screen reader: ensure toggle buttons labeled and table has proper headers/roles; cards announce name and expiry/status

## Dependencies
- M2/150 Inventory list/search/filter baseline
- Data model from M1/080 (images, category, location+sublocation, quantity/unit, status)
- Navigation to Item detail (M2/170)
