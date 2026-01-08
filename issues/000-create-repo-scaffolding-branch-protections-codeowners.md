## Context
We need a solid repo baseline for collaborative development with Codex/Copilot and human review.

## Goal
Create a maintainable GitHub repo setup that enforces quality gates.

## Expected behavior
- Main branch protected with required PR reviews
- CODEOWNERS routes reviews to maintainers
- Basic repo hygiene files in place

## Acceptance criteria (Definition of Done)
- [ ] Branch protection rules configured (PR required, status checks required)
- [ ] CODEOWNERS added for /lib, /test, /docs
- [ ] CONTRIBUTING.md includes dev workflow + PR checklist
- [ ] LICENSE added
- [ ] SECURITY.md stub added
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- CI pipeline implementation (separate issue).

## Implementation notes
- Add `.editorconfig` and `.gitattributes`.
- Add PR template with DoD checklist.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
