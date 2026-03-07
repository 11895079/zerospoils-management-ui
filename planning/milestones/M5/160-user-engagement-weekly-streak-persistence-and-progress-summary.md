# 160: User Engagement — Weekly Streak Persistence & Progress Summary

**Epic:** Gamification & Habit Formation  
**Milestone:** M5 (Public Launch)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 040 (telemetry — daily active user events), 300 (Progress/Metrics screen)

---

## Context

Habit-forming apps (Duolingo, Strava, Headspace) drive engagement via **visible streaks** and **weekly progress summaries**. These create psychological commitment ("I don't want to break my streak") and dopamine hits (celebration of wins).

**Current State:** ZeroSpoils tracks items saved/wasted but has no visible streak counter or weekly comparison. Users don't see progress feedback.

**Opportunity:** Add streak persistence on home screen and weekly summary cards to drive DAU (daily active users) and retention.

---

## Goal

Implement **streak tracking** (consecutive days with app engagement) and **weekly progress summaries** (items saved this week vs last week) to increase daily logins and habit formation.

---

## Expected behavior

### Streak Tracking

**Definition:** "Active Day" = any app session with ≥1 meaningful action:
- Item added to inventory
- Item marked as used/wasted
- Item moved to shopping list
- Reminder opened in notification

**Streak Logic:**
- First action of the day → increment streak by 1
- Day with no activity → streak resets to 0 (next action starts new streak at 1)
- Track streak count + last_active_date in persistent storage

**Home Screen Display:**

```
┌─────────────────────────────────┐
│       ZeroSpoils Home           │
├─────────────────────────────────┤
│                                 │
│  🔥 14-Day Streak!              │
│  You're on fire! Keep it up.    │
│                                 │
│  Next streak milestone: 30 days │
│  ████████████░░░░░░ 47%         │
│                                 │
├─────────────────────────────────┤
│  [Inventory]  [Shopping]  ...   │
```

**Streak Card Details:**
- Emoji: 🔥 (emphasize achievement)
- Streak counter: "X-Day Streak"
- Motivational message (rotates):
  - "You're on fire! Keep it up."
  - "X days strong! 💪"
  - "Unstoppable streak!"
  - "Legend in the making! 🏆"
- Next milestone indicator: "Next streak milestone: 30 days"
- Progress bar to next milestone (7-day → 14-day → 30-day → 100-day)

**Streak Milestones:**
- 🟢 7 days: "One Week Champion"
- 🟠 14 days: "Fortnight Master"
- 🔴 30 days: "Monthly Legend"
- 🌟 100 days: "Century Club"

### Weekly Progress Summary

**Progress/Metrics Screen — New "This Week" Card:**

```
┌─────────────────────────────────┐
│  📊 This Week's Impact          │
├─────────────────────────────────┤
│                                 │
│  You saved 23 items             │
│  ↑ 20% from last week (19)      │
│                                 │
│  Waste prevented: $47           │
│  ↑ 15% from last week ($41)     │
│                                 │
│  Most saved category:           │
│  🥕 Produce (12 items)          │
│                                 │
├─────────────────────────────────┤
│  [Week View]  [Month View]      │
└─────────────────────────────────┘
```

**Summary Metrics (Weekly Comparison):**
- Items saved this week vs last week (count + % change)
- Estimated waste value prevented (calculated from item prices, if available; else estimate)
- Most-saved category (category with most items saved)
- Day-of-week breakdown (which days most active)
- Consistency indicator: "X days active this week" (out of 7)

**Trend Indicators:**
- Green ↑ if this week > last week (growth)
- Red ↓ if this week < last week (decline)
- Gray → if equal

### Visual Design

**Streak Card (Home Screen):**
- Large emoji (🔥) for immediate recognition
- Centered, prominent placement (above Inventory/Shopping tabs)
- Tap to open "Streak Achievements" modal (optional; shows all milestones)

