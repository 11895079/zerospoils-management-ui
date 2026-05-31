# Item Entry Telemetry Analysis

This note defines how to analyze the camera-assisted add flow after the save-time telemetry normalization work on PR 93.

## Purpose

Use this document when answering these product questions:

- How much item entry is still manual?
- How often do users save an item after using camera assistance?
- When camera is used, how often are the barcode and expiry values actually trusted and retained?
- Which camera path is strongest: barcode only, expiry only, or combined?
- Which unknown category/location values are most common and should be promoted into reference packs?

## Source of truth

Use `item_added` as the primary event for item-entry funnel analysis.

Why:

- It is emitted only when an item is actually saved.
- It distinguishes manual, camera-assisted, shopping conversion, and receipt-batch inventory flows.
- It records whether camera-derived barcode and expiry values were accepted into the saved item.

Use scan-attempt events only as secondary diagnostics:

- `camera_assisted_barcode_scanned`
- `expiry_date_scanned`

For reference-pack curation, also use unknown-value telemetry events:
- `unknown_category_entered`
- `unknown_location_entered`
- `unknown_reference_value_entered`

Those events answer attempt and failure questions, not accepted-save questions.

## Unknown-Reference Curation Metrics

Use these metrics to prioritize pack updates:

- Top unknown values by region and locale
- Distinct sessions affected by each unknown value
- Unknown value recurrence over 7/30 day windows
- Promotion conversion rate (unknown seen -> later resolved by pack)

Canonical property expectations for unknown events:
- `value_type`
- `value_normalized`
- `value_hash`
- `context`
- `region`
- `locale`
- `app_version`
- `platform`
- `analytics_consent` (must be true)

### Query: Top Unknown Category Values

```sql
with unknown_values as (
  select
    date(timestamp) as event_date,
    json_value(properties, '$.value_hash') as value_hash,
    json_value(properties, '$.value_normalized') as value_normalized,
    json_value(properties, '$.value_type') as value_type,
    json_value(properties, '$.region') as region,
    json_value(properties, '$.locale') as locale,
    session_id
  from telemetry_events
  where name in ('unknown_category_entered', 'unknown_reference_value_entered')
    and cast(json_value(properties, '$.analytics_consent') as boolean) = true
)
select
  region,
  locale,
  value_normalized,
  count(*) as events,
  count(distinct session_id) as sessions
from unknown_values
where value_type = 'category'
group by region, locale, value_normalized
order by events desc
limit 100;
```

### Query: Top Unknown Location Values

```sql
with unknown_values as (
  select
    json_value(properties, '$.value_normalized') as value_normalized,
    json_value(properties, '$.value_type') as value_type,
    json_value(properties, '$.region') as region,
    json_value(properties, '$.locale') as locale,
    session_id
  from telemetry_events
  where name in ('unknown_location_entered', 'unknown_reference_value_entered')
    and cast(json_value(properties, '$.analytics_consent') as boolean) = true
)
select
  region,
  locale,
  value_normalized,
  count(*) as events,
  count(distinct session_id) as sessions
from unknown_values
where value_type = 'location'
group by region, locale, value_normalized
order by events desc
limit 100;
```

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

## Canonical warehouse shape

Assume a telemetry warehouse table shaped like this:

- `telemetry_events`
  - `id` string
  - `name` string
  - `timestamp` timestamp
  - `platform` string
  - `app_version` string
  - `session_id` string
  - `properties` JSON

All dashboard queries below use that shape.

## Canonical flattening CTE

Use this CTE as the base for the item-entry dashboard.

```sql
with item_added_events as (
  select
    timestamp,
    date(timestamp) as event_date,
    platform,
    app_version,
    session_id,
    json_value(properties, '$.item_id') as item_id,
    json_value(properties, '$.source') as source,
    json_value(properties, '$.entry_method') as entry_method,
    cast(json_value(properties, '$.camera_used') as boolean) as camera_used,
    json_value(properties, '$.category') as category,
    json_value(properties, '$.location') as location,
    cast(json_value(properties, '$.quantity') as integer) as quantity,
    cast(json_value(properties, '$.has_expiry_date') as boolean) as has_expiry_date,
    cast(json_value(properties, '$.camera_barcode_accepted') as boolean) as camera_barcode_accepted,
    cast(json_value(properties, '$.camera_expiry_accepted') as boolean) as camera_expiry_accepted,
    json_value(properties, '$.camera_barcode_source') as camera_barcode_source,
    json_value(properties, '$.camera_expiry_format') as camera_expiry_format
  from telemetry_events
  where name = 'item_added'
)
```

If your warehouse uses a different JSON function name, keep the same field list and swap the extractor.

## Concrete dashboard queries

