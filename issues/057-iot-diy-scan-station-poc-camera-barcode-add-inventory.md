## Context
A countertop scan station can reduce friction for power users.

## Goal
Prototype a Raspberry Pi (or similar) pipeline that scans barcodes and adds items.

## Expected behavior
- Barcode scan triggers an add event
- User can confirm on phone

## Acceptance criteria (Definition of Done)
- [ ] Define reference hardware and software stack
- [ ] Implement barcode recognition pipeline
- [ ] Call webhook API to create a pending item
- [ ] Document build guide and demo steps in `docs/iot/scan-station.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Production hardware product.

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
