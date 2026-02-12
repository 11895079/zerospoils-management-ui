## Context
Batch receipt capture is now part of the MVP scope (see docs/mvp.md). Users should capture multiple receipt photos per shopping trip and extract purchasable items in a single batch, offline-first.

## Goal
Enable batch receipt capture (up to 5 photos) with on-device text extraction and a review UI that lets users add multiple items to shopping list or inventory in one flow. Provide a lightweight Receipt Batches screen (drawer) to review past batches and see aggregate spend + consumption outcomes.

## Expected behavior
- User can start a new batch capture from Shopping List and/or Inventory.
- Inventory FAB opens a small speed-dial with two actions: “Add single item” and “Batch receipt”.
- Shopping List includes a visible “Batch Receipt Capture” CTA.
- Capture up to 5 receipt photos; show thumbnail stack and count.
- On-device text recognition extracts candidate line items.
- Review screen lets users edit item name, quantity, category, and price.
- Users can select which items to save and choose destination: Shopping List or Inventory.
- Receipt Batches screen lists batches by date with total spend and item count.
- Batch detail shows items, linked inventory status (available/consumed/wasted), and summary metrics:
	- Total spend
	- Consumed value
	- Wasted value
	- Remaining value
- Works offline without network dependency.
- Clear error states for camera permission denial and OCR failure.

## Acceptance criteria (Definition of Done)
- [ ] Entry points from Shopping List and Inventory present (CTA + FAB speed-dial)
- [ ] Batch capture UI supports up to 5 photos with clear progress and count
- [ ] 6th photo attempt shows inline limit message and blocks capture
- [ ] On-device text recognition processes all photos and merges line items
- [ ] Review UI supports edit (name, quantity, price), select/deselect, and batch save
- [ ] Items can be saved to Shopping List or Inventory in one action
- [ ] Shopping List save preserves price as estimated cost; Inventory save sets purchase price
- [ ] Permissions flow handled (camera + photo library) with fallback messaging
- [ ] Receipt Batches screen lists batches with spend + item count
- [ ] Batch detail screen shows items and consumption outcomes (consumed/wasted/remaining)
- [ ] Batch metrics match inventory status changes (updates as items are consumed/wasted)
- [ ] Telemetry events emitted for key actions (see below)
- [ ] Unit/widget tests added or updated
- [ ] Offline-first behavior verified (no network required)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Telemetry events
- `receipt_batch_started` (source_screen, batch_id)
- `receipt_photo_added` (batch_id, photo_index)
- `receipt_batch_processed` (batch_id, items_detected, duration_ms)
- `receipt_item_selected` (batch_id, item_index, destination)
- `receipt_batch_saved` (batch_id, items_saved, destination)
- `receipt_batch_viewed` (batch_id)
- `receipt_batch_list_viewed` (source_screen)
- `receipt_batch_failed` (batch_id, reason)
- `permission_prompted` (permission_type=camera|photos, source_screen)
- `permission_denied` (permission_type, source_screen)

## Out of scope
- Cloud OCR or server-side processing
- Barcode scanning
- Receipt storage sync across devices
- Bottom tab for batches

## Implementation notes
- Use on-device text recognition (e.g., ML Kit Text Recognition) to keep offline-first.
- Limit batch to 5 photos; show clear limit messaging.
- Normalize extracted text into candidate items (simple heuristics: split by line, parse price patterns, ignore totals/taxes).
- Store temporary images locally and clean up after batch completion.
- Reuse ShoppingListItem and Item models to persist results.
- Provide a “Save to Shopping List” and “Save to Inventory” choice at review.
- Add a lightweight parser that recognizes common receipt patterns (price at end, currency symbols, totals/tx lines filtered).
- Keep OCR pipeline modular (scanner → parser → review model) for later Pro enhancements.
- Use a deterministic batch ID (timestamp + random suffix) for telemetry correlation.
- Introduce a ReceiptBatch model with fields: id, createdAt, source, totalSpend, itemIds, receiptImagePaths.
- Compute batch stats by joining Inventory items to batch itemIds and aggregating by status.
- Add drawer entry: “Receipt Batches”.

## Test plan
**Automated:**
- Widget test: batch flow shows photo count and prevents adding the 6th photo.
- Widget test: review screen supports edit + select/deselect + destination choice.
- Unit test: text parsing converts sample receipt text into candidate items (name + price).
- Unit test: parser drops totals/taxes lines and ignores empty/invalid rows.
- Widget test: permission denied state shows correct guidance and retry action.
- Widget test: save-to-inventory persists purchase price and navigates back with success state.
- Widget test: save-to-shopping-list persists estimated cost and shows confirmation.
- Widget test: batch list renders totals and navigates to detail view.
- Unit test: batch summary aggregates consumed/wasted/remaining values correctly.

**Manual:**
1. Start batch capture from Shopping List, take 5 photos, verify thumbnails and count.
2. Complete review, edit item names, save to Shopping List; verify items appear.
3. Repeat and save to Inventory; verify items appear in Inventory list.
4. Disable camera permission and verify error state + recovery path.
5. Turn on airplane mode and complete a batch capture successfully.
6. Attempt to add a 6th photo and verify limit message and no capture.
7. Include totals/tax lines in receipt and verify they do not become items.
8. Open Receipt Batches from drawer, select a batch, verify totals and item statuses.

## Dependencies
- M2/145 onboarding + permissions
- M2/101 shopping list persistence
- M2/140 add item flow (for inventory save patterns)
