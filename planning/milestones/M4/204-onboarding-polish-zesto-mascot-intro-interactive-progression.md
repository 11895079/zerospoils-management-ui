# 204: Onboarding Polish — Zesto Mascot Intro & Interactive Progression

**Epic:** UX Polish & Gamification  
**Milestone:** M3 (MVP Quality & Shopping)  
**Priority:** P2  
**Size:** M  
**Dependencies:** 145 (onboarding first-run flow), 300 (badge system foundation), 350 (Zesto Phase 1 triggers), 375 (app-wide UX baseline + in-context guidance model)

---

## Context

The current onboarding flow (M2/145) is functional but static — users see 6 screens of text and permission prompts without emotional engagement or early introduction to the mascot. M3/350 adds Zesto to the app, but introduces him *after* onboarding completes. This misses an opportunity to set the tone for gamification early and make the first experience more memorable and fun.

Users should meet Zesto during onboarding and interact with him as part of the journey, creating a sense of companionship from the start rather than treating him as an add-on post-launch.

---

## Goal

Enhance the onboarding flow with Zesto animations, interactive elements, and a sense of progression so new users feel welcomed, excited, and primed for the gamified experience that follows.

---

## Expected behavior

- **Zesto intro screen** (new screen 1 of 7): User meets Zesto with a simple animation (fade-in, bounce, wave). Copy is warm and introduces the "waste reduction buddy" concept. Zesto is persistent on this screen and responds to user taps (giggles, changes expression).
- **Zesto on progress screens**: Zesto appears as a semi-transparent avatar in the corner of 2–3 subsequent onboarding screens (e.g., "Track Your Inventory" screen) with context-appropriate animations (nods, gives thumbs up). Tapping Zesto plays a short encouraging sound + haptic.
- **Interactive badge preview** (integrated into the final permissions/presets screen): Shows 1–2 example badges from the 20-badge system with Zesto pointing at them. Copy: "Unlock badges like these as you use ZeroSpoils!" Tapping a badge shows its unlock condition. Zesto reacts with celebration when any badge is tapped.
- **Preset selection screen** (before final "Continue to App"): Zesto offers a warm send-off message: "Ready to reduce waste? Let's go!" with a thumbs-up or wave animation.
- **Post-onboarding celebration**: After completing onboarding and adding the first item, Zesto appears with a celebratory message: "Welcome to the team! Your first item is tracked. Let's save that food!" with confetti or celebratory animation.
- Tapping Zesto at any point during onboarding emits a telemetry event (`mascot_tapped_during_onboarding`) to measure engagement.
- All Zesto animations use simple Dart code (Lottie optional, but custom animations via `Transform` + `AnimationController` are preferred for MVP).
- Onboarding flow is extended from 6 to 7 screens by adding the Zesto intro screen and integrating badge preview content into the final screen.

---

## Acceptance criteria (Definition of Done)

### Screens & Visuals
- [ ] Onboarding flow extends from 6 to 7 screens
- [ ] New screen 1: "Meet Zesto" with animation (fade-in + bounce) and Zesto responds to taps (giggles sound + expression change)
- [ ] Screens 2–4: Zesto appears as semi-transparent corner avatar with context reactions (nod on "Track", thumbs-up on "Smart Reminders")
- [ ] Final permissions/presets screen includes a "Badge Preview" section showing 2–3 example badge icons with unlock conditions; Zesto celebrates when badge is tapped
- [ ] Final preset screen: Zesto gives warm send-off ("Ready to reduce waste? Let's go!") with wave or thumbs-up animation
- [ ] Post-onboarding: On home screen after first item added, Zesto shows celebratory popup ("Welcome to the team! Your first item is tracked. Let's save that food!")

### Interactions & Animations
- [ ] Zesto responds to user taps with sound (giggle/chime) and haptic feedback (light haptic)
- [ ] All Zesto animations use `AnimationController` + `Transform` or similar Dart-native approach (not platform-specific assets)
- [ ] Animations are smooth (60 fps), snappy (200–400 ms duration), and feel cohesive with app theme
- [ ] Tapping any Zesto element during onboarding emits `mascot_tapped_during_onboarding` telemetry event

### Data & Persistence
- [ ] Onboarding completion flag persists (already covered by M2/145; no change needed)
- [ ] Track `onboarding_zesto_interactions` (count of taps/engagement during flow) in telemetry
- [ ] Post-onboarding celebration only fires once (store `first_item_zesto_celebration_shown` flag in prefs)

