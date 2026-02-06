## Context
The Settings screen includes a Rate App link for store reviews, but no issue tracks this entry point.

## Goal
Add a Settings entry that opens the App Store / Google Play review flow.

## Expected behavior
- Settings → Support & Feedback → Rate App
- Opens store review page for the current platform

## Acceptance criteria (Definition of Done)
- [ ] Rate App row opens the correct store URL
- [ ] Telemetry event: `rate_app_tapped` { source: "settings" }
- [ ] Widget test verifies row presence and tap handler
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- In-app rating prompts based on usage triggers

## Implementation notes
- Use platform-specific store URL helpers
- Keep URL in config for easy updates

## Test plan
**Automated:**
- Widget test: Rate App row present and tappable
- Unit test: store URL resolver returns platform URL

**Manual:**
1. Tap Rate App on iOS and Android
2. Verify store review page opens

## Dependencies
- None