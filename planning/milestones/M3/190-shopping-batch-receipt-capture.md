## Context
After grocery shopping, users bring home multiple items at once. Currently, adding items one-by-one is tedious and loses context of the shopping trip (receipt, store, total cost). Users want to capture the batch metadata (receipt photo, store, date, total) and link multiple items to that shopping session for historical tracking and insights.

## Goal
Deliver shopping batch capture with receipt photo attachment, batch metadata entry, item linking (at add-time or retroactive), and shopping history view integrated into Shopping tab.

## Expected behavior
- Enhance "+" button: tap shows options "Add Individual Item" or "Add Shopping Batch"
- "Add Shopping Batch" flow: capture batch metadata (store name, purchase date, total cost, payment method) + optional receipt photo
- Receipt photo stored locally; max 1 photo per batch; dedupe by checksum
- Support non-perishable items in batches (e.g., toothpaste, detergent, supplies without expiry_date); items without expiry still link to batch for shopping history tracking
- After batch created, user adds items and optionally links to batch; batch selector appears in add-item form
- Items can be linked to batch at add-time (batch dropdown in add-item form) or retroactively (multi-select items → "Link to Batch")
- Each inventory item shows purchase date (from batch purchase date or manual entry if not batched)
- Each inventory item shows batch association (batch name/date) and allows navigating to batch detail
- Shopping tab integrates batch history: shows shopping list + past batches (expandable sections)
- Batch detail view: receipt photo, metadata, list of items linked to batch, aggregate stats (total cost, item count, category distribution)
- Inventory filters include "Batch" filter; selecting batch shows only items from that shopping session
- Batch metadata included in M2/165 backup/restore; receipt photo embedded as base64 in JSON
- Telemetry: `batch_created`, `batch_item_linked`, `batch_viewed` events
- Offline-first: all batch CRUD and photo storage local; no network dependency

## Acceptance criteria (Definition of Done)
- [ ] Add `ShoppingBatch` entity to data model: id, store_name, purchase_date, total_cost, payment_method, receipt_photo_uri, created_at
- [ ] Implement batch repository with local persistence (Hive/sqflite) for CRUD operations
- [ ] Update "+" FAB: show bottom sheet with "Add Individual Item" and "Add Shopping Batch" options
- [ ] "Add Shopping Batch" form: fields for store name, purchase date, total cost, payment method (cash/card/mobile), receipt photo picker
- [ ] Receipt photo stored locally; max 1 per batch; checksum for dedupe; display in batch detail view
- [ ] Add optional `batch_id` field to Item entity (nullable UUID foreign key)
- [ ] Add `purchase_date` field to Item entity (required; uses batch purchase date when linked)
- [ ] Add-item form includes batch dropdown (show batches from last 30 days; searchable by store/date)
- [ ] Add-item form sets purchase date: auto-populate from batch when selected; allow manual override when no batch
- [ ] Retroactive linking: multi-select items in inventory → "Link to Batch" action → batch selector
- [ ] Shopping tab redesign: tabs/sections for "Shopping List" and "Shopping History" (batches chronological, most recent first)
- [ ] Batch detail view: receipt photo preview (tap to enlarge), metadata, linked items list, aggregate stats (cost, count, category pie chart)
- [ ] Inventory item detail shows purchase date and batch info (with link to batch detail)
- [ ] Inventory filter: add "Batch" filter showing all batches; selecting batch filters items to that batch only
- [ ] Update M2/165 backup/restore: include `shopping_batches` in JSON; embed receipt photo as base64 data URI
- [ ] Telemetry events: `batch_created {store, total_cost, items_count}`, `batch_item_linked {batch_id, item_count}`, `batch_viewed {batch_id}`
- [ ] Unit/widget/integration tests added or updated (batch CRUD, item linking, photo storage, backup/restore)
- [ ] Telemetry added/updated (event names + key properties documented)
- [ ] Offline-first behavior verified (no network dependency)
- [ ] Accessibility basics (form labels, photo preview alt text, batch list semantics)

