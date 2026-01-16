## Context
If you ever monetize aggregated analytics, you need explicit consent and strong anonymization boundaries.

## Goal
Define consent model and data export spec (implementation can follow later).

## Expected behavior
- Consent options are clear and revocable
- Export fields are anonymized and aggregated

## Acceptance criteria (Definition of Done)
- [ ] Create `docs/pro/consent-and-aggregation.md` outlining consent UI, retention, aggregation thresholds
- [ ] Define 'no small groups' rule to reduce re-identification risk
- [ ] Define what is never collected/shared (PII, exact addresses, raw receipt images)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Building the actual sales product.

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
