## Context
The Settings screen includes Privacy Policy and Terms of Service links. These should point to the hosted documents and be tracked.

## Goal
Wire Settings legal links to hosted Privacy Policy and Terms pages.

## Expected behavior
- Settings → Legal → Privacy Policy opens hosted page
- Settings → Legal → Terms of Service opens hosted page
- Links open in external browser or in-app webview (consistent with platform policy)

## Acceptance criteria (Definition of Done)
- [ ] Privacy and Terms links open correct hosted URLs (from M5/330)
- [ ] Links are accessible from Settings
- [ ] Telemetry events:
  - `privacy_opened` { source: "settings" }
  - `terms_opened` { source: "settings" }
- [ ] Widget tests for Settings row presence
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Drafting legal copy (handled in M5/330)

## Implementation notes
- Use URL constants from a single config file
- Prefer platform-safe URL launcher

## Test plan
**Automated:**
- Widget test: Settings rows render
- Unit test: URL config returns non-empty URLs

**Manual:**
1. Tap Privacy Policy; verify browser opens correct page
2. Tap Terms of Service; verify browser opens correct page

## Dependencies
- M5/330 privacy policy and terms of service