# Zesto the Avocado: Mascot Interaction Specification

**Version:** 1.0  
**Last Updated:** January 20, 2026  
**Status:** Planning (Not Yet Implemented)

---

## 1. Character Overview

### Identity
- **Name:** Zesto the Avocado
- **Visual:** 🥑 emoji (60px on pages, 140px in onboarding)
- **Personality:** Friendly, encouraging, playful but not annoying
- **Role:** Companion that celebrates wins, offers tips, and tracks progress
- **Tone:** Positive reinforcement, never judgmental about waste

### Design Principles
1. **Enhancement, not distraction** — Appears briefly (3s), then fades
2. **Context-aware** — Different messages based on user action/location
3. **Delightful but optional** — Users can disable in Settings
4. **Progressive disclosure** — Basic interactions first, advanced features unlocked over time

---

## 2. Current Implementation (v1.0)

### Pages with Zesto
- ✅ **Onboarding** (mascot.html): Introduction screen explaining his purpose
- ✅ **Inventory** (index.html): Appears after "Level up" button celebration
- ✅ **Progress** (progress.html): Appears on page load + when tapping badges overview

### Existing Triggers
| Trigger | Page | Message Type | Example Messages |
|---------|------|--------------|------------------|
| Item saved (celebrate button) | Inventory | `celebration` | "Amazing! 🎉", "You're crushing it! 💚", "Keep going! 🌟" |
| Page load | Progress | `pageLoad` | "Looking good! 📊", "Progress check! 💪", "Keep it up! 🌟" |
| Badges tapped | Progress | `badgeView` | "Check your badges! 🏆", "You earned 2 badges! 🎉", "2 down, 18 to go! 💪" |

### Technical Implementation
- **Position:** Absolute (bottom: 140px, left: 20px, z-index: 150)
- **Animation:** Bounce loop (2s infinite), bubble pop-in (0.3s cubic-bezier)
- **Auto-dismiss:** 3-second timeout, fade out transition
- **JavaScript:** `showMascot(messageType)` function with message arrays

---

## 3. Planned Interactions & Abilities

### 3.1 Core Triggers (Priority 1 — Implement First)

#### **Item Actions**
| Trigger | When | Message Type | Example Messages |
|---------|------|--------------|------------------|
| **First item added** | User adds their very first inventory item | `firstItem` | "Welcome! 🎉", "Great start! 💚", "Your first item! 🌟" |
| **Item consumed** | User marks item as consumed (not wasted) | `consumed` | "Saved it! 🎉", "Zero waste! 💚", "Yum! 😋" |
| **Item wasted** | User marks item as wasted | `wasted` | "💡 Tip: Store milk in back of fridge!", "Next time, freeze extras! ❄️", "Learn & improve! 📈", "Try freezing next time! 💡", "Store in airtight container! 📦" |
| **Quick save** | User consumes item <24h before expiry | `quickSave` | "Just in time! ⏰", "Beat the clock! 🏃", "Close call! 💚" |

#### **Milestones & Achievements**
| Trigger | When | Message Type | Example Messages |
|---------|------|--------------|------------------|
| **Badge unlocked** | User earns any badge | `badgeUnlocked` | "New badge! 🏆", "Achievement unlocked! 🎉", "You earned it! 💪" |
| **Streak milestone** | User hits 5/10/30/100-day streak | `streakMilestone` | "5 days strong! 🔥", "10 days! Legendary! ⚡", "100 days! 🤯" |
| **Savings milestone** | User saves $50/$100/$500 | `savingsMilestone` | "$50 saved! 💰", "You're rich! 💵", "Money in the bank! 🏦" |
| **Waste reduction** | User hits 0% waste for week/month | `zeroWaste` | "Perfect week! 🌟", "No waste! 🎉", "Flawless! 💚" |

