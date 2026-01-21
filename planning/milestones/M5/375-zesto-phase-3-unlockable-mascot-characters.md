# 375: Zesto Phase 3 — Unlockable Mascot Characters

**Epic:** Mascot & Gamification  
**Milestone:** M5 (Advanced Features)  
**Priority:** P2  
**Size:** M  
**Dependencies:** 350 (Zesto Phase 1), data model (item categories, consumption tracking)

---

## Context
Zesto the Avocado is the default mascot, but users should be able to **unlock new mascot characters** based on their saving behavior. This adds a collection/achievement element to gamification and lets users personalize their experience.

Unlocking is **free but achievement-based** (e.g., save 50 carrots to unlock Carrot mascot), not paywalled.

See full specification: `planning/docs/zesto-mascot-spec.md` (Section 7: Settings Integration, Section 3.3: Customization)

---

## Goal
Implement 3 unlockable mascot characters (🥕 Carrot, 🥦 Broccoli, 🍞 Bread) with clear unlock conditions, a mascot selection UI in Settings, and persistence of unlocked characters + active selection.

---

## Expected behavior

### 4 Mascot Characters
| Character | Emoji | Unlock Condition | Status at Launch |
|-----------|-------|------------------|------------------|
| **Zesto the Avocado** | 🥑 | Default (always unlocked) | ✅ Unlocked |
| **Carrie the Carrot** | 🥕 | Save 50 carrots (produce category) | 🔒 Locked |
| **Broc the Broccoli** | 🥦 | Save 50 vegetables (produce category) | 🔒 Locked |
| **Betty the Bread** | 🍞 | Save 50 grains (bread/grain category) | 🔒 Locked |

### Unlock Flow
1. User saves items in specific category (e.g., carrots)
2. App tracks consumption by category in localStorage: `mascot_unlock_progress`
3. When user crosses threshold (50 items), unlock notification appears:
   - Badge-style popup: "🎉 New Mascot Unlocked!"
   - Shows new character emoji + name
   - "Tap to select" CTA
4. User can now select that mascot in Settings → App Preferences → Mascot
5. Selected mascot appears in all future mascot interactions (replace 🥑 with 🥕/🥦/🍞)

### Settings UI (Mascot Selection)
**Settings → App Preferences → 🥑 Mascot (Customize)**

```
Choose Your Mascot

[🥑] Zesto the Avocado
    ✓ Selected • Always unlocked
    
[🥕] Carrie the Carrot
    🔒 Save 50 carrots to unlock (23/50)
    Progress bar: [########........] 46%
    
[🥦] Broc the Broccoli
    🔒 Save 50 vegetables to unlock (8/50)
    Progress bar: [##..............] 16%
    
[🍞] Betty the Bread
    🔒 Save 50 grains to unlock (0/50)
    Progress bar: [................] 0%
```

### Persistence
- **Unlocked mascots:** Stored in localStorage as `mascot_unlocked: ["avocado", "carrot"]`
- **Active selection:** Stored in localStorage as `mascot_active: "carrot"`
- On app load, read `mascot_active` and display that character in all mascot interactions

---

## Acceptance criteria (Definition of Done)

### Code Implementation
- [ ] Create `mascot_unlock_progress` localStorage object: `{ "produce": 23, "grain": 0, "dairy": 15, ... }`
- [ ] Increment category count when item consumed (not wasted)
- [ ] Check unlock thresholds (50 items) on every consumption
- [ ] Trigger unlock notification when threshold crossed: `showMascotUnlock('carrot')`
- [ ] Create `mascot_unlocked` localStorage array: default `["avocado"]`
- [ ] Add newly unlocked character to array: `["avocado", "carrot"]`
- [ ] Create `mascot_active` localStorage string: default `"avocado"`
- [ ] Update `showMascot()` to display active mascot emoji (not hardcoded 🥑)

### Settings UI
- [ ] Create "Mascot (Customize)" section in Settings → App Preferences
- [ ] Display all 4 mascot cards with emoji, name, unlock status
- [ ] Show "✓ Selected" for active mascot
- [ ] Show "🔒 Locked" + progress for unulocked mascots (e.g., "23/50" + 46% bar)
- [ ] Show "✓ Unlocked" + "Tap to select" for unlocked but not active mascots
- [ ] Tapping unlocked mascot card updates `mascot_active` and refreshes UI

