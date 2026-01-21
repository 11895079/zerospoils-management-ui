# 370: Zesto Phase 3 — Tap-to-Cycle Contextual Tips

**Epic:** Mascot & Gamification  
**Milestone:** M5 (Advanced Features)  
**Priority:** P2  
**Size:** S  
**Dependencies:** 350 (Zesto Phase 1), 360 (Zesto Phase 2 animations)

---

## Context
Currently, Zesto appears automatically based on triggers (item saved, badge earned, etc.) and auto-dismisses after 3-6 seconds. To make Zesto more interactive and useful, users should be able to **tap him** to cycle through contextual tips based on the current page/screen.

See full specification: `planning/docs/zesto-mascot-spec.md` (Section 3.3: User-Initiated Interactions)

---

## Goal
Enable users to tap the Zesto mascot character (when visible) to cycle through 3-5 contextual tips relevant to the current page. Tips rotate randomly from a predefined pool per page, with telemetry to track engagement.

---

## Expected behavior

### Tap Interaction Flow
1. User sees Zesto on screen (from any trigger: celebration, page load, etc.)
2. User taps the mascot character (🥑)
3. Speech bubble updates with a contextual tip for current page
4. Display time extends by 5 seconds (user initiated, so give more time)
5. User can tap again to cycle to next tip (up to 3 tips per appearance)
6. After 3 tips shown, mascot auto-dismisses (prevent infinite cycling)

### Contextual Tips by Page
| Page | Tip Pool (3-5 tips each) |
|------|--------------------------|
| **Inventory** | "💡 Tip: First in, first out (FIFO)!", "Store by expiry date!", "Group items by category!", "Check fridge before shopping!", "Use oldest items first!" |
| **Expiring Soon** | "Freeze items to extend life! ❄️", "Cook a batch meal!", "Use in smoothies/soups!", "Share with neighbors!", "Plan meals around expiring items!" |
| **Shopping List** | "Check inventory first!", "Plan 3-4 days ahead!", "Avoid impulse buys!", "Buy only what you need!", "Shop with a full stomach!" |
| **Progress** | "You've saved X items this week!", "Y% better than last week!", "Z days until next badge!", "$A saved this month!", "Keep up the streak!" |
| **Add Item** | "Don't forget expiry date!", "Group by category!", "Add quantity if multiple!", "Use barcode scan (Pro)!", "Set low stock alerts!" |
| **Settings** | "Enable notifications for expiry alerts!", "Try dark mode!", "Unlock new mascots!", "Export your data!", "Share feedback!" |
| **Onboarding** | (No tap interaction during onboarding — tips are already shown in flow) |

### Dynamic Tips (Progress Page)
Progress page tips should use **real user data**:
- "You've saved **23 items** this week!" (actual count from data)
- "**15% better** than last week!" (actual % improvement)
- "**2 days** until next badge!" (actual days to next streak milestone)
- "**$47 saved** this month!" (actual savings calculated)

---

## Acceptance criteria (Definition of Done)

