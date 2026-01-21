# 350: Zesto Phase 1 — Core Triggers (10 Events)

**Epic:** Mascot & Gamification  
**Milestone:** M3 (MVP Features)  
**Priority:** P1  
**Size:** L  
**Dependencies:** 090 (Flutter app skeleton), 340 (badge system)

---

## Context
Zesto the Avocado mascot currently appears on 3 pages (onboarding intro, inventory celebration, progress page load/badges tap) with basic messages. To make Zesto feel like a true companion, we need to expand his triggers to cover 10 core user events with educational, encouraging messages.

See full specification: `planning/docs/zesto-mascot-spec.md`

---

## Goal
Implement 10 core mascot triggers with 5-6 message variations each, anti-spam logic (5s minimum gap), message history tracking, and basic telemetry to measure engagement.

---

## Expected behavior

### 10 Core Triggers Implemented
1. **First item added** — Welcome message when user adds their very first inventory item
2. **Item consumed** — Celebration when user marks item as consumed (saved from waste)
3. **Item wasted** — Educational storage tip when item is wasted (not preachy, helpful)
4. **Quick save** — Special message when item consumed <24h before expiry
5. **Badge unlocked** — Celebration when user earns any badge
6. **Streak milestone** — Celebration at 5/10/30/100 day streaks
7. **Savings milestone** — Celebration when user saves $50/$100/$500
8. **Zero waste** — Celebration for 0% waste in week/month
9. **Daily welcome** — Greeting on first app open each day
10. **Expiry alert** — Reminder when 3+ items expiring within 24h

### Message Variety
- Each trigger has **5-6 message variations** to prevent repetition fatigue
- Messages pulled randomly from array per trigger type
- Mix of celebration, tips, and motivational language

### Anti-Spam Logic
- **5-second minimum gap** between mascot appearances (prevents spam)
- Tracks last message timestamp in localStorage
- If <5s since last message, queue is skipped (important alerts still tracked)

### Message History
- Tracks last **3 messages** shown to prevent immediate repeats
- If randomly selected message was one of last 3, re-roll once
- Ensures users see variety even with 5-6 message pool

### Telemetry
- `mascot_shown` event: messageType, page, timestamp
- `mascot_dismissed` event: auto vs manual dismiss, duration visible

---

## Acceptance criteria (Definition of Done)

### Code Implementation
- [ ] Create `data/storage_tips.json` with 20-30 storage tips (category → tip mappings)
- [ ] Expand `mascotMessages` object to include all 10 trigger types with 5-6 variations each
- [ ] Implement anti-spam logic: check localStorage for last message timestamp, skip if <5s
- [ ] Implement message history: track last 3 messages, re-roll if duplicate selected
- [ ] Add trigger logic for first item added (check if inventory is empty before add)
- [ ] Add trigger logic for item consumed (call `showMascot('consumed')` on consume action)
- [ ] Add trigger logic for item wasted (call `showMascot('wasted')` with storage tip from JSON)
- [ ] Add trigger logic for quick save (check if `daysUntilExpiry < 1` when consuming)
- [ ] Add trigger logic for badge unlocked (integrate with badge system, trigger on earn)
- [ ] Add trigger logic for streak milestone (check if streak == 5/10/30/100)
- [ ] Add trigger logic for savings milestone (check if totalSavings crosses $50/$100/$500)
- [ ] Add trigger logic for zero waste (calculate weekly/monthly waste %, trigger if 0%)
- [ ] Add trigger logic for daily welcome (check localStorage for lastOpenDate, once per day)
- [ ] Add trigger logic for expiry alert (count items with `daysUntilExpiry < 1`, trigger if ≥3)

### Data & Storage
- [ ] Create `storage_tips.json` with structure: `{ "category": ["Tip 1", "Tip 2", ...], ... }`
- [ ] Cover major categories: dairy, produce, meat, bread, leftovers, condiments
- [ ] Store `mascot_last_timestamp` in localStorage (Unix timestamp)
- [ ] Store `mascot_message_history` in localStorage (array of last 3 message strings)
- [ ] Store `mascot_unlocked_characters` in localStorage (array: default = `["avocado"]`)

### UI/UX
- [ ] Mascot appears correctly for all 10 triggers (visual test per trigger)
- [ ] Messages vary across repeated triggers (no "stuck message" bug)
- [ ] Anti-spam works: rapid events (5 items added in 2 seconds) only show 1 mascot
- [ ] Wasted item messages show helpful tips, not judgment ("💡 Tip: Store milk in back of fridge!")
- [ ] Messages feel encouraging and educational (not annoying or repetitive)

### Telemetry
- [ ] `mascot_shown` event fires with properties: `messageType`, `page`, `timestamp`
- [ ] `mascot_dismissed` event fires with properties: `dismissType` (auto/manual), `durationMs`
- [ ] Events logged to console (or telemetry service if implemented)