## Out of scope
- Receipt OCR for line item extraction (defer to M6 Pro tier after general OCR foundation)
- Cloud sync of batches/receipts across devices (M6)
- Multiple receipt photos per batch (limit 1 for MVP)
- Receipt photo editing/cropping (raw photo only)
- Batch analytics dashboard (category trends, store comparison - M6 insights)
- Export batch data to spreadsheet (defer to M4/M5)

## Implementation notes
- Store receipt photo in local files; save URI in `ShoppingBatch.receipt_photo_uri`; compute checksum to avoid duplicate storage
- Batch dropdown in add-item: show last 30 days only; format as "Store Name - MM/DD/YYYY ($XX.XX)"
- Shopping tab layout: Material TabBar or ExpansionTile sections; "Shopping List" + "Shopping History"
- Batch detail stats: total cost (from batch metadata), item count (count linked items), category distribution (group by item.category)
- Retroactive linking: use multi-select mode in inventory (long-press to enter selection mode); show "Link to Batch" in app bar actions
- Purchase date rules:
	- If linked to batch, item.purchase_date = batch.purchase_date
	- If not linked, item.purchase_date is required and set during item creation
- Backup format: `shopping_batches: [{id, store_name, purchase_date, total_cost, payment_method, receipt_photo_base64, created_at}]`
- Receipt photo base64: prefix with `data:image/jpeg;base64,` for re-import compatibility
- Telemetry: emit `batch_created` on save; include `items_count: 0` initially (updated when items linked)
- Payment method enum: `cash`, `credit_card`, `debit_card`, `mobile_payment`, `other`

## Test plan
**Automated:**
- Widget test: tap "+" FAB shows "Add Individual Item" and "Add Shopping Batch" options
- Widget test: "Add Shopping Batch" form validation (store name required, total cost ≥0, date not future)
- Widget test: attach receipt photo; verify stored locally and displayed in batch detail
- Unit test: ShoppingBatch repository CRUD operations (create, read, update, delete)
- Widget test: add-item form with batch selected; verify `item.batch_id` set correctly
- Widget test: add-item form sets purchase date from batch when selected
- Widget test: multi-select items in inventory; "Link to Batch" updates all selected items
- Widget test: Shopping tab shows "Shopping List" and "Shopping History" sections
- Widget test: batch detail view shows metadata, receipt photo, linked items, aggregate stats
- Widget test: inventory filter by batch shows only items from that batch
- Integration test: backup includes batches + receipt photos as base64; restore recreates batches
- Widget test: telemetry events fired for create/link/view with correct properties

**Manual:**
1. Tap "+" FAB; select "Add Shopping Batch"; fill store="Costco", date=today, cost=$125.50, payment=credit_card
2. Attach receipt photo from gallery; verify photo preview shown; save batch
3. Open Shopping tab → "Shopping History"; verify batch listed with store, date, cost
4. Tap batch; verify detail view shows receipt photo, metadata, 0 items linked
5. Add item "Milk"; select batch "Costco - 01/25/2026" from dropdown; save item
6. Return to batch detail; verify "Milk" now listed; item count = 1
7. Open item detail; verify purchase date shows 01/25/2026 and batch link points to Costco batch
7. Add 5 more items without batch; go to inventory; multi-select 3 items; tap "Link to Batch"; choose Costco batch
8. Verify batch detail now shows 4 items (Milk + 3 retroactive); aggregate stats updated
9. Inventory filter: select "Batch: Costco 01/25"; verify only 4 items shown
10. Backup data via M2/165; delete batch; restore backup; verify batch + receipt photo + item links restored
11. Screen reader: verify form labels, receipt photo alt text, batch list announces store/date/cost

## Dependencies
- M1/080 data model (Item entity for batch_id foreign key)
- M2/140 add-item screen (batch dropdown integration)
- M2/165 backup/restore (extend JSON schema for batches + base64 photos)
- M3 Shopping List implementation (if not already in M2/101)
