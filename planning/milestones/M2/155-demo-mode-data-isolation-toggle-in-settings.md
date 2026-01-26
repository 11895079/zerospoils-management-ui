## Context
Demo mode should be a safe playground with its own data store, switchable from Settings at any time, without impacting live inventory. Later, household admin/RBAC can disable demo access.

## Goal
Provide a Settings toggle that swaps between a demo database and the live database. Seed demo data across expiry horizons to showcase app value.

## Expected behavior
- Settings toggle: Demo Mode on/off
- When toggled on, app reads/writes to demo DB; when off, to live DB
- Demo DB comes pre-seeded with items spanning expired/today/this-week/later
- Telemetry records toggle events (on/off)
- Offline-first; no cloud dependency

## Acceptance criteria (DoD)
- [ ] Separate persisted namespaces for demo and live data (items, settings, telemetry sinks)
- [ ] Settings toggle instantly swaps active namespace; survives app restarts
- [ ] Seed demo items cover multiple categories and expiry buckets:
  - **Expired (past expiry):** 3-5 items (milk, lettuce, yogurt) with expiry dates 1-7 days ago
  - **Today:** 2-3 items (chicken, berries) expiring today
  - **This Week (1-7 days):** 5-7 items (bread, eggs, cheese, leftovers) expiring within 7 days
  - **Later (7+ days):** 8-10 items (frozen foods, canned goods, condiments, grains) expiring 2+ weeks out
  - Mix of categories: dairy, vegetables, fruit, meat_poultry, bakery, frozen_foods, condiments, snacks
  - Varied locations: fridge, freezer, pantry; include sublocations (e.g., fridge.crisper_left)
  - Include items with notes, photos (sample images), batch codes, costs for realistic demo experience
- [ ] Telemetry: `demo_mode_toggled` (properties: `enabled`, `active_namespace`)
- [ ] Offline-first verified
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Household RBAC controls (future: admins can enable/disable demo per household)
- Cloud sync/household sharing

## Implementation notes
- Namespace approach: prefix all box/table names with `demo_` vs `live_` (or distinct DB files); include telemetry/event sinks
- Toggle stored in settings; inject into repositories via provider
- Guard migrations: both namespaces must migrate safely
- Seed data loaded on first demo activation; avoid reseeding if data exists
- Surface subtle badge in UI when in demo (non-blocking)
- Demo seeding strategy:
  - Create JSON seed file with 20-25 items spanning all expiry horizons
  - Include sample images (low-res food photos) bundled in assets; reference in demo items
  - Set realistic purchase dates (7-30 days ago) and varied costs ($1.50-$45.00)
  - Add 2-3 shopping batches with receipt references for batch demo
  - Use realistic notes ("No expiry date found", "Opened on 1/20", "Buy One Get One")
  - Assign varied sublocations to demonstrate hierarchy (fridge.top_shelf, freezer.bin_2)

## Test plan
**Automated:**
- Unit test: toggle flips active repository namespace
- Unit test: seeding runs once; subsequent toggles preserve data
- Integration: add item in demo; toggle off/on; verify isolation from live
- Telemetry test: `demo_mode_toggled` emitted with correct payload

**Manual:**
1. Toggle Demo Mode on in Settings → see demo badge; seeded items appear across buckets
2. Add/edit/delete item in demo; toggle off; verify live data untouched
3. Kill/relaunch app; verify namespace persistence
4. Airplane mode: toggle and use demo; verify no errors

## Dependencies
- M1/080 (data model) for fields that must exist in both namespaces
- M3/130 (feature flags) optional to gate toggle visibility later