### Unlock Notification UI
- [ ] Create `.mascot-unlock-popup` modal overlay (full screen, dark overlay)
- [ ] Large emoji display (80px)
- [ ] "🎉 New Mascot Unlocked!" heading
- [ ] Character name + flavor text (e.g., "Carrie the Carrot - The veggie champion!")
- [ ] "Use Now" button (sets as active) + "Maybe Later" button (just unlocks)
- [ ] Popup appears immediately after unlock condition met

### Data & Tracking
- [ ] Map item categories to mascot unlock types:
  - `produce` → carrot, broccoli (split: carrots specifically → carrot, other veggies → broccoli)
  - `grain` → bread
  - Default: avocado (already unlocked)
- [ ] Track consumption by category (increment on consume, not add)
- [ ] Persist unlock progress across app restarts (localStorage)

### Telemetry
- [ ] `mascot_unlocked` event: character name, items saved to unlock, category
- [ ] `mascot_selected` event: character name, previous character
- [ ] `mascot_unlock_progress_viewed` event: page view on Settings → Mascot

### UI/UX
- [ ] Active mascot displays correctly on all pages (inventory, progress, etc.)
- [ ] Unlock notification feels celebratory (confetti burst optional)
- [ ] Progress bars in Settings update in real-time (if user consumes items, then opens Settings)
- [ ] Locked mascots show clear progress toward unlock (motivates collection)

### Accessibility
- [ ] Mascot cards in Settings are keyboard navigable
- [ ] "Use Now" button in unlock popup is keyboard accessible (Enter/Space)
- [ ] Screen readers announce unlock status ("Locked, 23 of 50 carrots saved")

### Tests
- [ ] Unit test: Consume 50 carrots → verify `mascot_unlock_progress.produce` increments to 50
- [ ] Unit test: Unlock carrot mascot → verify `mascot_unlocked` includes "carrot"
- [ ] Unit test: Select carrot mascot → verify `mascot_active` updates to "carrot"
- [ ] Widget test: Display mascot after selecting carrot → verify 🥕 appears (not 🥑)
- [ ] Widget test: Unlock notification appears when threshold crossed
- [ ] Widget test: Tap "Use Now" in unlock popup → verify mascot switches immediately
- [ ] Integration test: Save 50 carrots → unlock carrot → select carrot → verify appears on inventory page

---

## Out of scope
- More than 4 mascots at launch (can add more in M6+: 🍎 apple, 🧀 cheese, 🥩 steak, etc.)
- Animated mascots (different poses, expressions) — defer to M6+
- Mascot rarities (common, rare, legendary) — defer to M6+
- Seasonal/limited-time mascots — defer to M6+
- User-created mascots — defer to M6+
- Mascot trading/sharing — defer to M6+

---

## Implementation notes

### Category Mapping
```dart
Map<String, String> categoryToMascot = {
  'carrot': 'carrot',        // Specific subcategory
  'broccoli': 'broccoli',    // Specific subcategory
  'produce': 'broccoli',     // General produce → broccoli (if not carrot)
  'grain': 'bread',          // Grains → bread
  'bread': 'bread',          // Specific subcategory
  // Default: no mascot unlock (avocado is always unlocked)
};

Map<String, int> unlockThresholds = {
  'carrot': 50,
  'broccoli': 50,
  'bread': 50,
};
```