#### **Daily Engagement**
| Trigger | When | Message Type | Example Messages |
|---------|------|--------------|------------------|
| **Daily first open** | User opens app (once per day) | `dailyWelcome` | "Good morning! ☀️", "Welcome back! 👋", "Let's check in! 📱" |
| **Expiring soon alert** | 3+ items expiring within 24h | `expiryAlert` | "3 items expiring! ⏰", "Check fridge! 🥛", "Use these soon! 🍎" |
| **Shopping reminder** | User hasn't shopped in 7+ days | `shoppingReminder` | "Time to shop? 🛒", "List ready! 📝", "Plan a trip? 🚗" |

### 3.2 Advanced Interactions (Priority 2 — Future Enhancement)

#### **Contextual Tips**
| Trigger | When | Message Type | Example Messages |
|---------|------|--------------|------------------|
| **Storage tip** | User adds item with common storage mistakes | `storageTip` | "💡 Tip: Store bananas separately!", "Tip: Bread stays fresher frozen!", "Tomatoes like room temp! 🍅" |
| **Recipe suggestion** | User has 3+ expiring items that pair well | `recipeSuggestion` | "Try a stir-fry! 🍲", "Make a smoothie! 🥤", "Soup time! 🍜" |
| **Bulk save tip** | User adds many items at once (5+) | `bulkTip` | "Freeze extras! ❄️", "Meal prep time? 🍱", "Portion & freeze! 📦" |

#### **Social Interactions (Pro Tier)**
| Trigger | When | Message Type | Example Messages |
|---------|------|--------------|------------------|
| **Challenge started** | User joins or creates challenge | `challengeStart` | "Challenge on! 🎮", "Let's compete! 🏁", "Game time! 💪" |
| **Friend joined** | New friend connects | `friendJoin` | "New friend! 👋", "Squad grows! 🎉", "Welcome aboard! 🚀" |
| **Leaderboard rank** | User enters top 10 on leaderboard | `leaderboard` | "Top 10! 🏆", "You're ranked! 📊", "Rising star! ⭐" |

#### **Seasonal & Special Events**
| Trigger | When | Message Type | Example Messages |
|---------|------|--------------|------------------|
| **Holiday reminder** | Major holiday approaching | `holiday` | "Thanksgiving prep! 🦃", "Holiday planning? 🎄", "Party prep! 🎉" |
| **Earth Day** | April 22 | `earthDay` | "Happy Earth Day! 🌍", "Planet thanks you! 💚", "Eco hero! 🌱" |
| **App anniversary** | User's 1-year app-versary | `anniversary` | "1 year! 🎂", "You've saved so much! 💚", "Thanks for a year! 🎉" |

### 3.3 User-Initiated Interactions (Priority 3 — Long-term)

#### **Tap Zesto** (When visible)
- **Action:** User taps mascot character
- **Behavior:** Shows contextual tips based on current page/screen
- **Examples by page:**
  - **Inventory:** "💡 Tip: First in, first out (FIFO)!", "Store by expiry date!"
  - **Expiring Soon:** "Freeze items to extend life! ❄️", "Cook a batch meal!"
  - **Shopping List:** "Check inventory first!", "Plan 3-4 days ahead!"
  - **Progress:** "You've saved X items!", "Y% better than last week!"
  - **Add Item:** "Don't forget expiry date!", "Group by category!"

#### **Settings Control**
- **Toggle Zesto on/off** (Settings → App Preferences)
- **Frequency slider:** "Always" / "Milestones Only" / "Never"
- **Message types:** Enable/disable tips, celebrations, alerts

---

## 4. Message Content Guidelines

### Tone & Voice
- ✅ **DO:** Use encouraging, positive language
- ✅ **DO:** Keep messages short (3-6 words ideal)
- ✅ **DO:** Include relevant emojis (1-2 per message)
- ✅ **DO:** Vary messages to prevent repetition
- ❌ **DON'T:** Blame or shame users for waste
- ❌ **DON'T:** Use complex sentences or jargon
- ❌ **DON'T:** Overwhelm with too many messages
- ❌ **DON'T:** Make Zesto annoying or intrusive

