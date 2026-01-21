# 360: Zesto Phase 2 — Advanced Animations & Storage Tips UI

**Epic:** Mascot & Gamification  
**Milestone:** M4 (Polish & Launch)  
**Priority:** P2  
**Size:** M  
**Dependencies:** 350 (Zesto Phase 1 core triggers)

---

## Context
Phase 1 (issue 350) implements 10 core mascot triggers with basic animations (bounce, bubble pop). To make Zesto more expressive and delightful, we need advanced animations for different emotional states (celebration, encouragement, etc.) and enhanced storage tip UI with images/icons.

See full specification: `planning/docs/zesto-mascot-spec.md` (Section 5: Animation & Behavior Specifications)

---

## Goal
Add 4 advanced animation states (celebrate, shake, wave, enhanced disappear) and create rich storage tip UI with category icons, longer display time, and optional "Learn More" link to storage guide.

---

## Expected behavior

### 4 Advanced Animation States
1. **Celebrate** (badges, milestones, zero waste)
   - Larger bounce with rotation (±15°)
   - Scale pulse (1.0 → 1.2 → 1.0)
   - Duration: 0.5s
   - Confetti burst in background (optional)

2. **Shake head** (waste events — GENTLE, not judgmental)
   - Gentle rotate -15° ↔ +15° (2 oscillations)
   - Duration: 0.4s
   - Used sparingly, only with educational tips

3. **Wave** (daily welcome, friend join, return after 7+ days)
   - Scale pulse (1.0 → 1.15 → 1.0)
   - Slight rotation (0° → 10° → 0°)
   - Duration: 0.6s
   - More energetic than idle bounce

4. **Enhanced disappear** (smoother exit)
   - Opacity 1 → 0 with slight drop (translateY +10px)
   - Scale 1 → 0.95 (subtle shrink)
   - Duration: 0.3s
   - Feels more natural than simple fade

### Storage Tips Rich UI
When `wasted` trigger fires, show enhanced tip card:
- **Category icon** (🥛 dairy, 🥕 produce, 🥩 meat, 🍞 bread, 🍲 leftovers)
- **Bold tip text** (larger font, 14px → 16px)
- **Longer display time** (6 seconds instead of 3s for educational content)
- **Optional "Learn More" link** (opens storage guide article — defer to M4 if no guide yet)

### Animation Trigger Mapping
| Trigger | Animation State |
|---------|-----------------|
| Badge unlocked | Celebrate |
| Streak milestone (10/30/100 days) | Celebrate |
| Savings milestone ($100/$500) | Celebrate |
| Zero waste week/month | Celebrate |
| Daily welcome | Wave |
| Friend join (Pro) | Wave |
| Return after 7+ days | Wave |
| Item wasted | Shake (gentle, with tip) |
| All others | Default (bounce) |

---

## Acceptance criteria (Definition of Done)

### Animations
- [ ] Implement `@keyframes mascotCelebrate`: bounce + rotation + scale pulse (0.5s)
- [ ] Implement `@keyframes mascotShake`: gentle -15° ↔ +15° rotation (0.4s, 2 oscillations)
- [ ] Implement `@keyframes mascotWave`: scale pulse + rotation (0.6s)
- [ ] Implement enhanced `@keyframes mascotDisappear`: fade + drop + shrink (0.3s)
- [ ] Update `showMascot()` to accept optional `animationState` parameter
- [ ] Map trigger types to animation states (badgeUnlocked → celebrate, dailyWelcome → wave, etc.)

