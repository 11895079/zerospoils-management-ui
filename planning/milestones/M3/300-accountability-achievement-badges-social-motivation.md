# M3-300: Accountability & Achievement Badges — Social Motivation Loop

**Status:** Planning  
**Milestone:** M3 (MVP Features)  
**Priority:** P2 (Enhancement)  
**Effort:** M (Medium)  
**Labels:** `social`, `gamification`, `mvp-nice-to-have`

## Context

Users reduce waste better when they feel progress and social accountability. Badges (No Waste Week, Used Before Expiry, Cooked from Pantry) provide:
- **Motivation:** Visible progress and achievement milestones
- **Shareable proof:** Badges can be shown to friends without exposing personal data (privacy-first)
- **Habit formation:** Weekly streaks encourage consistent behavior

Badges are **not** tied to Pro tier — they're local, shareable achievements available to all users.

## Goal

Implement a local achievement badge system that:
- Awards badges for consistent waste reduction behaviors
- Tracks streaks (consecutive days/weeks without waste)
- Allows sharing badges (as image or text) without exposing underlying data
- Motivates continued use and habit formation

## Expected Behavior

### Badge Types (Local)

1. **🏆 No Waste Week**
   - Trigger: 7 consecutive days with 0% waste
   - Shown when streak ends (user sees "Week Streak!" badge)
   - Shareable: "I achieved No Waste Week! 🏆 7 days without wasting food."

2. **✓ Used Before Expiry**
   - Trigger: 5+ items consumed before expiry in past 30 days
   - Shown on Progress tab
   - Shareable: "I used 5+ items before they expired! ✓"

3. **🍳 Cooked from Pantry**
   - Trigger: Mark 3+ "prepared" items as consumed in past 30 days
   - Indication: User is leveraging what they have (meal planning)
   - Shareable: "I cooked 3 meals from pantry staples! 🍳"

4. **💰 Savings Milestone**
   - Trigger: Every $50 saved (locallycomputed: (items wasted cost × prevention rate))
   - Examples: $50 saved, $100 saved, $250 saved, etc.
   - Shareable: "I've saved $100 by reducing waste! 💰"

5. **🌍 Environmental Impact**
   - Trigger: Every 5 kg CO₂ avoided
   - Examples: 5 kg, 10 kg, 25 kg
   - Shareable: "I've avoided 10 kg CO₂! 🌍"

### Badge Display

- **Progress Tab:** Show earned badges in a "Achievements" section
- **Notification:** Toast when badge earned ("🏆 No Waste Week badge earned!")
- **Share Card:** Include in social sharing (already designed in progress.html prototype)

### Sharing (Local, No Data)

Badges appear as shareable cards with:
- Badge emoji + name
- Short motivation text ("7 days without wasting food")
- **No personal data** (no item names, expiry dates, or inventory visible)

Sharing methods:
- Copy text: "I achieved No Waste Week! 🏆 7 days without wasting food."
- Share image: Generate simple badge card (emoji, text, date)
- Link: (deferred to M4/M5) — public badge page

## Acceptance Criteria

- [ ] **Badge Logic:** All 5 badge types trigger correctly based on local data
- [ ] **Streak Tracking:** "No Waste Week" tracks consecutive days accurately (reset if any waste recorded)
- [ ] **UI:** Badges displayed on Progress tab with earned/not-earned states
- [ ] **Sharing:** Badges can be shared as text (copy-to-clipboard) and as image (HTML canvas render)
- [ ] **Privacy:** No personal inventory data included in share (only badge name + emoji)
- [ ] **Analytics:** Track badge earn events (badge_earned, badge_type, timestamp)
- [ ] **Tests:** Unit tests verify badge trigger logic; widget tests verify UI rendering
- [ ] **Accessibility:** Badge descriptions available to screen readers

## Out of Scope

- Leaderboards (deferred to M4/M5)
- Household badge challenges (deferred to M6, requires multi-device sync)
- Badge customization/trading (future enhancement)
- Achievement notifications to friends (deferred to M6, requires friend system)

## Implementation Notes

### Badge Trigger Logic

```dart
// Example: No Waste Week
class BadgeService {
  Future<bool> checkNoWasteWeekBadge(Repository repo) async {
    final last7Days = DateTime.now().subtract(Duration(days: 7));
    final wastedItems = await repo.getWastedItems(after: last7Days);
    return wastedItems.isEmpty; // No waste in past 7 days
  }

  Future<void> checkAllBadges(Repository repo) async {
    final badgesEarned = <Badge>[];
    
    if (await checkNoWasteWeekBadge(repo)) {
      badgesEarned.add(Badge.noWasteWeek());
    }
    if (await checkUsedBeforeExpiryBadge(repo)) {
      badgesEarned.add(Badge.usedBeforeExpiry());
    }
    // ... check others
    
    // Save earned badges + emit notification for each new one
    for (final badge in badgesEarned) {
      await repo.saveEarnedBadge(badge);
      _notifyBadgeEarned(badge);
    }
  }
}
```

### Sharing Implementation

**Text:** Generate motivational string
```dart
String getShareText(Badge badge) => switch(badge.type) {
  BadgeType.noWasteWeek => 
    '🏆 I achieved No Waste Week! 7 days without wasting food.',
  BadgeType.usedBeforeExpiry => 
    '✓ I used 5+ items before they expired!',
  // ...
};
```

**Image:** Use `screenshot` or `html_canvas` package to render badge card
```dart
// Render: emoji, badge name, earned date, "ZeroSpoils" watermark
```

### Data Model

```dart
class Badge {
  final String id;           // 'no-waste-week', 'used-before-expiry', etc.
  final String emoji;        // '🏆', '✓', '🍳', etc.
  final String name;         // "No Waste Week"
  final String description;  // "7 days without wasting food"
  final DateTime? earnedAt;  // Null if not yet earned
  final DateTime? earnedDate; // Date earned (for display)
}
```

### Badge State (Local DB)

Store in Hive/sqflite:
```
badges_earned = [
  {
    id: 'no-waste-week',
    earnedAt: '2026-01-20T15:30:00Z',
    shareCount: 2,
  },
  ...
]
```

## Test Plan

**Automated:**
- Unit test: Badge trigger logic (no waste in past 7 days → triggers)
- Unit test: Streak reset (if waste recorded, streak resets)
- Widget test: Badge display on Progress tab (shows earned/not-earned states)
- Widget test: Share buttons generate correct text
- Integration test: Full flow (consume items, badge earned, see on tab, share)

**Manual:**
1. Clear all items, wait 7 days (simulate via time mock)
2. Record 7 days of consumption with 0 waste
3. Verify "No Waste Week" badge appears on Progress tab
4. Tap share button, verify toast shows badge text
5. Record 1 wasted item on day 8 — verify streak resets
6. Test all 5 badge types via the above flow
7. Verify badge descriptions read correctly with TalkBack/VoiceOver

## Dependencies

- **Data Model** (Issue 080): Waste reason tracking, consumed/wasted flags required
- **Progress Tab** (Issue 060 prototype): UI in place to display badges
- **Local DB** (Issue 090): Hive/sqflite setup for storing earned badges

## Related Issues

- **Issue 060:** Progress dashboard (displays badges)
- **Issue 080:** Data model (consumed/wasted tracking)
- **Issue 310:** Household achievement challenges (M4, builds on this)
- **Issue 320:** Social sharing framework (M4, shared infrastructure for badge + other shares)

---

**Success:** Users see badges motivating them to reduce waste; badges are shareable and privacy-respecting (no personal data exposed).
