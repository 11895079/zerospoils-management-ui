# 155: Smart Replenishment — Predict Re-buy Items Based on Consumption History

**Epic:** Inventory Intelligence  
**Milestone:** M5 (Public Launch)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 080 (data model — consumption events), 040 (telemetry — item_mark_used events)

---

## Context

Users manually maintain shopping lists by remembering what they buy regularly. Most households have repeat purchases (milk every 5–7 days, bread every 4 days, coffee every 2 weeks), but users must re-enter these items every trip.

**Problem:** Shopping list creation is friction; users forget regular items or duplicate entries.

**Opportunity:** Track consumption patterns (when users mark items as "used") and suggest likely re-buys, reducing friction and increasing shopping list conversion.

---

## Goal

Implement predictive "Smart Replenishment" suggestions on the Shopping List screen that learn from consumption history and suggest items the user historically buys at intervals (e.g., "Milk — Usually every 5 days").

---

## Expected behavior

### Consumption History Tracking

1. When user marks item as **"used"** (via Inventory → item detail → "Mark used"), record:
   - Item name (case-insensitive, deduplicated)
   - Category
   - Timestamp of consumption event
   - Previous consumption event for same item (if any)

2. Compute **inter-purchase intervals:**
   - "Milk" consumed on [Jan 1, Jan 6, Jan 12, Jan 18] → intervals [5d, 6d, 6d]
   - Average interval: 5.67 days
   - Standard deviation: 0.47 days

3. Aggregate consumption history in local DB (persisted across app restarts):
   - Table: `consumption_history` (item_name, category, last_consumed_date, intervals[], avg_interval_days, total_consumptions)

### Smart Replenishment Suggestions

**Shopping List Screen — New "Smart Replenishment" Section:**

```
Shopping List

[Manually Added Items Section]
☐ Eggs (qty: 2)
☐ Tomatoes (qty: 3)

---

💡 Smart Replenishment (Based on Your History)

Based on patterns    Last bought: 5 days ago      Recency score
Milk                 Usually every 5 days        91% likely now
🥛━━━━━━━━━━━━━[⚫]

Bread                 Usually every 4 days        78% likely now
🍞━━━━━━━━━━━[⚫]

Coffee               Usually every 14 days       34% likely now
☕━━━━━━[⚫]________

[+ Add to list]      [✕ Dismiss]
```

### Suggestion Ranking

Suggestions ranked by **"re-purchase likelihood"** score:

```
likelihood_score = (recency_factor × frequency_factor) × base_confidence

where:
  recency_factor = days_since_last_consumed / avg_interval_days
                  (capped at 1.5 to avoid over-weighting old items)
  
  frequency_factor = total_consumptions / 10 (normalize; capped at 1.0)
                     (more history = higher confidence)
  
  base_confidence = 0.7 (threshold: only show if > 70%)
```

**Example:**
- Milk: last consumed 5 days ago, avg interval 5d, 52 total consumptions
  - recency = 5/5 = 1.0
  - frequency = 52/10 = 1.0 (capped)
  - score = 1.0 × 1.0 × 0.7 = **70%**  ✅ Suggested (≥70%)

- Coffee: last consumed 8 days ago, avg interval 14d, 12 total consumptions
  - recency = 8/14 = 0.57
  - frequency = 12/10 = 1.0 (capped)
  - score = 0.57 × 1.0 × 0.7 = **39%**  ✗ Not suggested (<70%)

### User Actions

1. **View suggestion:** Displays item name + "Usually every X days" + likelihood bar
2. **Tap "+ Add to list":** Creates shopping list item with quantity = 1 (user can edit)
3. **Tap "✕ Dismiss":** Hides that suggestion for this session (can reappear on next session)
4. **Edit quantity:** User edits added item (e.g., milk qty: 2 instead of 1)

### Settings Control

**Settings → Privacy & Data:**
```
☑ Smart Replenishment Suggestions
  (Analyzes your consumption history to suggest likely re-buys)
  Learn more...
```

Disabled → Smart Replenishment section hidden on Shopping List screen.

---

## Acceptance criteria (Definition of Done)

### Data Model & Consumption Tracking
- [ ] Extend `InventoryItem` model to include consumption history tracking
- [ ] Add `consumption_events` table to local DB (Hive/sqflite):
  ```
  {
    item_name (text),           // case-insensitive, deduplicated
    category (text),
    consumed_date (DateTime),
    quantity (int),             // how many units marked used
  }
  ```
