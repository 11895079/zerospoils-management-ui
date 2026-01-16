## Context
Users must be able to quickly confirm items and fix mistakes.

## Goal
Create a review workflow that maps receipt line items into inventory items.

## Expected behavior
- User can accept, edit, skip items
- Bulk actions exist (select all, set location)

## Acceptance criteria (Definition of Done)
- [ ] Review screen shows extracted items with confidence indicator
- [ ] Mapping supports category/location defaults
- [ ] On confirm, inventory items created and receipt stored/archived
- [ ] Telemetry: receipt_capture, receipt_review_accept, receipt_review_edit, receipt_review_skip
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Loyalty account ingestion.

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
