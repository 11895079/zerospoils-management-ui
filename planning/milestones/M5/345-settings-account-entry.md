## Context
The Settings screen includes an Account row for sign-in and profile access. There is no defined behavior or placement in milestones for the entry point.

## Goal
Add a Settings Account entry point that routes users to the account/sign-in flow.

## Expected behavior
- Settings → Account & Data → Account
- If signed out: show sign-in CTA
- If signed in: show account summary and sign-out option
- No backend requirements until M6

## Acceptance criteria (Definition of Done)
- [ ] Account entry in Settings navigates to account screen or sign-in flow
- [ ] Signed-out state shows CTA and benefits of account
- [ ] Signed-in state shows email and sign-out action
- [ ] Telemetry event: `account_settings_opened` { signed_in: bool }
- [ ] Widget tests for entry presence and navigation
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Household sharing and sync (M6)
- Full auth backend integration

## Implementation notes
- Use placeholder screen until M6/470 is implemented
- Keep UI copy aligned with future sync benefits

## Test plan
**Automated:**
- Widget test: tapping Account navigates to placeholder screen
- Unit test: signed-in vs signed-out rendering

**Manual:**
1. Tap Account from Settings
2. Verify sign-in CTA when signed out
3. Verify account summary when signed in (mock)

## Dependencies
- M6/470 household accounts