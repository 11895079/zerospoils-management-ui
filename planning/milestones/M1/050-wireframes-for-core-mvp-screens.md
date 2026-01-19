## Context
UX foundations (wireframes, interaction patterns, component primitives, design tokens) guide consistent implementation across screens.

## Goal
Deliver complete UX foundations: wireframes for MVP flows, interaction patterns, component guidelines, and design tokens.

## Expected behavior
- Wireframes cover: Add Item, Inventory, Expiring Soon, Item Detail, Shopping List, Settings
- Navigation is consistent and minimal
- Interaction primitives defined: quick add, scan flow, confirm dialogs, swipe actions
- Design tokens documented: spacing, typography, touch targets, color palette
- Accessibility notes included: tap targets ≥44pt, contrast ratios, font scaling

## Acceptance criteria (Definition of Done)
- [ ] Wireframes created under `docs/wireframes/` and linked in `docs/ux.md`
- [ ] Includes empty states + onboarding flows
- [ ] UX patterns doc created with component guidelines (buttons, lists, cards, modals)
- [ ] Design tokens documented in `docs/design-tokens.md`
- [ ] Reviewed by at least one team member (engineering + product)
- [ ] Clickable prototype (060) references patterns and tokens
- [ ] Accessibility annotations included on wireframes (tap targets ≥44pt, contrast ≥4.5:1, semantic labels)
- [N/A] Unit/widget/integration tests (documentation only)
- [N/A] Offline-first behavior verification (implementation concern, not wireframes)
- [N/A] Telemetry instrumentation (implemented in feature work)

## Out of scope
- High-fidelity visual design system and final brand assets (handled in launch milestone)

## Implementation notes
- Use grayscale wireframes; keep patterns pragmatic and mobile-first
- Prefer simple interactions that minimize typing
- Decide default lead times and buckets for notifications

## Test plan
**Automated:**
- Parse `docs/ux.md` and verify all wireframe files referenced exist
- Validate `docs/design-tokens.md` contains required sections (spacing, typography, colors, touch targets)

**Manual:**
1. Review wireframes with engineering team for feasibility
2. Validate accessibility annotations (tap targets, contrast) on all screens
3. Confirm navigation flow matches documented patterns
4. Run clickable prototype walkthrough with 5 users (see 060)

## Dependencies
- None
