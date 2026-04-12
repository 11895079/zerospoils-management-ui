## Summary
This PR completes the free camera-assisted add flow cleanup and telemetry normalization work on the inventory item-entry path. It also finishes the follow-on review fixes and item brand support across CRUD. It:

- routes the inventory FAB directly to the full single-item add form
- removes the redundant intermediate add chooser for single-item entry
- improves expiry OCR for Canadian `BB/MA` labels, bilingual month-code package stamps, compact numeric expiry stamps, yearless expiry labels, and Spanish month abbreviations
- makes successful OCR capture auto-close and adds embossed-date guidance plus torch support
- reuses recent item defaults and prior category/location when barcode suggestions match existing items
- adds optional `brand` capture and display across the item form, quick entry sheet, inventory cards, detail view, backup/export, and shopping-list conversion
- normalizes `item_added` save telemetry so manual vs camera-assisted entry and accepted camera-derived values can be analyzed reliably
- resolves the remaining OCR thumbnail-memory and telemetry-doc review comments

## What Changed
- **Add flow UX**
	- Inventory FAB now opens `ItemFormScreen` directly
	- Receipt-batch capture moved to a dedicated app bar action
	- Successful barcode/expiry capture no longer shows blocking success snackbars
	- Expiry OCR auto-closes on successful detection

- **OCR + barcode reliability**
	- Added parser support for `BB/MA`, `MEILLEUR AVANT`, packed-date cues like `PKD`, and bilingual month-code layouts such as `BB/MA 2027 NO 20`
	- Added parser support for compact `YYYYMMDD` expiry stamps when expiry context is strong
	- Added year inference for yearless month/day expiry labels such as `USE OR FREEZE BY APR 22`
	- Added Spanish month-abbreviation support such as `22 ABR 2026`
	- Expanded expiry-context scoring to handle nearby labels like `expiration date`, `best if used by`, and `use or freeze by`
	- Added realistic OCR fixture-backed regression coverage for Canadian, embossed, compact numeric, yearless, and Spanish-labelled packaging patterns
	- Barcode capture now shows the detected code in the form and reuses previous category/location defaults when the item name matches a recent saved item
	- OCR capture thumbnails are now downscaled before being held in memory for the capture strip, avoiding full-resolution image retention

- **Brand support**
	- Added optional nullable `brand` to the item model and Hive adapter
	- Included `brand` in backup/export JSON and CSV payloads
	- Added free-text brand entry with recent-brand suggestions/search to `ItemFormScreen` and `ItemEntrySheet`
	- Displayed brand on inventory list cards and item detail screens
	- Preserved brand during shopping-list to inventory conversion flows
	- Added widget coverage for brand save/load and conversion behavior

- **Telemetry**
	- `item_added` now includes normalized save-time attribution:
		- `source`
		- `entry_method`
		- `camera_used`
		- `camera_barcode_accepted`
		- `camera_expiry_accepted`
		- `camera_barcode_source`
		- `camera_expiry_format`
	- Semantically, `item_added` is now the source of truth for accepted-save analysis:
		- use `entry_method` / `source` for manual vs camera vs conversion segmentation
		- use `camera_barcode_accepted` and `camera_expiry_accepted` for trust-of-camera metrics
		- treat scan-attempt events as diagnostics, not save-truth
	- Shopping-list conversion and receipt-batch inventory saves now emit the same normalized `item_added` contract
	- Added repo docs with concrete dashboard SQL for manual vs camera adoption and camera trust from save events
	- Aligned `planning/docs/telemetry.md` with the implemented `expiry_date_scanned` payload keys: `scan_success` and `date_format_detected`

- **Planning**
	- Added M6 grooming issues for Pro geofenced grocery reminders and the supporting local store-affinity/preferences model

## Linked Planning Issues
- Adds planning for M6/525 and M6/530

## Validation
- Focused widget suites passed: 41 passed, 0 failed
- Item form + shopping conversion brand widget suites passed: 21 passed, 0 failed
- OCR form/widget suite passed: 12 passed, 0 failed
- Parser regressions passed: 24 passed, 0 failed
- Release APK built successfully:
	- `app/build/app/outputs/flutter-apk/app-release.apk`

## Notes For Review
- Use `item_added` rather than scan-attempt events as the source of truth for accepted camera-derived values
- `receipt_batch_camera` is intentionally normalized as camera-based without claiming field-level barcode/expiry acceptance
- Concrete dashboard queries for these semantics now live in `docs/item-entry-telemetry-analysis.md`
## Code Review Fixes (post-review)
- Replaced invalid `SemanticsService.sendAnnouncement(view, ...)` usage with `SemanticsService.announce(message, textDirection)` for SDK compatibility
- Normalized `expiry_date_scanned` telemetry: `success`→`scan_success`, `format_detected`→`date_format_detected`
- Removed dead unreachable `setState` block in `_capturePhoto`
- Replaced eager full-res photo bytes with lazy `FutureBuilder` thumbnail loading
- Hardened widget test: `find.text(...)` replaced with key-based `Text.data` assertion

- Brand remains optional and is intentionally modeled as a nullable string, not a separate entity/table