### Code Implementation
- [ ] Add click/tap event listener to `.mascot-character` element
- [ ] Prevent tap from bubbling (don't dismiss mascot when tapping character)
- [ ] Implement `cycleTip()` function to rotate through tips
- [ ] Create `contextualTips` object with tip pools for each page:
  ```javascript
  const contextualTips = {
    'inventory': ["Tip 1", "Tip 2", ...],
    'expiring-soon': ["Tip 1", "Tip 2", ...],
    'shopping-list': ["Tip 1", "Tip 2", ...],
    'progress': ["Tip 1", "Tip 2", ...],
    'add-item': ["Tip 1", "Tip 2", ...],
    'settings': ["Tip 1", "Tip 2", ...],
  };
  ```
- [ ] Track `tipsCycledThisAppearance` counter (max 3 tips per appearance)
- [ ] Extend display time by 5 seconds on each tap (user-initiated content)
- [ ] Auto-dismiss after 3 tips shown (prevent infinite cycling)
- [ ] Implement dynamic tip generation for Progress page (inject real user stats)

### UI/UX
- [ ] Mascot character has visible tap affordance (subtle scale pulse on hover, or initial bounce suggests interactivity)
- [ ] Speech bubble updates smoothly when tip changes (0.2s fade transition)
- [ ] Tip text wraps correctly if longer than usual (max 3 lines before wrapping)
- [ ] After 3 tips, mascot says "That's all for now! 👋" before dismissing

### Telemetry
- [ ] `mascot_tapped` event fires with properties: `page`, `tipNumber` (1/2/3), `tipContent`
- [ ] `mascot_tips_completed` event fires when user cycles through all 3 tips (engagement metric)

### Accessibility
- [ ] Mascot character has ARIA label "Tap for tips"
- [ ] Tips have 5-second minimum display after tap (sufficient reading time)
- [ ] Keyboard accessible: pressing Enter/Space when mascot focused triggers tap

### Tests
- [ ] Widget test: Tap mascot on inventory page → verify tip updates from inventory pool
- [ ] Widget test: Tap mascot 3 times → verify 3 different tips shown, then auto-dismiss
- [ ] Widget test: Tap mascot on progress page → verify tip includes real user data (e.g., "23 items saved")
- [ ] Unit test: `cycleTip()` doesn't repeat tips within same appearance (tracks shown tips)
- [ ] Unit test: Verify display time extends by 5s on each tap
- [ ] Integration test: Tap mascot 3 times → verify `mascot_tips_completed` telemetry fires

---

## Out of scope
- Persistent tip database (tips hardcoded in app for now)
- "Swipe to cycle tips" gesture (tap only for simplicity)
- Favorite tips / tip history — defer to M6+
- User-submitted tips — defer to M6+
- Video tips or animated tutorials — defer to M6+

---

## Implementation notes

### Contextual Tips Object
```javascript
const contextualTips = {
  'inventory': [
    "💡 Tip: First in, first out (FIFO)!",
    "Store by expiry date!",
    "Group items by category!",
    "Check fridge before shopping!",
    "Use oldest items first!",
  ],
  'expiring-soon': [
    "Freeze items to extend life! ❄️",
    "Cook a batch meal!",
    "Use in smoothies/soups!",
    "Share with neighbors!",
    "Plan meals around expiring items!",
  ],
  'shopping-list': [
    "Check inventory first!",
    "Plan 3-4 days ahead!",
    "Avoid impulse buys!",
    "Buy only what you need!",
    "Shop with a full stomach!",
  ],
  'progress': [
    "You've saved {itemCount} items this week!",
    "{improvementPercent}% better than last week!",
    "{daysToNextBadge} days until next badge!",
    "${savingsThisMonth} saved this month!",
    "Keep up the {streakDays}-day streak!",
  ],
  'add-item': [
    "Don't forget expiry date!",
    "Group by category!",
    "Add quantity if multiple!",
    "Use barcode scan (Pro)!",
    "Set low stock alerts!",
  ],
  'settings': [
    "Enable notifications for expiry alerts!",
    "Try dark mode!",
    "Unlock new mascots!",
    "Export your data!",
    "Share feedback!",
  ],
};
```

### Tap Event Listener
```javascript
// Add tap listener when mascot appears
function showMascot(messageType) {
  // ... (existing logic)
  
  const mascotCharacter = document.querySelector('.mascot-character');
  let tipsCycled = 0;
  let shownTipsThisAppearance = [];
  
  mascotCharacter.addEventListener('click', (e) => {
    e.stopPropagation(); // Prevent dismissing mascot
    
    if (tipsCycled >= 3) {
      // Max 3 tips per appearance
      showMascot('goodbye'); // "That's all for now! 👋"
      setTimeout(dismissMascot, 2000);
      return;
    }
    
    cycleTip(shownTipsThisAppearance);
    tipsCycled++;
    
    // Extend display time by 5 seconds
    clearTimeout(autoDismissTimeout);
    autoDismissTimeout = setTimeout(dismissMascot, 5000);
    
    // Telemetry
    logEvent('mascot_tapped', {
      page: currentPage,
      tipNumber: tipsCycled,
      tipContent: currentTipText,
    });
    
    if (tipsCycled === 3) {
      logEvent('mascot_tips_completed', { page: currentPage });
    }
  });
}

function cycleTip(shownTips) {
  const currentPage = getCurrentPage();
  const tipPool = contextualTips[currentPage] || contextualTips['inventory'];
  
  // Filter out already shown tips
  const availableTips = tipPool.filter(tip => !shownTips.includes(tip));
  
  // If all tips shown, reset
  if (availableTips.length === 0) {
    shownTips.length = 0;
    availableTips.push(...tipPool);
  }
  
  // Select random tip from available
  const selectedTip = availableTips[Math.floor(Math.random() * availableTips.length)];
  shownTips.push(selectedTip);
  
  // Inject dynamic data for progress page
  const displayTip = currentPage === 'progress' 
    ? injectUserStats(selectedTip) 
    : selectedTip;
  
  // Update bubble text with fade transition
  const bubble = document.querySelector('.mascot-bubble');
  bubble.classList.add('fade-out');
  setTimeout(() => {
    bubble.textContent = displayTip;
    bubble.classList.remove('fade-out');
    bubble.classList.add('fade-in');
  }, 200);
}

function injectUserStats(tipTemplate) {
  const stats = getUserStats(); // Get from data layer
  return tipTemplate
    .replace('{itemCount}', stats.itemsSavedThisWeek)
    .replace('{improvementPercent}', stats.improvementPercent)
    .replace('{daysToNextBadge}', stats.daysToNextBadge)
    .replace('{savingsThisMonth}', stats.savingsThisMonth.toFixed(2))
    .replace('{streakDays}', stats.currentStreak);
}
```

### Fade Transition CSS
```css
.mascot-bubble.fade-out {
  opacity: 0;
  transition: opacity 0.2s ease-out;
}

.mascot-bubble.fade-in {
  opacity: 1;
  transition: opacity 0.2s ease-in;
}

.mascot-character:hover {
  cursor: pointer;
  transform: scale(1.05);
  transition: transform 0.2s ease;
}
```

### Keyboard Accessibility
```javascript
mascotCharacter.addEventListener('keydown', (e) => {
  if (e.key === 'Enter' || e.key === ' ') {
    e.preventDefault();
    mascotCharacter.click(); // Trigger tap behavior
  }
});

mascotCharacter.setAttribute('tabindex', '0');
mascotCharacter.setAttribute('aria-label', 'Tap for helpful tips');
mascotCharacter.setAttribute('role', 'button');
```

---

## Test plan

### Automated tests

**Widget tests:**
1. Widget test: Tap mascot on inventory page → verify tip from inventory pool appears
2. Widget test: Tap mascot 3 times → verify 3 different tips shown (no repeats)
3. Widget test: Tap mascot 4th time → verify "That's all for now! 👋" + auto-dismiss after 2s
4. Widget test: Tap mascot on progress page → verify tip includes real user stats ("23 items saved")
5. Widget test: Verify display time extends by 5s after each tap (use fake timers)

**Unit tests:**
6. Unit test: `cycleTip()` returns tips from correct page pool (inventory vs progress vs shopping)
7. Unit test: `cycleTip()` doesn't repeat tips within same appearance (tracks shownTips array)
8. Unit test: `injectUserStats()` correctly replaces placeholders with real data

**Accessibility tests:**
9. Widget test: Press Enter on focused mascot → verify tip cycles (keyboard accessible)
10. Widget test: Press Space on focused mascot → verify tip cycles

**Telemetry tests:**
11. Unit test: Tap mascot → verify `mascot_tapped` event fires with correct properties
12. Unit test: Tap mascot 3 times → verify `mascot_tips_completed` event fires

### Manual testing

**Basic interaction:**
1. Trigger mascot on inventory page → tap mascot → verify tip updates
2. Tap mascot 3 times → verify 3 different tips appear
3. Tap 4th time → verify "That's all for now! 👋" and mascot dismisses after 2s
4. Verify tapping character doesn't dismiss mascot (tap bubble outside dismisses)

**Contextual tips:**
5. Navigate to Expiring Soon page → tap mascot → verify tips are about freezing, batch cooking, etc.
6. Navigate to Shopping List page → tap mascot → verify tips are about planning, checking inventory, etc.
7. Navigate to Progress page → tap mascot → verify tips include real stats ("You've saved 23 items this week!")

**Dynamic data:**
8. Save 10 items this week → tap mascot on Progress → verify "You've saved 10 items this week!"
9. Maintain 7-day streak → tap mascot on Progress → verify "Keep up the 7-day streak!"
10. Save $35 this month → tap mascot on Progress → verify "$35.00 saved this month!"

**UX polish:**
11. Hover over mascot → verify cursor changes to pointer (suggests interactivity)
12. Verify tips fade smoothly when cycling (0.2s transition)
13. Verify tips wrap correctly if long (max 3 lines)

**Accessibility:**
14. Focus mascot with keyboard (Tab) → press Enter → verify tip cycles
15. Press Space while focused → verify tip cycles
16. Verify ARIA label "Tap for tips" is announced by screen reader

---

## Dependencies
- **350:** Zesto Phase 1 — Core triggers (mascot must already appear on pages)
- **360:** Zesto Phase 2 — Advanced animations (smooth transitions for tip cycling)

---

## Related issues
- **350:** Zesto Phase 1 — Core triggers (prerequisite)
- **360:** Zesto Phase 2 — Advanced animations (prerequisite)
- **375:** Zesto Phase 3 — Unlockable mascot characters (parallel feature)
- **380:** Zesto Phase 3 — Settings controls (parallel feature)

---

## Milestone placement: M5 (Advanced Features)
This is an **engagement enhancement** that makes Zesto more interactive and useful. While delightful, it's not required for launch—perfect for post-MVP iteration in M5.
