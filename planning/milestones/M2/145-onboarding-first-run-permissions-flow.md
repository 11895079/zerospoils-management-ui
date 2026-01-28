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
- [ ] Onboarding screens implemented in Flutter with localizable copy.
- [ ] Camera and notification permission prompts are shown with contextual rationale and a "Maybe later" option.
- [ ] First‑run flow funnels user to the Add Item screen and records a telemetry event for conversion.
- [ ] Unit/widget tests for onboarding flows and telemetry assertions.
- [ ] A/B toggle exists (feature flag) to run experiments on onboarding length.

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