### Message Structure
```javascript
messageType: [
  "Primary message! emoji",
  "Alternate phrasing! emoji",
  "Another variation! emoji",
  "Fourth option! emoji",
  "Fifth variation! emoji",
  // Minimum 5-6 variations per type to prevent repetition fatigue
]
```

### Emoji Usage Patterns
- **Celebration:** 🎉 🌟 💚 💪 🔥 ✨
- **Progress:** 📊 📈 🏆 💯 ⭐ 🎯
- **Food/Items:** 🥑 🥛 🍎 🍞 🥕 🌮
- **Money:** 💰 💵 💸 🏦 💳
- **Time:** ⏰ ⏳ 🕐 ⌛
- **Tips:** 💡 🔍 📝 ✏️
- **Social:** 👋 🤝 👥 🎮 🏁

---

## 5. Animation & Behavior Specifications

### Animation States
| State | Visual | Duration | Trigger |
|-------|--------|----------|---------|
| **Idle** | Gentle bounce loop | 2s infinite | Always (when visible) |
| **Appear** | Scale 0→1, opacity 0→1 | 0.3s | Message triggered |
| **Celebrate** | Larger bounce + rotation | 0.5s | Badge unlocked, milestone |
| **Shake head** | Rotate -15° ↔ +15° | 0.4s | Waste event (gentle) |
| **Wave** | Scale pulse + rotate | 0.6s | Daily welcome, friend join |
| **Disappear** | Opacity 1→0, scale 1→0.95 | 0.3s | Auto-dismiss timeout |

### Timing Rules
- **Default display:** 3 seconds before auto-dismiss
- **Celebration events:** 4 seconds (longer for milestones)
- **Alert messages:** 5 seconds (user needs to see/act)
- **Tips:** 6 seconds (more content to read)
- **Minimum gap:** 5 seconds between messages (prevent spam)

### Positioning Logic
- **Default:** Bottom-left (bottom: 140px, left: 20px)
- **With FAB:** Shift up if FAB visible (bottom: 200px)
- **With bottom sheet:** Hide temporarily until dismissed
- **Portrait only:** Hide in landscape mode (limited space)

---

## 6. Technical Implementation Plan

### Phase 1: Core Triggers (M3 — Current Milestone)
```javascript
// Expand showMascot() function with new message types
const mascotMessages = {
  celebration: [...], // ✅ EXISTING
  pageLoad: [...],    // ✅ EXISTING
  badgeView: [...],   // ✅ EXISTING
  
  // NEW (Phase 1)
  firstItem: ["Welcome! 🎉", "Great start! 💚", "Your first item! 🌟", "Nice work! 💪", "Let's save food! 🌱"],
  consumed: ["Saved it! 🎉", "Zero waste! 💚", "Yum! 😋", "Perfect! 🌟", "Well done! 💪"],
  wasted: ["💡 Tip: Store milk in back of fridge!", "Next time, freeze extras! ❄️", "Learn & improve! 📈", "Try freezing next time! 💡", "Store in airtight container! 📦"],
  quickSave: ["Just in time! ⏰", "Beat the clock! 🏃", "Close call! 💚", "Saved at the buzzer! 🔔", "Nick of time! ⏳"],
  badgeUnlocked: ["New badge! 🏆", "Achievement unlocked! 🎉", "You earned it! 💪", "Badge get! 🌟", "Congrats! 🎊"],
  streakMilestone: ["5 days strong! 🔥", "10 days! Legendary! ⚡", "30 days! Amazing! 🤯", "100 days! Incredible! 🏆", "On fire! 🔥"],
  savingsMilestone: ["$50 saved! 💰", "You're rich! 💵", "Money in the bank! 🏦", "Cha-ching! 💸", "Savings hero! 💳"],
  zeroWaste: ["Perfect week! 🌟", "No waste! 🎉", "Flawless! 💚", "100% saved! 💯", "Waste-free! 🌱"],
  dailyWelcome: ["Good morning! ☀️", "Welcome back! 👋", "Let's check in! 📱", "Ready to save? 🌟", "New day! 🌅"],
  expiryAlert: ["3 items expiring! ⏰", "Check fridge! 🥛", "Use these soon! 🍎", "Expiry alert! 🔔", "Time to cook! 🍳"],
};
```

