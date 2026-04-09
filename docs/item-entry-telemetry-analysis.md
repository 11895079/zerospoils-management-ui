# Item Entry Telemetry Analysis

This note defines how to analyze the camera-assisted add flow after the save-time telemetry normalization work on PR 93.

## Purpose

Use this document when answering these product questions:

- How much item entry is still manual?
- How often do users save an item after using camera assistance?
- When camera is used, how often are the barcode and expiry values actually trusted and retained?
- Which camera path is strongest: barcode only, expiry only, or combined?

## Source of truth

Use `item_added` as the primary event for item-entry funnel analysis.

Why:

- It is emitted only when an item is actually saved.
- It distinguishes manual, camera-assisted, shopping conversion, and receipt-batch inventory flows.
- It records whether camera-derived barcode and expiry values were accepted into the saved item.

Use scan-attempt events only as secondary diagnostics:

- `camera_assisted_barcode_scanned`
- `expiry_date_scanned`

Those events answer attempt and failure questions, not accepted-save questions.

## Canonical fields

### Entry segmentation

- `source`
- `entry_method`

Current expected values:

- `manual`
- `camera_barcode`
- `camera_expiry`
- `camera_barcode_and_expiry`
- `shopping_convert`
- `receipt_batch_camera`

`source` and `entry_method` currently carry the same normalized value on save. Keep both for downstream compatibility.

### Camera trust fields

- `camera_used`
- `camera_barcode_accepted`
- `camera_expiry_accepted`
- `camera_barcode_source`
- `camera_expiry_format`

Interpretation:

- `camera_used=true` means a camera-derived input contributed to this saved item path.
- `camera_barcode_accepted=true` means the saved item retained a barcode-derived result.
- `camera_expiry_accepted=true` means the saved item retained an OCR-derived expiry date.
- `camera_barcode_source` tells you whether the accepted barcode suggestion came from the seed catalog, a learned mapping, or an unknown fallback.
- `camera_expiry_format` records the retained OCR format. Use it to spot formats with poor acceptance or parser gaps.

## Recommended dashboard cards

### 1. Entry mix

Metric:

- Count of `item_added` grouped by `entry_method`

Why it matters:

- This is the top-line adoption view for manual vs camera-assisted entry.

### 2. Camera usage share

Metric:

- `count(item_added where camera_used=true) / count(item_added)`

Why it matters:

- This shows how much of actual saved inventory creation is camera-assisted.

### 3. Barcode acceptance rate

Metric:

- `count(item_added where camera_barcode_accepted=true) / count(item_added where entry_method in ('camera_barcode','camera_barcode_and_expiry'))`

Why it matters:

- This is the cleanest measure of barcode trust at save time.

### 4. Expiry acceptance rate

Metric:

- `count(item_added where camera_expiry_accepted=true) / count(item_added where entry_method in ('camera_expiry','camera_barcode_and_expiry'))`

Why it matters:

- This shows whether OCR is producing values users keep rather than overwrite.

### 5. Combined camera completion rate

Metric:

- `count(item_added where entry_method='camera_barcode_and_expiry' and camera_barcode_accepted=true and camera_expiry_accepted=true) / count(item_added where entry_method='camera_barcode_and_expiry')`

Why it matters:

- This is the strongest single KPI for the new guided add flow.

### 6. Barcode source quality

Metric:

- Count of accepted barcode saves grouped by `camera_barcode_source`

Why it matters:

- It separates catalog quality from learned-local quality and fallback behavior.

### 7. OCR format quality

Metric:

- Count of `item_added` grouped by `camera_expiry_format`
- Acceptance rate grouped by `camera_expiry_format`

Why it matters:

- It helps identify problematic formats such as stamped bilingual Canadian layouts.

## Suggested SQL-style queries

```sql
-- Entry mix
select entry_method, count(*) as saves
from item_added
group by entry_method
order by saves desc;

-- Barcode acceptance
select
  sum(case when camera_barcode_accepted then 1 else 0 end) * 1.0
    / nullif(count(*), 0) as barcode_acceptance_rate
from item_added
where entry_method in ('camera_barcode', 'camera_barcode_and_expiry');

-- Expiry acceptance by OCR format
select
  camera_expiry_format,
  count(*) as saves,
  sum(case when camera_expiry_accepted then 1 else 0 end) as accepted,
  sum(case when camera_expiry_accepted then 1 else 0 end) * 1.0
    / nullif(count(*), 0) as acceptance_rate
from item_added
where entry_method in ('camera_expiry', 'camera_barcode_and_expiry')
group by camera_expiry_format
order by saves desc;
```

## Caveats

- `receipt_batch_camera` is camera-derived, but it does not currently claim field-level barcode or expiry acceptance.
- `shopping_convert` is not a camera save, even if the upstream shopping item was suggested elsewhere.
- Scan-attempt events can exceed save counts because users may cancel, retry, or overwrite values before saving.

## Review checklist

- Prefer save-based metrics over scan-based metrics for product success reporting.
- Break out `camera_barcode_and_expiry` from single-field camera flows.
- Watch format-specific OCR acceptance after parser changes.
- Compare acceptance rates before and after barcode catalog or OCR parser updates.