**Progress Summary (Metrics Screen):**
- Card-based layout (consistent with Settings cards)
- Icons for each metric (item count, money saved, category)
- Sparkle effect (✨) on % increase for positive feedback
- Week/Month/All-Time tabs for time period selection

### Settings Control

**Settings → Notifications & Alerts:**
```
☑ Streak Reminders
  (Get a reminder if you miss a day to keep your streak)
  
☑ Weekly Progress Summary
  (Show weekly comparison on Metrics screen)
```

---

## Acceptance criteria (Definition of Done)

### Data Model & Persistence
- [ ] Add `user_streak` table to local DB (Hive/sqflite):
  ```
  {
    streak_count (int),             // current streak days
    last_active_date (DateTime),    // date of last action
    best_streak_count (int),        // all-time best
    best_streak_date_range (string),// "Mar 1 - Mar 14, 2026"
    created_at (DateTime),
    updated_at (DateTime),
  }
  ```
- [ ] Add `weekly_stats` table:
  ```
  {
    week_start_date (DateTime),          // Monday of week
    items_saved_count (int),
    items_wasted_count (int),
    waste_value_prevented (double),      // estimated USD
    most_saved_category (string),
    active_days_count (int),             // days with activity
  }
  ```
- [ ] Persist user_streak + weekly_stats across app restarts
- [ ] Initialize streak = 0, last_active_date = null on first app launch

### Streak Tracking Logic
- [ ] Define "active day" as any action:
  - `inventory_item_added`
  - `inventory_item_used` or `inventory_item_wasted`
  - `shopping_list_item_added`
  - `notification_opened` (for reminder-driven actions)
- [ ] On app start, check if today's date > last_active_date:
  - If yes and no prior session today → increment streak by 1 (if last_active_date = yesterday)
  - If yes and last_active_date < yesterday → reset streak to 0
  - If no (same day as last_active_date) → no change
- [ ] Update last_active_date = today on first action of the day
- [ ] Track best_streak_count (all-time high)
- [ ] Tests:
  - Unit test: Streak increment on consecutive days
  - Unit test: Streak reset on skipped day
  - Unit test: Same-day activity (no re-increment)
  - Unit test: Milestone thresholds (7, 14, 30, 100 days)

### Weekly Stats Aggregation
- [ ] Compute weekly stats from consumption events:
  - `items_saved`: count of items marked "used" (week_start ≤ consumed_date < week_start + 7days)
  - `items_wasted`: count of items marked "wasted" (same date range)
  - `waste_value_prevented`: sum of (item_quantity × estimated_unit_price) for used items
    - Fallback: use category-based price estimates (e.g., produce = $2/unit, dairy = $3/unit)
  - `most_saved_category`: category with highest count of saved items
  - `active_days_count`: count of unique dates with ≥1 action in week
- [ ] Recompute weekly stats on app start (or every 5 min)
- [ ] Store rolling 12-week history (delete older weeks to save DB space)
- [ ] Comparison logic:
  - this_week_count vs last_week_count → calculate % change
  - trend_direction = (this_week > last_week) ? "up" : (this_week < last_week) ? "down" : "equal"
- [ ] Tests:
  - Unit test: Weekly aggregation (items saved, wasted, value)
  - Unit test: Percentage change calculation
  - Unit test: Category grouping (highest count)
  - Unit test: Active days count

### UI/UX Implementation

**Home Screen Streak Card:**
- [ ] Create `StreakCard` widget
- [ ] Display on `home_screen.dart` above inventory/shopping tabs
- [ ] Render:
  - Large emoji (🔥)
  - "X-Day Streak" text
  - Motivational message (rotated from list)
  - Next milestone label + progress bar
- [ ] Tap to open `StreakAchievements` modal (shows milestones + badges)
- [ ] Hidden if streak = 0 (no ongoing streak yet)
- [ ] Tests:
  - Widget test: Render streak card with 14-day streak
  - Widget test: Tap to open achievements modal
  - Widget test: Hidden when streak = 0