### Phase 2: Advanced Interactions (M4 — Polish Milestone)
- Storage tips based on item category
- Recipe suggestions from expiring items
- Contextual help messages
- Seasonal event triggers

### Phase 3: Social & Customization (M5 — Advanced Features)
- Challenge/leaderboard messages
- Friend interaction messages
- Settings controls (frequency, types)
- Tap-to-cycle-tips interaction
- Custom mascot selection (carrot, broccoli, bread based on top category)

### Data Requirements
- **Local storage:**
  - Last message timestamp (prevent spam - 5 second minimum gap)
  - User preferences (enabled, frequency)
  - Message history (prevent immediate repeats)
  - Unlocked mascots (track which characters user has earned)
- **Storage tips JSON file:**
  - Item category → storage tip mappings
  - Easy to update without code changes
  - ~20-30 common tips covering major food categories
- **Telemetry events:**
  - `mascot_shown` (messageType, page)
  - `mascot_dismissed` (auto vs manual, duration)
  - `mascot_tapped` (contextual tips shown)

---

## 7. Settings Integration

### Proposed Settings Structure
**Settings → App Preferences → Mascot (Zesto)**

```
⚙️ App Preferences
└── 🥑 Mascot (Zesto)
    ├── ☑️ Enable Mascot
    │   └── (Toggle on/off)
    ├── 📊 Appearance Frequency
    │   ├── ○ Always (All events)
    │   ├── ● Milestones Only (Badges, streaks, savings) [DEFAULT]
    │   └── ○ Never
    ├── 💬 Message Types
    │   ├── ☑️ Celebrations (Saves, badges, streaks)
    │   ├── ☑️ Tips & Reminders (Storage, expiry alerts)
    │   └── ☑️ Daily Welcome
    └── 🎨 Customize (Free - Unlockable)
        ├── 🥑 Avocado (Zesto) — Default
        ├── 🥕 Carrot — Save 50 carrots to unlock
        ├── 🥦 Broccoli — Save 50 vegetables to unlock
        └── 🍞 Bread — Save 50 grains to unlock
```

---

## 8. Success Metrics

### User Engagement
- **Mascot visibility rate:** % of eligible events where mascot shown
- **Dismissal rate:** % auto-dismissed vs manually dismissed (tap outside)
- **Setting changes:** % users who modify mascot settings
- **Tap interaction:** (Phase 3) % users who tap mascot for tips

### Behavioral Impact
- **Post-celebration actions:** Do users add more items after "Level up" celebration?
- **Expiry alert response:** Do users consume items after expiry alerts?
- **Tip effectiveness:** Do storage tips reduce waste for those item types?

### Sentiment
- **User feedback:** In-app surveys, app store reviews mentioning mascot
- **Disable rate:** % of users who turn off mascot completely
- **Pro conversion:** Does mascot customization drive Pro upgrades?

---

## 9. Implementation Checklist

### Phase 1: Core Triggers (M3)
- [ ] Add 10 new message types to `mascotMessages` object
- [ ] Implement `firstItem` trigger on first inventory add
- [ ] Implement `consumed`/`wasted` triggers on item action
- [ ] Implement `quickSave` logic (check expiry date < 24h)
- [ ] Implement `badgeUnlocked` trigger (integrate with badge system)
- [ ] Implement `streakMilestone` trigger (5/10/30/100 day checks)
- [ ] Implement `savingsMilestone` trigger ($50/$100/$500 checks)
- [ ] Implement `zeroWaste` trigger (weekly/monthly 0% calculation)
- [ ] Implement `dailyWelcome` trigger (once per day, first open)
- [ ] Implement `expiryAlert` trigger (check for 3+ items expiring <24h)
- [ ] Add anti-spam logic (5s minimum gap between messages)
- [ ] Add message history (prevent same message twice in a row)
- [ ] Telemetry: `mascot_shown`, `mascot_dismissed` events

