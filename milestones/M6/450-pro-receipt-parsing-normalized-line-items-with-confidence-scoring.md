## Context
OCR output must be transformed into usable inventory items.

## Goal
Build a parser that produces normalized line items with confidence scores.

## Expected behavior
- Line items are extracted with product name, quantity, price (optional), and confidence
- User can review and correct

## Acceptance criteria (Definition of Done)
- [ ] Define normalized `ReceiptLineItem` schema
- [ ] Implement parsing rules and fallback heuristics
- [ ] Compute confidence scoring per line item
- [ ] Persist results and link to receipt job
- [ ] Unit tests with golden fixtures for receipts
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Automatic expiry prediction (later).

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
