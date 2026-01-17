## Context
A stable model reduces rework and enables future scanning/analytics.

## Goal
Define canonical domain model and event log strategy.

## Expected behavior
- Item supports name, category, location, quantity/unit, expiry_date
- Events capture state changes for insights

## Acceptance criteria (Definition of Done)
- [x] Create `docs/data-model.md` with schema
- [x] Define enums for category/location
- [x] Define waste_reason draft enum
- [x] Migration strategy documented
- [x] Unit/widget/integration tests added or updated (N/A - documentation only)
- [x] Telemetry added/updated (event names + key properties documented in data model)
- [x] Offline-first behavior verified (where applicable - documented in model)
- [x] Accessibility basics (labels, contrast, tap targets - N/A for documentation)

## Out of scope
- Not defined

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
**Automated:**
- JSON schema validation for `docs/data-model.md` entity definitions
- Verify all enums (category, location, waste_reason) have at least 3 values
- Script checks migration strategy section exists and includes versioning approach

**Manual:**
1. Review data model with engineering team for normalization
2. Trace each MVP feature to required model entities/fields
3. Validate event log design supports analytics queries (e.g., waste by category)
4. Confirm quantity/unit handling supports common cases (count, weight, volume)
5. Review migration strategy for backward compatibility

## Dependencies
- None