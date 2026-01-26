## Context
A stable model reduces rework and enables future scanning/analytics.

## Goal
Define canonical domain model and event log strategy.

## Expected behavior
- Item supports name, category, location, quantity/unit, expiry_date, notes, images, batch/lot metadata
- Weight/volume capture uses unit + precision defaults; photos attach as local URIs with checksum for dedupe
- Category presets define default expiry offsets and preferred storage locations per category
- Storage locations enumerated with hierarchy (fridge → shelf/drawer) and guidance for defaults
- Events capture state changes for insights

## Acceptance criteria (Definition of Done)
- [x] Create `docs/data-model.md` with schema
- [x] Define enums for category/location
- [x] Define waste_reason draft enum
- [x] Add Item fields for `notes`, `images[]` (URI + checksum + created_at), `batch/lot_code` and `purchase_source`
- [x] Document weight/volume capture (unit + precision), and quantity validation rules by measure type
- [x] Add category-level presets (default expiry offsets, default storage location, default unit) and persistence format
- [x] Expand storage locations to include fridge/freezer sublocations (shelf/drawer/bin) with hierarchy guidance
- [x] Migration strategy documented
- [x] Unit/widget/integration tests added or updated (N/A - documentation only)
- [x] Telemetry added/updated (event names + key properties documented in data model)
- [x] Offline-first behavior verified (where applicable - documented in model)
- [x] Accessibility basics (labels, contrast, tap targets - N/A for documentation)

## Out of scope
- Cloud sync payloads for attachments (out-of-scope until sync is defined)

## Implementation notes
- Keep codebase modular (domain/data/ui layers).
- Limit images to 5 per item; store file URI + width/height + checksum; future-proof for cloud sync by keeping attachment table/collection separate
- Batch metadata: `batch_code` (string), `purchase_source` (enum: grocery, farmers_market, delivery, other), optional `purchase_receipt_id` for future linking
- Category presets: map category → {default_expiry_days, default_storage_location, default_unit}; allow user override per household profile
- Storage hierarchy: location enum plus optional sublocation string (e.g., fridge → crisper_left); keep denormalized string for simple queries

## Test plan
**Automated:**
- JSON schema validation for `docs/data-model.md` entity definitions
- Verify all enums (category, location, waste_reason) have at least 3 values
- Script checks migration strategy section exists and includes versioning approach
- Script asserts Item table includes `notes`, `images`, `batch_code`, `purchase_source`, and weight/volume rules
- Script validates category preset section exists with default expiry + storage mapping
- Script validates storage hierarchy guidance section present with fridge/freezer sublocations

**Manual:**
1. Review data model with engineering team for normalization
2. Trace each MVP feature to required model entities/fields
3. Validate event log design supports analytics queries (e.g., waste by category)
4. Confirm quantity/unit handling supports common cases (count, weight, volume)
5. Review migration strategy for backward compatibility
6. Walk through add-item UX and ensure data model supports notes, images, batch/lot capture, and category presets for defaults
7. Check storage hierarchy suffices for expiring-soon filters (fridge drawers vs freezer bins)

## Dependencies
- None