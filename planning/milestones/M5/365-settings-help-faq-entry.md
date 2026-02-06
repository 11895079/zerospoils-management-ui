## Context
The Settings screen includes a Help & FAQ link but there is no defined behavior or implementation plan for the entry point.

## Goal
Add a Settings entry point for Help & FAQ that routes to the help center stub.

## Expected behavior
- Settings → Support & Feedback → Help & FAQ
- Opens in-app FAQ/help center or external page (per M5/360)

## Acceptance criteria (Definition of Done)
- [ ] Settings entry opens help center stub (M5/360)
- [ ] Telemetry event: `help_tapped` { source: "settings" }
- [ ] Widget test verifies row and tap behavior
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full help center content (handled in M5/360)

## Implementation notes
- Reuse existing help center route or URL constants

## Test plan
**Automated:**
- Widget test: Help & FAQ row present and tappable

**Manual:**
1. Tap Help & FAQ
2. Confirm help center opens

## Dependencies
- M5/360 in-app FAQ/help center stub