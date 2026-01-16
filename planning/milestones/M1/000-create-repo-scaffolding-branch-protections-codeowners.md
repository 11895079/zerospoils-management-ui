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
**Automated:**
- GitHub API script to verify branch protection rules exist and require PR reviews
- Parse CODEOWNERS and validate all paths reference existing directories

**Manual:**
1. Attempt direct push to main (should fail)
2. Create PR without required reviewers (should block)
3. Verify CODEOWNERS routes /lib changes to maintainers
4. Confirm CONTRIBUTING.md renders correctly on GitHub

## Dependencies
- None