### Consumption Tracking
```dart
void consumeItem(Item item) {
  // ... (existing consume logic)
  
  // Track category consumption for mascot unlocks
  final progress = localStorage.getMap('mascot_unlock_progress') ?? {};
  final category = item.category.toLowerCase();
  progress[category] = (progress[category] ?? 0) + 1;
  localStorage.setMap('mascot_unlock_progress', progress);
  
  // Check if unlock threshold crossed
  checkMascotUnlocks(category, progress[category]);
}

void checkMascotUnlocks(String category, int count) {
  final mascotType = categoryToMascot[category];
  if (mascotType == null) return; // No mascot for this category
  
  final threshold = unlockThresholds[mascotType] ?? 50;
  if (count < threshold) return; // Not yet unlocked
  
  // Check if already unlocked
  final unlockedMascots = localStorage.getStringList('mascot_unlocked') ?? ['avocado'];
  if (unlockedMascots.contains(mascotType)) return; // Already unlocked
  
  // UNLOCK!
  unlockedMascots.add(mascotType);
  localStorage.setStringList('mascot_unlocked', unlockedMascots);
  
  // Show unlock popup
  showMascotUnlock(mascotType);
  
  // Telemetry
  logEvent('mascot_unlocked', {
    'character': mascotType,
    'itemsSaved': count,
    'category': category,
  });
}
```

### Unlock Notification Popup (HTML)
```html
<div class="mascot-unlock-popup" id="mascotUnlockPopup">
  <div class="mascot-unlock-modal">
    <div class="mascot-unlock-emoji" id="unlockEmoji">🥕</div>
    <h2 class="mascot-unlock-heading">🎉 New Mascot Unlocked!</h2>
    <div class="mascot-unlock-name" id="unlockName">Carrie the Carrot</div>
    <div class="mascot-unlock-flavor" id="unlockFlavor">The veggie champion!</div>
    
    <div class="mascot-unlock-actions">
      <button class="btn-primary" onclick="selectUnlockedMascot()">
        Use Now
      </button>
      <button class="btn-secondary" onclick="closeUnlockPopup()">
        Maybe Later
      </button>
    </div>
  </div>
</div>
```

### Settings Mascot Section (HTML)
```html
<div class="accordion-section">
  <div class="accordion-header" onclick="toggleAccordion(this)">
    <div>
      <div class="setting-label">🥑 Mascot (Customize)</div>
      <div class="setting-description">Unlock new mascots by saving items</div>
    </div>
    <span class="accordion-chevron">›</span>
  </div>
  
  <div class="accordion-body">
    <div class="mascot-grid">
      <!-- Avocado (always unlocked) -->
      <div class="mascot-card active" data-mascot="avocado">
        <div class="mascot-card-emoji">🥑</div>
        <div class="mascot-card-name">Zesto the Avocado</div>
        <div class="mascot-card-status unlocked">✓ Selected</div>
      </div>
      
      <!-- Carrot (example: 23/50 progress) -->
      <div class="mascot-card locked" data-mascot="carrot" data-progress="23" data-threshold="50">
        <div class="mascot-card-emoji grayscale">🥕</div>
        <div class="mascot-card-name">Carrie the Carrot</div>
        <div class="mascot-card-status locked">
          🔒 Save 50 carrots to unlock (23/50)
        </div>
        <div class="mascot-card-progress">
          <div class="progress-bar">
            <div class="progress-fill" style="width: 46%;"></div>
          </div>
        </div>
      </div>
      
      <!-- Broccoli -->
      <div class="mascot-card locked" data-mascot="broccoli" data-progress="8" data-threshold="50">
        <div class="mascot-card-emoji grayscale">🥦</div>
        <div class="mascot-card-name">Broc the Broccoli</div>
        <div class="mascot-card-status locked">
          🔒 Save 50 vegetables to unlock (8/50)
        </div>
        <div class="mascot-card-progress">
          <div class="progress-bar">
            <div class="progress-fill" style="width: 16%;"></div>
          </div>
        </div>
      </div>
      
      <!-- Bread -->
      <div class="mascot-card locked" data-mascot="bread" data-progress="0" data-threshold="50">
        <div class="mascot-card-emoji grayscale">🍞</div>
        <div class="mascot-card-name">Betty the Bread</div>
        <div class="mascot-card-status locked">
          🔒 Save 50 grains to unlock (0/50)
        </div>
        <div class="mascot-card-progress">
          <div class="progress-bar">
            <div class="progress-fill" style="width: 0%;"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
```