### Offline-First
- [ ] All mascot logic works offline (localStorage, local JSON file)
- [ ] No network dependencies for trigger detection or message display

### Accessibility
- [ ] Mascot messages have 3s minimum display (users can read)
- [ ] Speech bubbles have sufficient contrast (white bg, dark text)
- [ ] Mascot animations don't trigger motion sickness (gentle bounce only)

### Tests
- [ ] Unit test: Anti-spam logic prevents messages <5s apart
- [ ] Unit test: Message history prevents last 3 messages from repeating
- [ ] Unit test: First item trigger only fires on truly first item
- [ ] Unit test: Quick save logic detects items <24h from expiry
- [ ] Unit test: Expiry alert counts items correctly (≥3 items <24h)
- [ ] Widget test: Mascot appears and dismisses correctly
- [ ] Integration test: Trigger each of 10 events, verify mascot shown

---

## Out of scope
- Advanced animations (celebrate, shake, wave) — defer to M4 (issue 360)
- Storage tips as full database with images — defer to M4
- Recipe suggestions from expiring items — defer to M4
- Tap-to-cycle-tips interaction — defer to M5 (issue 370)
- Custom mascot selection (carrot, broccoli, bread) — defer to M5 (issue 375)
- Social triggers (challenge, friend, leaderboard) — defer to M5
- Settings controls (frequency, message types) — defer to M5 (issue 380)

---

## Implementation notes

### Storage Tips JSON Structure
```json
{
  "dairy": [
    "💡 Store milk in back of fridge (coldest spot)!",
    "💡 Cheese lasts longer wrapped in wax paper!",
    "💡 Freeze yogurt in ice cube trays for smoothies!"
  ],
  "produce": [
    "💡 Store tomatoes at room temperature!",
    "💡 Keep bananas separate (they ripen other fruit)!",
    "💡 Wash berries only before eating!"
  ],
  "meat": [
    "💡 Freeze meat within 2 days of purchase!",
    "💡 Thaw meat in fridge, not counter!",
    "💡 Store raw meat on bottom shelf!"
  ],
  "bread": [
    "💡 Freeze bread to extend life by weeks!",
    "💡 Store bread in cool, dry place!",
    "💡 Revive stale bread in oven (350°F, 5 min)!"
  ],
  "leftovers": [
    "💡 Cool leftovers before refrigerating!",
    "💡 Store in airtight containers!",
    "💡 Freeze extras within 3 days!"
  ],
  "condiments": [
    "💡 Store ketchup in fridge after opening!",
    "💡 Honey never spoils (no fridge needed)!",
    "💡 Hot sauce lasts months in fridge!"
  ]
}
```

### Anti-Spam Logic (Pseudocode)
```dart
void showMascot(String messageType) {
  final lastTimestamp = localStorage.getInt('mascot_last_timestamp') ?? 0;
  final now = DateTime.now().millisecondsSinceEpoch;
  
  // Check 5-second minimum gap
  if (now - lastTimestamp < 5000) {
    print('Mascot spam prevented: ${now - lastTimestamp}ms since last');
    return; // Skip this message
  }
  
  // Get message history (last 3)
  final history = localStorage.getStringList('mascot_message_history') ?? [];
  
  // Select random message from array
  final messages = mascotMessages[messageType];
  String selectedMessage = messages[Random().nextInt(messages.length)];
  
  // Re-roll if in last 3 messages
  if (history.contains(selectedMessage)) {
    selectedMessage = messages[Random().nextInt(messages.length)];
  }
  
  // Update history (keep last 3)
  history.add(selectedMessage);
  if (history.length > 3) history.removeAt(0);
  localStorage.setStringList('mascot_message_history', history);
  
  // Update timestamp
  localStorage.setInt('mascot_last_timestamp', now);
  
  // Show mascot with selected message
  _displayMascot(selectedMessage);
  
  // Telemetry
  logEvent('mascot_shown', {'messageType': messageType, 'page': currentPage});
}
```

### First Item Detection
```dart
Future<void> addItem(Item item) async {
  final inventory = await getInventory();
  final isFirstItem = inventory.isEmpty;
  
  await saveItem(item);
  
  if (isFirstItem) {
    showMascot('firstItem');
  }
}
```

### Quick Save Detection
```dart
void consumeItem(Item item) {
  final daysUntilExpiry = item.expiryDate.difference(DateTime.now()).inDays;
  
  if (daysUntilExpiry < 1) {
    showMascot('quickSave'); // Beat the clock!
  } else {
    showMascot('consumed'); // Regular save
  }
  
  markItemConsumed(item);
}
```