```sql
-- 1. Entry mix by day
with item_added_events as (
  select
    date(timestamp) as event_date,
    json_value(properties, '$.entry_method') as entry_method
  from telemetry_events
  where name = 'item_added'
)
select
  event_date,
  entry_method,
  count(*) as saves
from item_added_events
group by event_date, entry_method
order by event_date desc, saves desc;
```

```sql
-- 2. Overall entry mix share
with item_added_events as (
  select json_value(properties, '$.entry_method') as entry_method
  from telemetry_events
  where name = 'item_added'
)
select
  entry_method,
  count(*) as saves,
  round(count(*) * 100.0 / sum(count(*)) over (), 2) as pct_of_saves
from item_added_events
group by entry_method
order by saves desc;
```

```sql
-- 3. Camera usage share
with item_added_events as (
  select cast(json_value(properties, '$.camera_used') as boolean) as camera_used
  from telemetry_events
  where name = 'item_added'
)
select
  count(*) as total_saves,
  sum(case when camera_used then 1 else 0 end) as camera_assisted_saves,
  round(
    sum(case when camera_used then 1 else 0 end) * 100.0
      / nullif(count(*), 0),
    2
  ) as camera_usage_pct
from item_added_events;
```

```sql
-- 4. Barcode acceptance rate
with item_added_events as (
  select
    json_value(properties, '$.entry_method') as entry_method,
    cast(json_value(properties, '$.camera_barcode_accepted') as boolean) as camera_barcode_accepted
  from telemetry_events
  where name = 'item_added'
)
select
  count(*) as barcode_flow_saves,
  sum(case when camera_barcode_accepted then 1 else 0 end) as accepted_barcode_saves,
  round(
    sum(case when camera_barcode_accepted then 1 else 0 end) * 100.0
      / nullif(count(*), 0),
    2
  ) as barcode_acceptance_pct
from item_added_events
where entry_method in ('camera_barcode', 'camera_barcode_and_expiry');
```

```sql
-- 5. Expiry acceptance rate
with item_added_events as (
  select
    json_value(properties, '$.entry_method') as entry_method,
    cast(json_value(properties, '$.camera_expiry_accepted') as boolean) as camera_expiry_accepted
  from telemetry_events
  where name = 'item_added'
)
select
  count(*) as expiry_flow_saves,
  sum(case when camera_expiry_accepted then 1 else 0 end) as accepted_expiry_saves,
  round(
    sum(case when camera_expiry_accepted then 1 else 0 end) * 100.0
      / nullif(count(*), 0),
    2
  ) as expiry_acceptance_pct
from item_added_events
where entry_method in ('camera_expiry', 'camera_barcode_and_expiry');
```

```sql
-- 6. Combined camera completion rate
with item_added_events as (
  select
    json_value(properties, '$.entry_method') as entry_method,
    cast(json_value(properties, '$.camera_barcode_accepted') as boolean) as camera_barcode_accepted,
    cast(json_value(properties, '$.camera_expiry_accepted') as boolean) as camera_expiry_accepted
  from telemetry_events
  where name = 'item_added'
)
select
  count(*) as combined_flow_saves,
  sum(
    case
      when camera_barcode_accepted and camera_expiry_accepted then 1
      else 0
    end
  ) as fully_accepted_saves,
  round(
    sum(
      case
        when camera_barcode_accepted and camera_expiry_accepted then 1
        else 0
      end
    ) * 100.0 / nullif(count(*), 0),
    2
  ) as full_completion_pct
from item_added_events
where entry_method = 'camera_barcode_and_expiry';
```

```sql
-- 7. Barcode source quality
with item_added_events as (
  select
    json_value(properties, '$.camera_barcode_source') as camera_barcode_source,
    cast(json_value(properties, '$.camera_barcode_accepted') as boolean) as camera_barcode_accepted
  from telemetry_events
  where name = 'item_added'
)
select
  camera_barcode_source,
  count(*) as saves,
  sum(case when camera_barcode_accepted then 1 else 0 end) as accepted_saves,
  round(
    sum(case when camera_barcode_accepted then 1 else 0 end) * 100.0
      / nullif(count(*), 0),
    2
  ) as acceptance_pct
from item_added_events
where camera_barcode_source is not null and camera_barcode_source <> 'none'
group by camera_barcode_source
order by saves desc;
```

```sql
-- 8. OCR format quality
with item_added_events as (
  select
    json_value(properties, '$.camera_expiry_format') as camera_expiry_format,
    cast(json_value(properties, '$.camera_expiry_accepted') as boolean) as camera_expiry_accepted,
    json_value(properties, '$.entry_method') as entry_method
  from telemetry_events
  where name = 'item_added'
)
select
  camera_expiry_format,
  count(*) as saves,
  sum(case when camera_expiry_accepted then 1 else 0 end) as accepted_saves,
  round(
    sum(case when camera_expiry_accepted then 1 else 0 end) * 100.0
      / nullif(count(*), 0),
    2
  ) as acceptance_pct
from item_added_events
where entry_method in ('camera_expiry', 'camera_barcode_and_expiry')
  and camera_expiry_format is not null
  and camera_expiry_format <> 'none'
group by camera_expiry_format
order by saves desc;
```