### Storage Tips Rich UI
- [ ] Create `.mascot-bubble-tip` CSS class for enhanced tip styling
- [ ] Add category icon logic: map item category → emoji (dairy → 🥛, produce → 🥕, etc.)
- [ ] Increase tip font size from 12px to 16px (easier to read)
- [ ] Increase tip display time from 3s to 6s (educational content needs more time)
- [ ] Add optional "Learn More →" link at bottom of tip bubble (if storage guide exists)
- [ ] Style link: 12px, green color (#2f9e44), underline on hover

### Positioning & Timing
- [ ] Celebrate animation triggers confetti burst in background (reuse existing confetti)
- [ ] Shake animation is GENTLE (not harsh or judgmental)
- [ ] Wave animation feels energetic but not overwhelming
- [ ] Enhanced disappear works with all animation states (no visual glitches)

### UI/UX
- [ ] All animations feel delightful, not distracting
- [ ] Celebrate animation duration doesn't block user (0.5s max)
- [ ] Storage tips are easily readable with icon + larger text
- [ ] "Learn More" link is obvious but not obtrusive

### Telemetry
- [ ] `mascot_shown` event includes `animationState` property
- [ ] `mascot_tip_learn_more_tapped` event fires when user taps link

### Accessibility
- [ ] Animations respect `prefers-reduced-motion` (disable celebrate/shake/wave if user prefers)
- [ ] Storage tips have 6s minimum display (sufficient reading time)
- [ ] Category icons have alt text (for screen readers)

### Tests
- [ ] Widget test: Celebrate animation plays correctly on badge unlock
- [ ] Widget test: Shake animation plays correctly on waste event
- [ ] Widget test: Wave animation plays correctly on daily welcome
- [ ] Widget test: Enhanced disappear works after all animation types
- [ ] Widget test: Storage tip displays with correct icon for each category
- [ ] Unit test: `prefers-reduced-motion` disables complex animations
- [ ] Integration test: Earn badge → verify celebrate animation + confetti burst

---

## Out of scope
- Full storage guide articles (just link placeholder if guide doesn't exist yet)
- Recipe suggestions from expiring items — defer to M5
- Tap-to-cycle-tips interaction — defer to M5 (issue 370)
- Seasonal animations (holiday themes, Earth Day special) — defer to M5+

---

## Implementation notes

### Celebrate Animation (CSS)
```css
@keyframes mascotCelebrate {
  0% {
    transform: translateY(0) rotate(0deg) scale(1);
  }
  25% {
    transform: translateY(-20px) rotate(-15deg) scale(1.1);
  }
  50% {
    transform: translateY(-30px) rotate(0deg) scale(1.2);
  }
  75% {
    transform: translateY(-20px) rotate(15deg) scale(1.1);
  }
  100% {
    transform: translateY(0) rotate(0deg) scale(1);
  }
}

.mascot-character.celebrate {
  animation: mascotCelebrate 0.5s cubic-bezier(0.68, -0.55, 0.265, 1.55);
}
```

### Shake Animation (CSS)
```css
@keyframes mascotShake {
  0%, 100% {
    transform: rotate(0deg);
  }
  25% {
    transform: rotate(-15deg);
  }
  75% {
    transform: rotate(15deg);
  }
}

.mascot-character.shake {
  animation: mascotShake 0.4s ease-in-out 2; /* 2 iterations */
}
```

### Wave Animation (CSS)
```css
@keyframes mascotWave {
  0%, 100% {
    transform: scale(1) rotate(0deg);
  }
  33% {
    transform: scale(1.15) rotate(10deg);
  }
  66% {
    transform: scale(1.05) rotate(-5deg);
  }
}

.mascot-character.wave {
  animation: mascotWave 0.6s ease-in-out;
}
```

### Enhanced Disappear (CSS)
```css
@keyframes mascotDisappearEnhanced {
  0% {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
  100% {
    opacity: 0;
    transform: translateY(10px) scale(0.95);
  }
}

.mascot.hide {
  animation: mascotDisappearEnhanced 0.3s ease-out forwards;
}
```

### Storage Tip Rich UI (CSS)
```css
.mascot-bubble-tip {
  background: white;
  border-radius: 12px;
  padding: 14px 16px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  max-width: 280px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.mascot-bubble-tip-header {
  display: flex;
  align-items: center;
  gap: 10px;
}

.mascot-bubble-tip-icon {
  font-size: 24px;
}

.mascot-bubble-tip-text {
  font-size: 16px;
  font-weight: 500;
  color: #333;
  line-height: 1.4;
}

.mascot-bubble-tip-link {
  font-size: 12px;
  color: #2f9e44;
  text-decoration: none;
  align-self: flex-end;
  margin-top: 4px;
}

.mascot-bubble-tip-link:hover {
  text-decoration: underline;
}
```

### Updated showMascot() Function
```dart
void showMascot(String messageType, {String? animationState}) {
  // ... (anti-spam logic, message selection)
  
  // Determine animation state if not provided
  animationState ??= _getAnimationForTrigger(messageType);
  
  // Apply animation class
  final mascotElement = document.querySelector('.mascot-character');
  mascotElement.classList.add(animationState); // 'celebrate', 'wave', 'shake', etc.
  
  // Trigger confetti for celebrate animation
  if (animationState == 'celebrate') {
    triggerConfetti();
  }
  
  // Adjust display time for tips (6s instead of 3s)
  final displayDuration = messageType == 'wasted' ? 6000 : 3000;
  
  // ... (show bubble, auto-dismiss after displayDuration)
}

String _getAnimationForTrigger(String messageType) {
  switch (messageType) {
    case 'badgeUnlocked':
    case 'streakMilestone':
    case 'savingsMilestone':
    case 'zeroWaste':
      return 'celebrate';
    case 'dailyWelcome':
    case 'friendJoin':
      return 'wave';
    case 'wasted':
      return 'shake';
    default:
      return 'default'; // Regular bounce
  }
}
```

### Category Icon Mapping
```dart
Map<String, String> categoryIcons = {
  'dairy': '🥛',
  'produce': '🥕',
  'meat': '🥩',
  'bread': '🍞',
  'leftovers': '🍲',
  'condiments': '🥫',
  'beverages': '☕',
  'snacks': '🍿',
  'frozen': '❄️',
  'general': '💡',
};
```

---

## Test plan

### Automated tests

**Widget tests (animations):**
1. Widget test: Trigger `badgeUnlocked` → verify celebrate animation plays (rotation + scale)
2. Widget test: Trigger `wasted` → verify shake animation plays (gentle oscillation)
3. Widget test: Trigger `dailyWelcome` → verify wave animation plays (scale + rotation)
4. Widget test: Verify enhanced disappear animation on auto-dismiss
5. Widget test: Verify confetti triggers on celebrate animation

**Widget tests (storage tips UI):**
6. Widget test: Waste dairy item → verify tip shows with 🥛 icon and larger text
7. Widget test: Waste produce item → verify tip shows with 🥕 icon
8. Widget test: Verify tip displays for 6 seconds (not 3s like regular messages)
9. Widget test: Verify "Learn More →" link appears and is tappable
10. Widget test: Tap "Learn More" → verify telemetry event fires

**Accessibility tests:**
11. Unit test: `prefers-reduced-motion` disables celebrate/shake/wave (falls back to default)
12. Widget test: Storage tips remain visible for 6s minimum (sufficient reading time)

**Integration tests:**
13. Integration test: Earn badge → celebrate animation + confetti + "New badge! 🏆" message
14. Integration test: Waste item → shake animation + storage tip with icon + 6s display

### Manual testing

**Animation verification:**
1. Earn any badge → verify Zesto does celebrate animation (bounce + rotate + scale)
2. Verify confetti burst accompanies celebrate animation
3. Waste an item → verify Zesto does gentle shake (not harsh)
4. Open app first time today → verify Zesto does wave animation
5. Wait 3s after regular message → verify smooth disappear with drop effect

**Storage tips UI:**
6. Waste dairy item → verify tip shows "💡 Store milk in back of fridge!" with 🥛 icon
7. Waste produce item → verify different tip with 🥕 icon
8. Verify tip text is larger and easier to read than regular messages
9. Verify tip displays for ~6 seconds (count manually)
10. Tap "Learn More" link → verify it's tappable and logs telemetry (if link active, navigates to guide)

**Accessibility:**
11. Enable "Reduce Motion" in OS settings → verify complex animations disabled (just gentle fade in/out)
12. Verify all animations feel delightful, not overwhelming
13. Verify shake animation on waste events doesn't feel judgmental (test with 5 different people)

**Edge cases:**
14. Trigger celebrate animation twice rapidly → verify both animate correctly (no conflict)
15. Dismiss mascot mid-animation → verify smooth exit (no visual glitches)

---

## Dependencies
- **350:** Zesto Phase 1 — Core triggers (must be implemented first)
- Existing confetti animation (reuse for celebrate state)

---

## Related issues
- **350:** Zesto Phase 1 — Core triggers (prerequisite)
- **370:** Zesto Phase 3 — Tap-to-cycle-tips interaction
- **375:** Zesto Phase 3 — Unlockable mascot characters
- **380:** Zesto Phase 3 — Settings controls

---

## Milestone placement: M4 (Polish & Launch)
This is a **polish feature** that enhances the mascot experience but isn't required for MVP. Launch readiness is about delight and personality, making M4 the perfect fit.