**Progress Screen Weekly Summary:**
- [ ] Create `WeeklySummaryCard` widget
- [ ] Add to `progress_screen.dart` (new card or section)
- [ ] Render tabs: [This Week] [This Month] [All Time]
- [ ] For each tab, display:
  - Items saved (this period vs previous period)
  - Waste value prevented
  - Most saved category
  - Active days count (if weekly view)
  - Trend indicators (✨ if up, ↓ if down)
- [ ] Chart option (optional): sparkline chart showing daily activity
- [ ] Tests:
  - Widget test: Render weekly summary with data
  - Widget test: Tab switching (week/month/all-time)
  - Widget test: Trend indicators (up/down/equal)

**Streak Achievements Modal:**
- [ ] Modal showing all milestone badges:
  ```
  🟢 7 Days: One Week Champion (UNLOCKED)
  🟠 14 Days: Fortnight Master (UNLOCKED)
  🔴 30 Days: Monthly Legend (0/30) [14 days to go]
  🌟 100 Days: Century Club (0/100) [86 days to go]
  ```
- [ ] Tap locked milestone to show unlock progress
- [ ] Celebrate unlock with animation + confetti (optional)

### Telemetry
- [ ] `streak_updated` event:
  - Properties: `streak_count`, `action_type` (item_added/item_used/item_wasted), `streak_milestone_unlocked` (bool)
- [ ] `streak_reset` event:
  - Properties: `prior_streak_count`, `reason` (skipped_day / user_reset)
- [ ] `weekly_summary_viewed` event:
  - Properties: `items_saved_this_week`, `trend_direction`, `most_saved_category`
- [ ] `achievement_unlocked` event:
  - Properties: `milestone_days` (7/14/30/100), `total_achievement_count`

### Accessibility
- [ ] Streak card has semantic label: "X-day streak, flame emoji"
- [ ] Progress bar has ARIA attributes: `aria-valuenow`, `aria-valuemax`, `aria-label="X of Y days"`
- [ ] Tap targets ≥44pt
- [ ] Milestone badges have alt text

### Persistence & Sync
- [ ] Streak + weekly stats persisted locally (survives app restart)
- [ ] No cloud sync for MVP (free tier, offline-first)
- [ ] Pro tier (M6): optional sync + cross-device streak persistence

### Tests

**Automated Tests (Unit):**

- Streak increment:
  - Session 1 (Day 1): streak = 1
  - Session 2 (Day 2, next day): streak = 2
  - Session 3 (Day 3, same day): streak = 2 (no duplicate)

- Streak reset:
  - Session 1-3 (Days 1–3): streak = 3
  - Pause (Day 4: no activity)
  - Session 4 (Day 5): streak = 1 (reset, new streak starts)

- Weekly stats:
  - Items saved: 23 (count of consumed events Mon–Sun)
  - Waste prevented: $47 (sum of estimated prices)
  - Most saved category: "Produce" (12 items)
  - Active days: 5 (out of 7)

- Percentage change:
  - This week: 23 items, Last week: 19 items
  - Change: +4 items, +21% ✓

- Milestone detection:
  - Streak 7 → "One Week Champion" badge unlocked
  - Streak 14 → "Fortnight Master" badge unlocked
  - Streak 30 → "Monthly Legend" badge unlocked
  - Streak 100 → "Century Club" badge unlocked

**Widget Tests (UI):**

- Render streak card with 14-day streak + motivational message
- Render progress summary with weekly data + trend indicators
- Tap achievement modal → shows milestones
- Tab switching in progress summary (week/month/all-time)
- Tap milestone card → shows unlock progress

**Integration Tests:**

- Mark item as used (Inventory) → active_days_count increases, weekly_stats updated
- Day boundary crossing (11pm → 1am) → streak increments correctly
- Multiple actions same day → no duplicate streaks

**Manual Smoke Tests:**