### Wasted Item with Storage Tip
```dart
void wasteItem(Item item) async {
  final tips = await loadStorageTips(); // Load JSON
  final categoryTips = tips[item.category] ?? tips['general'];
  final randomTip = categoryTips[Random().nextInt(categoryTips.length)];
  
  // Override message array temporarily with storage tip
  mascotMessages['wasted'] = [randomTip];
  showMascot('wasted');
  
  markItemWasted(item);
}
```

---

## Test plan

### Automated tests

**Unit tests (10 trigger logic tests):**
1. `test_first_item_trigger` — Add item to empty inventory, verify `showMascot('firstItem')` called
2. `test_consumed_trigger` — Consume item, verify `showMascot('consumed')` called
3. `test_wasted_trigger_with_tip` — Waste item, verify storage tip loaded from JSON and shown
4. `test_quick_save_trigger` — Consume item <24h from expiry, verify `showMascot('quickSave')` called
5. `test_badge_unlocked_trigger` — Earn badge, verify `showMascot('badgeUnlocked')` called
6. `test_streak_milestone_5_days` — Reach 5-day streak, verify `showMascot('streakMilestone')` called
7. `test_savings_milestone_50_dollars` — Cross $50 total savings, verify `showMascot('savingsMilestone')` called
8. `test_zero_waste_week` — Complete week with 0% waste, verify `showMascot('zeroWaste')` called
9. `test_daily_welcome_once_per_day` — Open app twice same day, verify mascot only shown once
10. `test_expiry_alert_3_items` — Add 3 items expiring <24h, verify `showMascot('expiryAlert')` called

**Unit tests (anti-spam & message history):**
11. `test_anti_spam_5_second_gap` — Trigger 2 events 2s apart, verify only 1 mascot shown
12. `test_message_history_no_repeats` — Trigger same event 4 times, verify all 4 messages different
13. `test_storage_tips_json_loads` — Verify JSON file loads correctly and returns tips for each category

**Widget tests:**
14. Widget test: Trigger `showMascot('consumed')`, verify mascot appears with message
15. Widget test: Wait 3 seconds, verify mascot auto-dismisses
16. Widget test: Tap outside mascot bubble, verify manual dismiss

**Integration tests:**
17. Integration test: Complete full flow (add item → consume → verify mascot appears with "Saved it!" message)
18. Integration test: Waste item → verify educational tip appears (not judgment)
19. Integration test: Earn badge → verify celebration mascot appears

### Manual testing

**Trigger verification (10 scenarios):**
1. Delete all data, add first item → verify "Welcome! 🎉" or similar appears
2. Mark item as consumed → verify "Saved it! 🎉" or similar appears
3. Mark item as wasted → verify storage tip appears (e.g., "💡 Tip: Store X in Y!")
4. Add item expiring tomorrow, consume it today → verify "Just in time! ⏰" appears
5. Earn badge (e.g., save 5 items) → verify "New badge! 🏆" appears
6. Maintain 5-day streak → verify "5 days strong! 🔥" appears
7. Save enough items to cross $50 → verify "$50 saved! 💰" appears
8. Complete week with 0 wasted items → verify "Perfect week! 🌟" appears
9. Open app first time today → verify "Good morning! ☀️" or similar appears
10. Add 3 items expiring today → verify "3 items expiring! ⏰" appears

**Anti-spam & variety:**
11. Add 5 items rapidly → verify only 1 mascot appears (anti-spam works)
12. Consume 10 items over 60 seconds → verify different messages appear (variety works)
13. Waste 5 different categories of items → verify different storage tips appear

**UX polish:**
14. Verify all messages feel encouraging, not annoying
15. Verify wasted item tips are helpful, not judgmental
16. Verify mascot animations are smooth (no jank)
17. Verify mascot doesn't block critical UI elements

---

## Dependencies
- **090:** Flutter app skeleton with routing, theming, DI (mascot needs app structure)
- **340:** Badge system implementation (for `badgeUnlocked` trigger)
- **Data model:** Item with category, expiry date, consumed/wasted status

---

## Related issues
- **360:** Zesto Phase 2 — Advanced animations (celebrate, shake, wave)
- **370:** Zesto Phase 3 — Tap-to-cycle-tips interaction
- **375:** Zesto Phase 3 — Unlockable mascot characters (carrot, broccoli, bread)
- **380:** Zesto Phase 3 — Settings controls (frequency, message types, enable/disable)
- **340:** Badge system implementation (dependency for badgeUnlocked trigger)

---

## Milestone placement: M3 (MVP Features)
This is a **core engagement feature** that makes the app feel alive and supportive. While not strictly required for MVP, it significantly enhances user motivation and retention, making it a strong M3 candidate alongside other gamification features (badges, progress tracking).
