# Notification UX Defaults

## Overview
Reminders are central to ZeroSpoils' value proposition. They must be **helpful, not annoying** — encouraging users to take action without judgment.

**Design principles:**
- **Supportive tone:** Empowering language that helps users succeed
- **Non-judgmental:** No shame about expired items or waste
- **Actionable:** Clear next steps in every notification
- **Configurable:** Users control timing and frequency

---

## Default Lead Times

Users receive notifications at three key moments before an item expires:

| Lead Time | Timing | Purpose |
|-----------|--------|---------|
| **3 days before** | 72 hours prior to expiry | Early warning for meal planning |
| **1 day before** | 24 hours prior to expiry | Urgent reminder to use item |
| **Day of expiry** | Morning of expiration date | Last-chance alert |

**Default schedule:** All three notifications enabled by default. Users can disable individual lead times in Settings.

**Time of day:** All notifications sent at **9:00 AM local time** (configurable in Settings: 7 AM - 10 AM).

---

## Notification Copy Templates

### Template Variables
All templates support these variables:
- `{item_name}` — Item name (e.g., "Milk", "Chicken breast")
- `{expiry_date}` — Human-readable date (e.g., "Jan 25", "Tomorrow", "Today")
- `{days_left}` — Number of days until expiry (e.g., "3", "1")
- `{location}` — Storage location (e.g., "Fridge", "Freezer")
- `{category}` — Item category (e.g., "Dairy", "Produce")

---

### 3 Days Before Expiry

**Title:**
```
🍴 Plan ahead: {item_name} expires in 3 days
```

**Body:**
```
Your {item_name} in the {location} expires on {expiry_date}. Add it to your meal plan this week!
```

**Actions:**
- "View Item" → Opens item detail screen
- "Dismiss" → Dismisses notification

**Example:**
```
🍴 Plan ahead: Milk expires in 3 days

Your Milk in the Fridge expires on Jan 26. Add it to your meal plan this week!

[View Item]  [Dismiss]
```

---

### 1 Day Before Expiry

**Title:**
```
⏰ Use soon: {item_name} expires tomorrow
```

**Body:**
```
Your {item_name} expires tomorrow ({expiry_date}). Make sure to use it!
```

**Actions:**
- "View Item" → Opens item detail screen
- "Mark as Used" → Marks item as consumed
- "Dismiss" → Dismisses notification

**Example:**
```
⏰ Use soon: Chicken breast expires tomorrow

Your Chicken breast expires tomorrow (Jan 25). Make sure to use it!

[View Item]  [Mark as Used]  [Dismiss]
```

---

### Day of Expiry

**Title:**
```
🔔 Expires today: {item_name}
```

**Body:**
```
Your {item_name} expires today. Use it now or mark as wasted if it's too late.
```

**Actions:**
- "Mark as Used" → Marks item as consumed
- "Mark as Wasted" → Records waste event
- "Dismiss" → Dismisses notification

**Example:**
```
🔔 Expires today: Yogurt

Your Yogurt expires today. Use it now or mark as wasted if it's too late.

[Mark as Used]  [Mark as Wasted]  [Dismiss]
```

---

### Already Expired (Edge Case)

**Title:**
```
⚠️ Expired: {item_name}
```

**Body:**
```
Your {item_name} expired {days_left} days ago. Check if it's still safe to use.
```

**Actions:**
- "Mark as Used" → Marks item as consumed (if still safe)
- "Mark as Wasted" → Records waste event
- "Remove" → Deletes item from inventory

**Example:**
```
⚠️ Expired: Cheese

Your Cheese expired 2 days ago. Check if it's still safe to use.

[Mark as Used]  [Mark as Wasted]  [Remove]
```

---

## Tone Guidelines

### ✅ Do
- **Empowering language:** "You can do this!"
- **Helpful suggestions:** "Add to meal plan", "Use in tonight's dinner"
- **Neutral framing:** "Expires today" (not "going bad")
- **Positive reinforcement:** "Great job tracking your food!"
- **Action-oriented:** Clear next steps in every notification

### ❌ Don't
- **Judgmental language:** "You're wasting food", "Another item expired"
- **Guilt-tripping:** "This item is going to waste because you forgot"
- **Alarmist tone:** "URGENT: Food is rotting!"
- **Negative framing:** "Failed to use", "You let this expire"
- **Passive voice:** "Item has expired" → Use "Your {item} expires today"

---

## Settings Configuration

Users can customize notification behavior in **Settings → Notifications**:

### Lead Time Toggles
- ☑️ 3 days before expiry
- ☑️ 1 day before expiry
- ☑️ Day of expiry

### Time of Day
- **Send notifications at:** [Dropdown: 7 AM - 10 AM]
- Default: 9:00 AM

### Do Not Disturb
- ☐ Pause all notifications until [Date picker]

### Per-Category Overrides (Future Enhancement)
- Produce: 2 days, 1 day (shorter lead time)
- Dairy: 3 days, 1 day, day-of (standard)
- Pantry: 1 week, 3 days (longer lead time)

---

## Implementation Notes

### Flutter Package
Use `flutter_local_notifications` for local notification scheduling:
```dart
dependencies:
  flutter_local_notifications: ^17.0.0
```

### Scheduling Logic
- Calculate expiry date for each item
- Schedule 3 notifications per item (3 days, 1 day, day-of)
- Cancel notifications if item is marked as used/wasted before expiry
- Reschedule if expiry date changes

### Permissions
- iOS: Request notification permissions on first launch (Settings screen)
- Android: Notifications enabled by default (API 33+)

### Telemetry Events
Track notification effectiveness:
- `notification_received` (lead_time, item_category)
- `notification_action_taken` (action: viewed, marked_used, dismissed)
- `notification_settings_changed` (setting: lead_time, value)

---

## User Research Validation

**Test scenarios:**
1. Show 5 users the notification copy templates
2. Ask: "Does this make you feel motivated or judged?"
3. Validate: Users understand action buttons and next steps

**Success criteria:**
- 4/5 users find tone supportive (not judgmental)
- 5/5 users understand what "Mark as Used" means
- 3/5 users would enable all three default lead times

---

## Future Enhancements (Out of Scope for MVP)

- **Smart timing:** Learn user's meal prep times, send reminders accordingly
- **Recipe suggestions:** "Your {item} expires soon — here are 3 recipes"
- **Batch reminders:** "3 items expire this week — view list"
- **Quiet hours:** Don't send notifications between 10 PM - 7 AM
- **Weekly summary:** "This week: 5 items used, 1 wasted, 80% success rate"

---

## Related Documents
- [Telemetry Taxonomy](./telemetry.md) — Event definitions for notification tracking
- [UX Wireframes](./ux.md) — Settings screen mockups
- Issue M1/070 — Notification UX defaults specification
- Issue M3/XXX — Notification implementation (TBD)

---

**Last Updated:** January 23, 2026  
**Owner:** Product Team  
**Status:** Specification complete, implementation deferred to M3