### CSS for Mascot Cards
```css
.mascot-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
  padding: 16px 0;
}

.mascot-card {
  background: white;
  border: 2px solid #e9ecef;
  border-radius: 12px;
  padding: 16px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
}

.mascot-card.active {
  border-color: #2f9e44;
  background: #f8f9fa;
}

.mascot-card.locked {
  opacity: 0.7;
  cursor: not-allowed;
}

.mascot-card-emoji {
  font-size: 48px;
  margin-bottom: 8px;
}

.mascot-card-emoji.grayscale {
  filter: grayscale(100%);
  opacity: 0.5;
}

.mascot-card-name {
  font-weight: 600;
  font-size: 14px;
  color: #333;
  margin-bottom: 4px;
}

.mascot-card-status {
  font-size: 12px;
  color: #666;
}

.mascot-card-status.unlocked {
  color: #2f9e44;
  font-weight: 600;
}

.mascot-card-progress {
  margin-top: 8px;
}

.progress-bar {
  height: 6px;
  background: #e9ecef;
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #2f9e44, #51cf66);
  transition: width 0.3s ease;
}
```

---

## Test plan

### Automated tests

**Unit tests (unlock logic):**
1. Unit test: Consume 49 carrots → verify carrot mascot NOT unlocked
2. Unit test: Consume 50th carrot → verify carrot mascot unlocked (`mascot_unlocked` includes "carrot")
3. Unit test: Consume 51st carrot → verify unlock popup doesn't show again (already unlocked)
4. Unit test: Consume 50 grains → verify bread mascot unlocked

**Widget tests (UI):**
5. Widget test: Display Settings → Mascot section → verify 4 mascot cards shown
6. Widget test: Locked mascot shows progress bar (23/50 = 46% filled)
7. Widget test: Tap unlocked mascot card → verify `mascot_active` updates
8. Widget test: Unlock popup appears when threshold crossed
9. Widget test: Tap "Use Now" → verify mascot switches immediately

**Integration tests:**
10. Integration test: Save 50 carrots → verify unlock notification → tap "Use Now" → verify 🥕 appears on inventory page
11. Integration test: Unlock carrot → navigate to Settings → verify carrot card shows "✓ Unlocked"

**Telemetry tests:**
12. Unit test: Unlock mascot → verify `mascot_unlocked` event fires
13. Unit test: Select mascot → verify `mascot_selected` event fires

### Manual testing

**Unlock flow:**
1. Start fresh (delete localStorage) → consume 50 carrots → verify unlock popup appears
2. Tap "Use Now" → verify 🥕 appears immediately on inventory page
3. Tap "Maybe Later" → verify carrot still unlocked but avocado remains active
4. Navigate to Settings → Mascot → tap carrot card → verify switches to 🥕

**Progress tracking:**
5. Consume 10 carrots → open Settings → Mascot → verify progress bar shows 10/50 (20%)
6. Consume 10 more carrots → refresh Settings → verify progress bar updates to 20/50 (40%)
7. Consume 30 more carrots → verify unlock popup appears immediately

**Multiple mascots:**
8. Unlock carrot → unlock bread → verify both show as "✓ Unlocked" in Settings
9. Switch between carrot and bread → verify active mascot updates correctly
10. Verify only 1 mascot can be active at a time (radio button behavior)

**Visual verification:**
11. Select carrot mascot → navigate to all pages (inventory, progress, expiring-soon) → verify 🥕 appears everywhere
12. Verify locked mascots show grayscale emoji in Settings (not full color)
13. Verify active mascot card has green border in Settings

**Edge cases:**
14. Unlock mascot while mascot is visible on screen → verify popup doesn't break active mascot
15. Unlock mascot, close app, reopen → verify mascot remains unlocked (persisted)
16. Switch mascot mid-session → verify new mascot appears on next trigger (not cached)

---

## Dependencies
- **350:** Zesto Phase 1 — Core triggers (mascot must appear on pages)
- Data model: Item with category field (to track consumption by category)

---

## Related issues
- **350:** Zesto Phase 1 — Core triggers (prerequisite)
- **370:** Zesto Phase 3 — Tap-to-cycle tips (parallel feature)
- **380:** Zesto Phase 3 — Settings controls (prerequisite for Settings UI)

---

## Milestone placement: M5 (Advanced Features)
This is a **collection/achievement feature** that enhances engagement and personalization. Not required for launch, but adds significant delight factor for post-MVP iteration in M5.