- [ ] When user marks item as "used", create consumption event
- [ ] Aggregate consumption history on app startup + periodically (e.g., every 5 min) into:
  ```
  {
    item_name (text, unique),
    category (text),
    last_consumed_date (DateTime),
    intervals_days (List<int>),
    avg_interval_days (double),
    stddev_interval_days (double),
    total_consumptions (int),
  }
  ```
- [ ] Handle edge cases:
  - New items (no history) → not suggested
  - Single consumption (no pattern yet) → not suggested until ≥2 consumptions
  - Case-insensitive matching ("Milk", "milk", "MILK" → same item)
  - Typos/spelling variations → (defer fuzzy matching to future, use exact match for MVP)
  - Items with 0 consumption → excluded from suggestions

### Suggestion Algorithm
- [ ] Implement `calculateRepurchaseLikelihood(item)` function
- [ ] Rank suggestions by likelihood score (desc)
- [ ] Filter for score ≥0.70 (70% threshold)
- [ ] Show top 5 suggestions (prevent overload)
- [ ] Tests:
  - Unit test: Likelihood calculation for known scenarios (milk, bread, coffee)
  - Unit test: Threshold filtering (only ≥70% shown)
  - Unit test: Ranking order (highest score first)
  - Edge case: Empty history → no suggestions
  - Edge case: Single consumption → no suggestions

### UI/UX
- [ ] Create "Smart Replenishment" section card on Shopping List screen
- [ ] Display below manually added items (visual separation with divider)
- [ ] Each suggestion shows:
  - Item icon/thumbnail (or category icon)
  - Item name
  - "Usually every X days" label
  - Likelihood bar (linear progress bar, 0–100%)
  - "+ Add" button + "✕" dismiss button
- [ ] Likelihood bar color:
  - 🟢 Green: 80–100% (very likely)
  - 🟡 Yellow: 70–79% (likely)
- [ ] Empty state: If no suggestions ≥70%, section hidden (not shown as empty)
- [ ] Tapping "+ Add" creates shopping list item with default qty=1
- [ ] User can edit qty after adding
- [ ] "✕ Dismiss" removes from this session's view (persists in data)

### Telemetry
- [ ] `shopping_suggestions_viewed` event:
  - Properties: `suggestion_count`, `top_3_items` (item names), `top_likelihood_score`
- [ ] `shopping_suggestion_added` event:
  - Properties: `item_name`, `likelihood_score`, `avg_interval_days`, `last_consumed_days_ago`
- [ ] `shopping_suggestion_dismissed` event:
  - Properties: `item_name`, `likelihood_score` (note dismissals to improve ranking)
- [ ] Track conversion: `insights_shopping_suggestions_to_purchase` (proxy: shopping list completions after viewing suggestions)

### Accessibility
- [ ] Suggestion cards have semantic labels: "Milk, usually every 5 days, 91% likely"
- [ ] Likelihood bar has accessible name (e.g., `aria-label="91 percent likely"`)
- [ ] Tap targets ≥44pt
- [ ] Keyboard navigation: Tab → through suggestions

### Persistence & Sync
- [ ] Consumption history persisted locally (survives app restart)
- [ ] No cloud sync for MVP (free tier, offline-first)
- [ ] Pro tier (M6): optional cloud sync of patterns

### Tests

**Automated Tests (Unit):**

- Test consumption event creation:
  - Mark "Milk" as used → new consumption event created
  - Mark "milk" (lowercase) as used → same item aggregated (case-insensitive)

- Test interval calculation:
  - Milk consumed [Jan 1, Jan 6, Jan 12] → intervals [5, 6] days, avg 5.5 days

- Test likelihood scoring:
  - Milk (5 days ago, 5d avg, 50 consumptions) → score 70% ✓
  - Bread (2 days ago, 4d avg, 12 consumptions) → score 88% ✓
  - Coffee (25 days ago, 14d avg, 8 consumptions) → score 31% ✗

- Test filtering:
  - Only items with ≥70% likelihood shown
  - Empty history → no suggestions
  - Single consumption → no suggestions

- Test ranking:
  - Top 5 by likelihood score (desc)
  - Ties broken by recency (most recent first)

**Widget Tests (UI):**

- Render Smart Replenishment section with 3 suggestions
- Verify suggestion order (high→low likelihood)
- Tap "+ Add" button → item added to shopping list
- Tap "✕ Dismiss" button → item removed from current view
- Edit qty after adding → qty persisted
- Empty state: section hidden if no suggestions ≥70%

**Integration Tests:**

- Mark item as used (Inventory) → appears in Smart Replenishment after 2+ consumptions
- Add suggestion to shopping list → shopping list count increases
- Modify suggestion qty → qty reflected in shopping list

**Manual Smoke Tests:**

1. **Scenario: New User (No History)**
   - Navigate to Shopping List → Smart Replenishment section not shown (no history)
   - ✅ Pass

