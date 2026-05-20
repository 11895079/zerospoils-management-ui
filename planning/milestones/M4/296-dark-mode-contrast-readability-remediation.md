## Context
Dark mode toggle support is implemented (M4/295), but several screens still have low-contrast text and secondary labels that are difficult to read when dark theme is enabled. This is now a beta-quality blocker because it impacts usability and accessibility.

## Goal
Audit and remediate dark-mode contrast/readability issues so all core screens meet accessibility contrast targets and remain legible in real usage.

## Expected behavior
- All primary, secondary, helper, hint, and disabled text remains readable in dark mode
- Input fields, chips, cards, badges, banners, and overlays use dark-safe foreground/background combinations
- Dark mode is visually consistent across screens and states (empty/loading/error/success)

## Acceptance criteria (Definition of Done)
- [x] Dark-mode contrast audit completed for core flows: onboarding, inventory, add/edit item, item detail, expiring soon, shopping list, settings, progress, feedback drawer, receipt capture/review
- [x] Text contrast on audited screens meets WCAG AA minimum: 4.5:1 for normal text and 3:1 for large text/icons
- [x] Theme tokens updated where needed to remove hard-coded colors and improve dark-mode readability
- [x] Shared components updated to use semantic colors (not ad hoc overrides)
- [x] Widget tests added/updated for key dark-mode regressions (text/icon color resolution, surface contrast-safe pairings)
- [ ] Manual QA checklist executed on iOS and Android (light and dark themes); deferred to follow-up verification pass, screenshots optional
- [x] Telemetry event logged when users report a dark-mode readability issue from the feedback drawer: `ui_dark_mode_readability_reported`

## Out of scope
- Full design-system rebrand
- Dynamic color extraction from OS wallpaper
- AAA contrast target for all text (AA required for this work item)

## Implementation notes
- Start from existing M4/295 token set and tighten semantic mappings (`onSurface`, `onSurfaceVariant`, `outline`, `error`, `inverse*`)
- Prioritize remediation of small text and helper labels first (most frequent readability failures)
- Avoid one-off inline color fixes in screen widgets; patch theme extensions and shared component styles first
- If screenshots are captured during manual review, treat them as optional supporting evidence rather than a DoD requirement
- Latest manual QA update: Chrome pass completed and surfaced Add/Edit Item title/category visibility issues; both fixed with theme-driven text colors and regression tests. Android and additional iOS device verification remain pending.

## Test plan
**Automated:**
- Widget test: verify critical text widgets resolve to theme-aware colors in dark mode on Inventory, Item Detail, Settings, and Shopping List screens
- Widget test: ensure feedback drawer text, helper copy, and validation/error states are readable in dark mode
- Widget test: ensure chips/badges/callouts use contrast-safe foreground/background combinations in dark theme
- Unit test: theme token mappings produce non-identical foreground/background pairs for semantic text styles

**Manual:**
1. Enable dark mode in Settings and navigate each audited screen
2. Verify title/body/caption/helper/disabled text is readable without squinting on both iOS and Android devices
3. Trigger validation and error states in forms and verify readability
4. Open feedback drawer and verify all labels, placeholders, and buttons are legible
5. If you choose to capture screenshots, compare before/after states and attach them to the PR as optional evidence

## Dependencies
- M4/295 dark mode theme toggle (implemented)
- M4/165 accessibility audit (cross-check targets)
