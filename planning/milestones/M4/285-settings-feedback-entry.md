## Context
The Settings screen includes a "Send Feedback" entry but there is no defined behavior or tracking for it.

## Goal
Provide a Settings entry point for user feedback that routes to the approved feedback channel and captures metadata.

## Expected behavior
- Settings → Support & Feedback → Send Feedback
- Tapping opens in-app feedback form or prefilled email (per M4/280)
- Includes device/app metadata automatically
- Works offline (queue if needed)

## Acceptance criteria (Definition of Done)
- [ ] Settings entry opens feedback flow defined in M4/280
- [ ] Metadata included: app_version, platform, build_number, locale
- [ ] Telemetry event: `feedback_opened` { source: "settings" }
- [ ] Success and failure states are handled
- [ ] Unit/widget tests added
- [ ] Offline-first verified
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Public community forum integration
- Advanced sentiment analysis

## Implementation notes
- Reuse feedback service defined in M4/280
- If offline, store draft locally and prompt to send later

## Test plan
**Automated:**
- Widget test: tapping Send Feedback launches feedback flow
- Unit test: feedback metadata builder returns required fields

**Manual:**
1. Tap Send Feedback from Settings
2. Verify metadata is prefilled
3. Disable network and retry; confirm queued state

## Dependencies
- M4/280 in-app feedback entry point