2. **Scenario: Build History, Then Suggest**
   - Mark "Milk" as used on Days [1, 6, 12, 18] (5–6 day pattern)
   - On Day 23, navigate to Shopping List
   - ✅ Milk appears in Smart Replenishment with "Usually every 5 days"
   - ✅ Likelihood ≥80% shown in green bar

3. **Scenario: Multiple Items Ranked**
   - History: Milk (5d pattern), Bread (4d pattern), Coffee (14d pattern)
   - Last consumption: Milk (5d ago), Bread (2d ago), Coffee (20d ago)
   - Ranking should be: Bread (88%), Milk (70%), Coffee (34%)
   - ✅ Smart Replenishment shows Bread #1, Milk #2, Coffee not shown (<70%)

4. **Scenario: Add & Edit**
   - Tap "+ Add" on Milk suggestion → qty=1 added to Shopping List
   - Tap qty field → change to qty=2
   - ✅ Qty persisted, total items = 2

5. **Scenario: Dismiss & Re-session**
   - Tap "✕" on Coffee suggestion → hidden from view
   - Restart app
   - ✅ Coffee reappears (dismiss was session-scoped)

6. **Scenario: Settings Toggle**
   - Disable "Smart Replenishment Suggestions" in Settings
   - Navigate to Shopping List
   - ✅ Section not shown (hidden by user preference)
   - Re-enable in Settings
   - ✅ Section reappears

---

## Out of scope

- **Fuzzy matching for typos** (e.g., "Milk" vs "Mulk") — defer to future iteration; MVP uses exact match
- **Cloud sync of patterns** — free tier only; defer to M6 Pro tier
- **Dietary filters** — no user preferences for MVP; show all patterns
- **Household-specific patterns** — single-user only; defer to M6 household sync (540)
- **Predictive pricing** — no price optimization; defer to future
- **Seasonal adjustments** — no seasonal data; start with raw patterns
- **Machine learning model** — use heuristic algorithm only (no ML infrastructure)

---

## Implementation notes

### Algorithm Trade-offs

**Option A (Current):** Heuristic-based likelihood (recency × frequency × confidence)
- ✅ No ML infrastructure needed
- ✅ Transparent to users (explainable: "Usually every 5 days")
- ✅ Works offline
- ❌ Less sophisticated (no ML personalization)

**Option B (Future/M6 Pro):** ML model trained on consumption patterns
- ✅ More accurate after user builds history
- ❌ Requires cloud infrastructure + model hosting
- ❌ Defer to Pro tier

**Decision:** Start with Option A (MVP), plan Option B for M6 Pro tier enhancement.

### Local DB Schema

```sql
-- Consumption history table
CREATE TABLE consumption_events (
  id INTEGER PRIMARY KEY,
  item_name TEXT NOT NULL,
  category TEXT,
  consumed_date DATETIME NOT NULL,
  quantity INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Aggregated patterns table (for performance, recomputed periodically)
CREATE TABLE consumption_patterns (
  item_name TEXT PRIMARY KEY,
  category TEXT,
  last_consumed_date DATETIME,
  avg_interval_days REAL,
  stddev_interval_days REAL,
  total_consumptions INTEGER,
  intervals_json TEXT, -- JSON array of interval days
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### Performance Optimization

- Compute patterns **once on app startup** (not on every Shopping List open)
- Cache results in memory during session
- Recompute if ≥10 min elapsed since last update
- Limit history retention to **12 months** (delete older consumption events periodically)

### Future Enhancements (M6+)

- Fuzzy matching for item name variations ("Milk" ≈ "Whole Milk")
- Seasonal patterns (higher demand in winter for heating oil, etc.)
- Household-level aggregation (if Item A bought by family member, suggest for all users)
- ML model training on consumption + purchase price data
- Push notification: "Milk is running low based on your pattern" (M6 Pro)

---

## Dependencies

- **M1/080:** Data model with consumption events (`item_mark_used`)
- **M1/040:** Telemetry infrastructure (event emission)
- **M5/360:** Shopping List UI screen exists and is functional

---

## API / External Services

None required (local-only processing, no API calls).

---

## Notes for Implementation

> This feature is **high-impact for retention** because it:
> 1. Reduces friction (fewer items to manually re-enter each trip)
> 2. Catches forgotten items (history-based reminders)
> 3. Drives social proof ("You usually buy milk every 5 days" = validation)
> 4. Creates habit loops (use item → mark used → see suggestion → add to list → purchase again)
>
> **Priority in M5:** Implement after core Shopping List features (add/remove items), as it's an enhancement, not core.