### Phase 2: Advanced Interactions (M4)
- [ ] Implement storage tips (item category → tip mapping)
- [ ] Implement recipe suggestions (ingredient pairing logic)
- [ ] Implement bulk tip (5+ items added at once)
- [ ] Add seasonal events (holiday detection, Earth Day)
- [ ] Add app anniversary trigger (user signup date + 1 year)
- [ ] Enhanced animations (celebrate, shake, wave states)
- [ ] Positioning logic (shift for FAB, hide for bottom sheets)

### Phase 3: Social & Customization (M5)
- [ ] Add Settings section: Mascot preferences
- [ ] Implement frequency slider (Always/Milestones/Never)
- [ ] Implement message type toggles (Celebrations/Tips/Welcome)
- [ ] Implement tap-to-cycle-tips interaction
- [ ] Add fun facts database (rotate on tap)
- [ ] Pro feature: Custom mascot selection (🥕🥦🍞)
- [ ] Social triggers (challenge, friend, leaderboard)

---

## 10. Open Questions & Decisions Needed

### Technical
1. **Storage tip database:** ✅ **DECISION: JSON file** (easier to update, ~20-30 tips covering major categories)
2. **Recipe suggestions:** Simple keyword matching or integrate with external recipe API?
3. **Anti-spam logic:** ✅ **DECISION: 5-second minimum gap** between messages (prevents spam while allowing important alerts)
4. **Message history size:** Track last 3 messages or last 10 to prevent repeats?
5. **Message variations:** ✅ **DECISION: 5-6 variations per trigger** (prevents repetition fatigue)

### UX/Design
1. **Shake head animation:** Too negative for waste events, or playful enough?
2. **Custom mascot characters:** ✅ **DECISION: Free but unlockable** (save 50 items of category to unlock that mascot)
3. **Tap interaction:** ✅ **DECISION: Contextual tips** based on current page (most valuable UX)
4. **Landscape mode:** Completely hide Zesto, or show smaller version?
5. **Waste message tone:** ✅ **DECISION: Educational angle** (storage tips rather than just encouragement)

### Product
1. **Free vs Pro:** ✅ **DECISION: All mascot features free** (customization unlockable through gameplay, not paywall)
2. **Frequency default:** "Milestones Only" balances delight + non-intrusive, or too conservative?
3. **Disable rate:** If >30% users disable, rethink approach or just accept preference?
4. **Seasonal events:** Worth maintaining calendar logic, or focus on core triggers?

---

## 11. Appendix: Message Brainstorming

### Additional Message Ideas (Not Yet Categorized)
- "Fridge hero! 🦸"
- "Waste warrior! ⚔️"
- "Smart saver! 🧠"
- "Kitchen pro! 👨‍🍳"
- "Meal planner! 📅"
- "Budget boss! 💼"
- "Eco champion! 🏆"
- "Food rescuer! 🚑"
- "Leftover legend! 🍱"
- "Snack attack! 🍿"
- "Chef's kiss! 👨‍🍳💋"
- "Nailed it! 🔨"
- "On fire! 🔥"
- "Crushing goals! 🎯"
- "Level unlocked! 🎮"

---

**Next Steps:**
1. Review this spec with team/stakeholders
2. Prioritize Phase 1 triggers for M3 implementation
3. Create implementation issues for each phase
4. Design advanced animations (celebrate, shake, wave)
5. Build storage tip database (item category → tip mapping)
