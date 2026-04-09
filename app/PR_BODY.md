## Summary
This PR completes the free camera-assisted add flow cleanup and telemetry normalization work on the inventory item-entry path. It:

- routes the inventory FAB directly to the full single-item add form
- removes the redundant intermediate add chooser for single-item entry
- improves expiry OCR for Canadian `BB/MA` labels and bilingual month-code package stamps
- makes successful OCR capture auto-close and adds embossed-date guidance plus torch support
- reuses recent item defaults and prior category/location when barcode suggestions match existing items
- normalizes `item_added` save telemetry so manual vs camera-assisted entry and accepted camera-derived values can be analyzed reliably

## What Changed
- **Add flow UX**
	- Inventory FAB now opens `ItemFormScreen` directly
	- Receipt-batch capture moved to a dedicated app bar action
	- Successful barcode/expiry capture no longer shows blocking success snackbars
	- Expiry OCR auto-closes on successful detection

- **OCR + barcode reliability**
	- Added parser support for `BB/MA`, `MEILLEUR AVANT`, packed-date cues like `PKD`, and bilingual month-code layouts such as `BB/MA 2027 NO 20`
	- Added realistic OCR fixture-backed regression coverage for Canadian packaging patterns
	- Barcode capture now shows the detected code in the form and reuses previous category/location defaults when the item name matches a recent saved item

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

- **Planning**
	- Added M6 grooming issues for Pro geofenced grocery reminders and the supporting local store-affinity/preferences model

## Linked Planning Issues
- Adds planning for M6/525 and M6/530

## Validation
- Focused widget suites passed: 41 passed, 0 failed
- Parser regressions passed for Canadian `BB/MA` and month-code layouts
- Release APK built successfully:
	- `app/build/app/outputs/flutter-apk/app-release.apk`

## Notes For Review
- Use `item_added` rather than scan-attempt events as the source of truth for accepted camera-derived values
- `receipt_batch_camera` is intentionally normalized as camera-based without claiming field-level barcode/expiry acceptance
- Concrete dashboard queries for these semantics now live in `docs/item-entry-telemetry-analysis.md`
