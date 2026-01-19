## Context
Codex/Copilot work best with a crisp scope and acceptance criteria.

## Goal
Produce a single source of truth for MVP features and non-goals.

## Expected behavior
- MVP scope documented with explicit DoD for each feature
- Non-goals listed to prevent scope creep

## Acceptance criteria (Definition of Done)
- [ ] Create `docs/mvp.md` documenting MVP: manual item entry/edit, inventory + expiring views, reminders, shopping list, offline-first
- [ ] Add explicit non-goals (meal planning, required IoT hardware, selling data without consent)
- [ ] Add MVP success metrics (items added/week, reminder actions, retention)
- [ ] Document reviewed with product lead for completeness and alignment
- [N/A] Unit/widget/integration tests (documentation only)
- [N/A] Telemetry instrumentation (documented in dedicated telemetry issue)
- [N/A] Accessibility testing (not applicable to documentation)

## Out of scope
- Not defined

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
**Automated:**
- Markdown linter validates `docs/mvp.md` structure (required sections present)
- Script verifies all MVP features have corresponding issue files

**Manual:**
1. Review `docs/mvp.md` with product lead for completeness
2. Verify non-goals section prevents scope creep discussions
3. Confirm success metrics are measurable and tied to telemetry events
4. Team walkthrough to ensure shared understanding

## Dependencies
- None
