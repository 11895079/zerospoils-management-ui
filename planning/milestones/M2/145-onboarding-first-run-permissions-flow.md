```markdown
## Context
New users need a fast, guided path to reach value (add first items) and understand privacy/perms.

## Goal
Design and implement first‑run onboarding and permission flows that reduce drop‑off.

## Expected behavior
- On first launch, user sees a short flow explaining core value and is guided to add their first 1–3 items.
- Permission prompts (camera, notifications) are shown inline with clear justification and an option to defer.
- Onboarding is skippable and can be re-opened from settings.

## Acceptance criteria (Definition of Done)
- [x] Onboarding screens implemented in Flutter with localizable copy (2/3 pages for short variant).
- [x] Camera and notification permission prompts are shown with contextual rationale and a "Maybe later" option.
- [x] First‑run flow guides user through onboarding and persists completion flag (routes to home after completion).
- [x] Widget tests for onboarding flows and telemetry instrumentation (10 tests, all passing).
- [x] A/B feature flag implemented (OnboardingVariant enum: short/long) to run experiments on onboarding length.
- [x] Telemetry events: onboarding_started, onboarding_completed, permission_prompt_shown, permission_deferred, onboarding_skipped.
- [x] Router dynamically sets initial location based on onboarding_complete flag.

## Implementation status
**Completed:** February 3, 2026
**PR:** [Main commit 7264c7d](https://github.com/your-repo/commit/7264c7d)
**Key files:**
- `lib/presentation/screens/onboarding_screen.dart` (274 lines): Multi-page PageView with telemetry
- `lib/presentation/widgets/camera_permission_prompt.dart` (59 lines): Camera permission dialog
- `lib/presentation/widgets/notification_permission_prompt.dart`: Enhanced notification flow
- `lib/presentation/routing/router.dart`: Dynamic initial location based on onboarding status
- `lib/main.dart`: Updated initialization to check onboarding_complete flag
- `test/widget/onboarding_flow_test.dart` (296 lines): 10 comprehensive widget tests

**Test results:** All 138 tests passing

## Out of scope
- Deep personalization; rigorous experimentation frameworks (basic A/B support only).

## Implementation notes
- Keep flows short (3 screens max) and mobile‑friendly. Use feature flags for experiments.

## Test plan
 **Automated:**
 - Widget: first-run shows onboarding, skip returns to home, reopen from settings works
 - Widget: camera and notification permission prompts appear contextually with deferral option
 - Telemetry: `onboarding_started`, `onboarding_completed`, `permission_prompt_shown` (type), `permission_deferred` events emitted
 - Feature flag: A/B toggle switches between short (1–2 screens) and long (3 screens) flow

 **Manual:**
 1. Fresh install → onboarding appears; complete flow and add 1–3 items
 2. Tap "Maybe later" on camera permission → proceed without blocking; verify manual add still works
 3. Enable notifications permission when prompted → see success confirmation; navigate back
 4. Skip onboarding → from Settings, reopen onboarding and complete; verify telemetry records conversion
 5. Switch A/B flag → experience alternate flow length; verify both paths function

## Dependencies
- `130-feature-flags-framework-prepare-for-pro.md`

```
