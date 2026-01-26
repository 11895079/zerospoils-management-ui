## Context
Users need ability to manage food categories beyond built-in defaults. Current model uses fixed category enum, but users shop at varied stores with specialized items (school snacks, ethnic foods, supplements) that don't fit standard taxonomy. Need hybrid approach: standard categories + user-defined extensions.

## Goal
Deliver user-defined category management (CRUD) with searchable dropdown, persistence, and migration from fixed enum to hybrid model.

## Expected behavior
- Category selector shows built-in categories + user-defined categories in searchable dropdown
- "Add new category" button in dropdown footer opens inline form (name + optional icon/color picker)
- User-defined categories stored in local DB; backed up/restored with M2/165 JSON export
- Built-in categories (from data model) remain constant; cannot be deleted but can be hidden
- Category field in add-item/edit-item shows merged list (built-ins first, then custom, alphabetical within groups)
- Deleting a custom category prompts user to reassign items or move to "other" category
- Category presets (M1/080) apply only to built-in categories; user-defined categories use generic defaults
- Telemetry: `category_created`, `category_deleted`, `category_assigned` events
- Offline-first: all category CRUD operations local; no network dependency

## Acceptance criteria (Definition of Done)
- [ ] Add `UserCategory` entity to data model with fields: id, name, icon (optional), color (optional), created_at
- [ ] Implement CRUD repository for UserCategory with local persistence (Hive/sqflite)
- [ ] Update category dropdown UI to show built-in + user-defined categories in searchable list
- [ ] Add "Add new category" button in dropdown footer; opens inline form with name + optional icon/color
- [ ] Category selector filters/searches across both built-in and user-defined categories
- [ ] Handle category deletion: prompt to reassign items to another category or default to "other"
- [ ] Update M2/165 backup/restore to include user-defined categories in JSON schema alongside items and storage locations
- [ ] JSON backup/restore handles user-defined categories: export as array, restore with conflict check (duplicate names ask user to rename or merge) alongside items and batches
- [ ] JSON backup restores user-defined categories; attempting to import backup with unknown categories asks for confirmation or maps to "other"
- [ ] Migration: existing items using built-in enum values unchanged; new items can use user-defined categories
- [ ] Telemetry events: `category_created {name, is_custom: true}`, `category_deleted {name, items_affected}`, `category_assigned {category, is_custom}`
- [ ] Unit/widget/integration tests added or updated (CRUD operations, dropdown filtering, deletion/reassignment flow)
- [ ] Telemetry added/updated (event names + key properties documented)
- [ ] Offline-first behavior verified (no network dependency)
- [ ] Accessibility basics (dropdown keyboard nav, form labels, focus management)

## Out of scope
- Cloud sync of user-defined categories across devices (M6)
- Category icons/emoji picker (defer to M4 UX polish)
- Category usage analytics/suggestions (M6 insights dashboard)
- Bulk category reassignment UI

## Implementation notes
- Store user-defined categories in separate table: `user_categories (id, name, icon, color, created_at)`
- Item.category field becomes nullable string instead of enum; validate against built-in + user-defined lists
- Category dropdown: render built-ins first (hardcoded order from data model), then user-defined (alphabetical)
- Deletion flow: query count of items using category; if >0, show dialog with reassignment dropdown + "Move to Other" default
- For category presets (M1/080), apply defaults only if category matches built-in enum; user-defined categories use: expiry=14d, storage=pantry, unit=count
- Telemetry: emit `category_created` only on successful save; include `is_custom: true` property for user-defined categories
- Searchable dropdown: filter on name (case-insensitive); highlight matches; support keyboard up/down/enter
- Icon/color optional for MVP; use default icon + random pastel color if not specified

## Test plan
**Automated:**
- Widget test: category dropdown renders built-in + user-defined categories in correct order
- Widget test: search filters categories; selecting custom category sets item.category correctly
- Widget test: "Add new category" button opens form; submitting saves to DB and updates dropdown immediately
- Widget test: deleting category with items prompts reassignment; reassigning updates all affected items
- Unit test: UserCategory repository CRUD operations (create, read, update, delete)
- Integration test: backup/restore includes user-defined categories; reimporting restores custom categories
- Widget test: telemetry events fired for create/delete/assign with correct properties

**Manual:**
1. Open add-item screen; tap category dropdown; verify built-in categories listed first
2. Tap "Add new category" in dropdown footer; enter "School Snacks"; save; verify appears in dropdown
3. Create item using custom category; edit item; verify custom category selected and persists
4. Create 5+ items with custom category; delete category; verify reassignment prompt with item count
5. Reassign to different category; verify all 5 items updated; reopen items to confirm
6. Backup data via M2/165; delete custom category; restore backup; verify custom category restored
7. Search category dropdown with partial text ("sna"); verify matches "snacks" and "School Snacks"
8. Keyboard nav: tab to dropdown, use arrows to navigate, enter to select; verify accessible

## Dependencies
- M1/080 data model (category enum and presets)
- M2/165 backup/restore (must include user_categories in JSON schema)
- M2/140 add-item screen (category dropdown integration)