1. **Scenario: Build Streak**
   - Day 1: Add item to inventory → streak = 1, "🔥 1-Day Streak!"
   - Day 2: Mark item as used → streak = 2, "🔥 2-Day Streak!"
   - Day 3: Open shopping list → streak = 3, "🔥 3-Day Streak!"
   - ✅ Streak card visible, count increments correctly

2. **Scenario: Streak Reset**
   - Streak = 14 after 14 consecutive days
   - Skip Day 15 (no activity)
   - Day 16: Add item → streak resets to 1, "🔥 1-Day Streak!"
   - ✅ Reset message displayed (optional snackbar: "Streak reset. Start fresh!")

3. **Scenario: Milestone Unlock**
   - Streak increments to 7 days
   - ✅ Notification: "🎉 One Week Champion! Keep the streak alive!"
   - Tap close → badge added to achievements modal

4. **Scenario: Weekly Summary**
   - Week: 23 items saved, 2 items wasted
   - Last week: 19 items saved, 1 item wasted
   - ✅ Summary card shows:
     - "You saved 23 items ↑ 21% from last week (19)"
     - "Most saved category: 🥕 Produce (12 items)"
     - "Active 6 out of 7 days"

5. **Scenario: Settings Toggle**
   - Disable "Streak Reminders" in Settings
   - No reminder notifications on streak milestones (but streak still tracks)
   - ✅ Streak card still visible on home screen
   - Re-enable setting → reminders resume

6. **Scenario: Settings Toggle (Summary)**
   - Disable "Weekly Progress Summary" in Settings
   - Progress screen shows only charts/history (no summary card)
   - ✅ Re-enable → summary card reappears

---

## Out of scope

- **Cross-device streak sync** — free tier only; defer to M6 Pro tier
- **Leaderboards** — no social comparison for MVP
- **Push notification reminders** — planned for M5/380 (notification preferences), not this issue
- **Badges with images** — text + emoji only; defer to M5/375 (Zesto mascots)
- **Custom streak goals** — fixed milestones only (7, 14, 30, 100 days)
- **Offline streak preservation on cloud** — no backup; local storage only

---

## Implementation notes

### Streak Psychology

Why streaks work:
1. **Commitment device:** Users don't want to "waste" their streak → builds habit
2. **Visible progress:** Counter shows cumulative effort → motivates continuation
3. **Milestone celebrations:** Unlocking badges provides dopamine hit → reinforces behavior
4. **Comparison feedback:** "Last week = 19, this week = 23" shows tangible progress → validates effort

**Design principle:** Make streak **visible and celebrated**; users should see it on first launch.

### Performance Optimization

- Compute streak + weekly stats once on app startup
- Cache results in memory (StreakProvider with Riverpod or similar)
- Recompute if >5 min elapsed or on explicit refresh
- Limit historical data: keep 12 weeks of stats, delete older

### Future Enhancements (M6+)

- **Cloud sync:** Persist streak + stats on backend (cross-device)
- **Push reminders:** "Your streak is at risk! Add an item today."
- **Social sharing:** "I've saved 23 items this week! 🎉"
- **Monthly goals:** "Save 100+ items this month" (explicit goal setting)
- **Household streak:** Aggregate family members' contributions into shared streak

---

## Dependencies

- **M1/040:** Telemetry infrastructure (event emission)
- **M2/300:** Progress/Metrics screen exists and is functional
- **M1/080:** Data model with consumption events (item_used, item_wasted)

---

## Notes for Implementation

> This feature is **critical for retention** because:
> 1. Streaks create **habit loops** (action → reward → repeat)
> 2. Visual feedback (on home screen) creates **behavioral reinforcement**
> 3. Comparison to prior week shows **tangible progress** (dopamine hit)
> 4. Milestone celebrations create **social proof** ("I'm doing this consistently")
>
> **Priority in M5:** Implement early (after core screens), as it unlocks habituation.
> **Metrics to track:** DAU (daily active users), streak persistence, retention rates (day 7, day 30).