```sql
-- 9. Platform split for manual vs camera-assisted saves
with item_added_events as (
  select
    platform,
    json_value(properties, '$.entry_method') as entry_method
  from telemetry_events
  where name = 'item_added'
)
select
  platform,
  entry_method,
  count(*) as saves
from item_added_events
group by platform, entry_method
order by platform, saves desc;
```

```sql
-- 10. Daily conversion trend for the combined guided flow
with item_added_events as (
  select
    date(timestamp) as event_date,
    json_value(properties, '$.entry_method') as entry_method,
    cast(json_value(properties, '$.camera_barcode_accepted') as boolean) as camera_barcode_accepted,
    cast(json_value(properties, '$.camera_expiry_accepted') as boolean) as camera_expiry_accepted
  from telemetry_events
  where name = 'item_added'
)
select
  event_date,
  count(*) as combined_flow_saves,
  sum(
    case
      when camera_barcode_accepted and camera_expiry_accepted then 1
      else 0
    end
  ) as fully_accepted_saves,
  round(
    sum(
      case
        when camera_barcode_accepted and camera_expiry_accepted then 1
        else 0
      end
    ) * 100.0 / nullif(count(*), 0),
    2
  ) as full_completion_pct
from item_added_events
where entry_method = 'camera_barcode_and_expiry'
group by event_date
order by event_date desc;
```

## Scan diagnostic queries

These are secondary queries for attempt and failure analysis.

```sql
-- 11. Barcode scan attempts vs accepted barcode saves
with barcode_attempts as (
  select date(timestamp) as event_date, count(*) as attempts
  from telemetry_events
  where name = 'camera_assisted_barcode_scanned'
  group by date(timestamp)
),
barcode_saves as (
  select
    date(timestamp) as event_date,
    count(*) as accepted_saves
  from telemetry_events
  where name = 'item_added'
    and cast(json_value(properties, '$.camera_barcode_accepted') as boolean) = true
  group by date(timestamp)
)
select
  coalesce(a.event_date, s.event_date) as event_date,
  coalesce(a.attempts, 0) as attempts,
  coalesce(s.accepted_saves, 0) as accepted_saves
from barcode_attempts a
full outer join barcode_saves s on a.event_date = s.event_date
order by event_date desc;
```

```sql
-- 12. Expiry OCR scan attempts vs accepted expiry saves
with expiry_attempts as (
  select
    date(timestamp) as event_date,
    count(*) as attempts,
    sum(case when cast(json_value(properties, '$.scan_success') as boolean) then 1 else 0 end) as successful_attempts
  from telemetry_events
  where name = 'expiry_date_scanned'
  group by date(timestamp)
),
expiry_saves as (
  select
    date(timestamp) as event_date,
    count(*) as accepted_saves
  from telemetry_events
  where name = 'item_added'
    and cast(json_value(properties, '$.camera_expiry_accepted') as boolean) = true
  group by date(timestamp)
)
select
  coalesce(a.event_date, s.event_date) as event_date,
  coalesce(a.attempts, 0) as attempts,
  coalesce(a.successful_attempts, 0) as successful_attempts,
  coalesce(s.accepted_saves, 0) as accepted_saves
from expiry_attempts a
full outer join expiry_saves s on a.event_date = s.event_date
order by event_date desc;
```

## Suggested dashboard layout

1. Scorecards:
   - total saves
   - camera usage %
   - barcode acceptance %
   - expiry acceptance %
   - combined flow completion %
2. Time series:
   - daily entry mix by `entry_method`
   - daily combined flow completion %
3. Breakdown tables:
   - barcode source quality
   - OCR format quality
   - platform split
4. Diagnostics:
   - barcode attempts vs accepted saves
   - expiry attempts vs accepted saves

## Caveats

- `receipt_batch_camera` is camera-derived, but it does not currently claim field-level barcode or expiry acceptance.
- `shopping_convert` is not a camera save, even if the upstream shopping item was suggested elsewhere.
- Scan-attempt events can exceed save counts because users may cancel, retry, or overwrite values before saving.

## Review checklist

- Prefer save-based metrics over scan-based metrics for product success reporting.
- Break out `camera_barcode_and_expiry` from single-field camera flows.
- Watch format-specific OCR acceptance after parser changes.
- Compare acceptance rates before and after barcode catalog or OCR parser updates.