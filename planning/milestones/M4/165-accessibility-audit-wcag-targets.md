```markdown
## Context
Accessibility is a cross‑cutting requirement; MVP issues mention basics but lack a dedicated audit and remediation plan.

## Goal
Run an accessibility audit, define WCAG targets, and implement remediation tasks with tests.

## Expected behavior
- Define WCAG AA targets for core screens.
- Provide an accessibility checklist and automated test coverage for key views.

## Acceptance criteria (Definition of Done)
- [ ] WCAG AA success criteria documented for MVP screens.
- [ ] Accessibility smoke tests added to CI (a11y checks for labels, contrast, tap targets).
- [ ] Key widgets updated to include semantics, accessible labels and focus order.
- [ ] Manual audit report and remediation backlog created.
- [ ] Tab/page header text contrast improved: ensure minimum 4.5:1 contrast ratio for Inventory, Expiring Soon, Shopping tab headers against green background; consider darker text color or lighter background variant.

## Out of scope
- Full WCAG AAA compliance for v1.

## Implementation notes
- Use Flutter accessibility testing tools and manual audits with a screen reader.

## Test plan
- CI runs basic a11y checks; manual screen reader walkthrough on main flows.

## Dependencies
- `150-mvp-inventory-list-screen-search-filter.md`

```
