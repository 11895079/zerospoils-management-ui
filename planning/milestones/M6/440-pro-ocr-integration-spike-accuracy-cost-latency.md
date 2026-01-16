## Context
Before committing, validate OCR quality on real grocery receipts.

## Goal
Run a spike to evaluate OCR options and document results.

## Expected behavior
- Team has a documented recommendation
- Baseline accuracy metrics collected

## Acceptance criteria (Definition of Done)
- [ ] Test at least 3 receipt types (Walmart, Costco, Loblaws/Metro) and 10 samples each
- [ ] Measure line item extraction accuracy and failure modes
- [ ] Estimate per-receipt cost and latency
- [ ] Document recommendation in `docs/pro/ocr-spike.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Production-grade OCR pipeline.

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- Issue 235: ML infrastructure (evaluation metrics, baseline dataset schema)