### Testing
- [ ] Widget tests: verify Zesto appears on each screen where expected
- [ ] Widget tests: tapping Zesto triggers animation and sound (mock sound via `SystemSound.click` or similar)
- [ ] Widget tests: post-onboarding celebration popup shows after first item is added
- [ ] Integration test: end-to-end onboarding + first item add shows celebration
- [ ] Telemetry: `onboarding_started`, `mascot_tapped_during_onboarding`, `onboarding_completed`, and celebratory event all logged

### Accessibility
- [ ] Zesto taps are labeled with semantic hints ("Tap Zesto for encouragement")
- [ ] All animations respect `MediaQuery.of(context).disableAnimations` for accessibility users
- [ ] Sound is never the sole feedback channel (haptic always present)

---

## Out of scope

- Full Lottie animation library integration (use simple Dart animations for MVP)
- Advanced ML-driven personalization of Zesto messages (static variations per trigger is sufficient)
- Zesto customization or alternative mascot variants
- Voice synthesis for Zesto (text + sound effects only)

---

## Implementation notes

**Zesto Asset Requirements:**
- Static Zesto SVG or PNG (current design from Figma or design system)
- Optional: 2–3 simple expression variations (happy, celebrating, thinking) — can be simple color/emoji variations or slight scale changes
- Animations built with `AnimatedBuilder` + `AnimationController` rather than external libraries

**Screen Order (7 total after this change):**
1. Welcome (unchanged)
2. **[NEW] Meet Zesto** — intro animation + tap to giggle
3. Problem (unchanged, Zesto in corner)
4. Solution (unchanged, Zesto in corner)
5. Workflow (unchanged, Zesto in corner)
6. Waste (unchanged, Zesto in corner)
7. Permissions + Presets + Badge Preview + Continue (final screen, Zesto send-off)

**Sound & Haptics:**
- Use `SystemSound.click` for Zesto giggle/tap feedback
- `HapticFeedback.lightImpact()` for every Zesto interaction (respects user preference from settings once M3/203 is shipped)
- All sounds tied to telemetry for A/B testing engagement

**Post-Onboarding Celebration:**
- Trigger: on first `Item.create()` after `onboarding_complete == true` and `first_item_zesto_celebration_shown == false`
- Show a simple animated popup/overlay with Zesto + message for 3 seconds, then auto-dismiss
- Emit `first_item_added_celebration` telemetry event

---

## Test plan

**Automated:**
- Unit test: `OnboardingScreen` state includes `_zestoTapCount` that increments on tap
- Widget test: verify Zesto renders on screen 1 with animation trigger
- Widget test: tapping Zesto emits telemetry event `mascot_tapped_during_onboarding`
- Widget test: Zesto appears in corner of screens 2–4 and responds to tap with sound mock
- Widget test: badge preview screen renders 2–3 badge icons; tapping badge triggers Zesto celebration animation
- Widget test: post-onboarding celebration fires after first item added (mock `ItemRepository.create()`)
- Widget test: post-onboarding celebration only shows once (flag persists across sessions)
- Integration test: full onboarding + first item add flow verifies celebration appears

**Manual:**
1. Fresh install → onboarding starts; verify Zesto intro screen has fade-in + bounce animation
2. Tap Zesto on intro screen → hear giggle sound + see haptic vibration + Zesto expression changes
3. Proceed through onboarding → verify Zesto appears in corner of 2–3 screens with context reactions (nod, thumbs-up)
4. Reach badge preview screen → verify badges display with unlock conditions; tap one and see Zesto celebrate
5. Complete preset selection → verify Zesto gives send-off with wave animation
6. Finish onboarding; add first item to inventory → verify celebration popup with Zesto appears for ~3 seconds
7. Add second item → verify celebration does NOT reappear (one-time flag)
8. Return to Settings → reopen onboarding; verify celebration is skipped since `onboarding_complete == true` already
9. Disable haptics in Settings (M3/203) → re-run onboarding; verify Zesto still animates but haptic is suppressed
10. Screen reader / accessibility mode → verify Zesto taps are labeled; verify animations are disabled when system accessibility setting is on

---

## Dependencies

- M2/145 onboarding first-run flow (base to enhance)
- M3/203 haptic and sound feedback settings (for preferences integration)
- M3/300 badge system foundation (for badge preview visual)
- M3/350 Zesto Phase 1 (defines core mascot message system; this issue layers UI/UX on top)

---

## Notes

This issue bridges the gap between the functional onboarding (M2/145) and the gamified mascot system (M3/350) by making the first experience emotionally engaging and setting expectations for the interactive, companion-focused design that follows. The early introduction of Zesto and interactive feedback (taps, sounds, animations) primes users for the badge unlocks, streak celebrations, and other gamification elements coming in later milestones.
