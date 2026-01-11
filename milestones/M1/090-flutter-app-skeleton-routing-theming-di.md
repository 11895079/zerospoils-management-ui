## Context
Establish a maintainable architecture for rapid iteration.

## Goal
Create a Flutter shell with routing, theming, and DI.

## Expected behavior
- App launches to home shell
- Navigation between tabs works
- Theme tokens defined

## Acceptance criteria (Definition of Done)
- [ ] Project compiles for iOS and Android
- [ ] State management approach selected and documented
- [ ] Routing supports deep links later
- [ ] Includes base components (buttons/cards)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Not defined

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
**Automated:**
- Widget test: verify app launches and renders home screen
- Widget test: navigate between all tabs, assert each screen renders
- Unit test: verify DI container resolves all registered services
- Integration test: deep link handling (simulate opening app with link)

**Manual:**
1. `flutter run` on iOS simulator (verify compile and launch)
2. `flutter run` on Android emulator (verify compile and launch)
3. Navigate between all tabs and verify smooth transitions
4. Verify theme tokens applied (spacing, colors, typography)
5. Test on physical device for performance baseline

## Dependencies
- None
