# Wireframe 5: Onboarding Flow

## Purpose
First-time users are guided through welcome, permissions, and quick tutorial to understand core features.

## Layout - Screen 1: Welcome

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│         🌱 ZeroSpoils          │  ← App logo/icon
│                                 │
│     "Reduce household food      │  ← Tagline
│      waste, save money"         │
│                                 │
│                                 │
│       [Get Started] (blue)      │  ← Primary CTA
│       [Learn More] (secondary)  │  ← Secondary link
│                                 │
│                                 │
└─────────────────────────────────┘
```

### Screen 1 Details
- **Hero image:** App icon or illustration (seedling/leaf)
- **Headline:** "ZeroSpoils"
- **Tagline:** Short benefit statement
- **Primary button:** "Get Started" (leads to Screen 2)
- **Secondary link:** "Learn More" (opens in browser or tooltip)
- **Skip button:** (optional, top-right) "Skip Tutorial"

---

## Layout - Screen 2: Permissions Request

```
┌─────────────────────────────────┐
│                                 │
│      📱 Enable Notifications    │
│                                 │
│    "Get reminders when items    │  ← Description
│     are about to expire"        │
│                                 │
│                                 │
│       [Allow]    [Skip]         │  ← Buttons (Allow primary)
│                                 │
│                                 │
│    ◦ Notifications ✓            │  ← Progress indicators (dot 2 of 3)
│    ◦ Permissions (next)         │
│    ◦ Ready to go                │
│                                 │
└─────────────────────────────────┘
```

### Screen 2 Details
- **Permission request:** Notifications (iOS: UNUserNotificationCenter, Android: POST_NOTIFICATIONS)
- **Headline:** "Enable Notifications"
- **Explanation:** Benefit of notifications
- **Primary button:** "Allow" (requests permission)
- **Secondary button:** "Skip" (continues to Screen 3)
- **Progress indicator:** 3 dots showing position in flow

---

## Layout - Screen 3: Quick Tutorial

```
┌─────────────────────────────────┐
│                                 │
│    ✨ Here's How It Works      │
│                                 │
│  1️⃣ Add items you buy          │  ← Step with emoji
│     (e.g., Milk, Spinach)      │
│                                 │
│  2️⃣ See expiry warnings        │  ← Step with emoji
│     when items expire soon      │
│                                 │
│  3️⃣ Plan meals & shopping      │  ← Step with emoji
│     to reduce waste             │
│                                 │
│                                 │
│    [Start Using App] (blue)     │  ← Primary CTA
│                                 │
│    ◦ Notifications              │  ← Progress (3 of 3)
│    ◦ Permissions                │
│    ◦ Ready to go ✓              │
│                                 │
└─────────────────────────────────┘
```

### Screen 3 Details
- **Headline:** "Here's How It Works"
- **Steps:** 3 key actions shown with emoji + text
- **Primary button:** "Start Using App" (closes onboarding, shows home)
- **Progress indicator:** Step 3 complete
- **Optional:** Skip button if user clicks back (return to previous step)

---

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| Hero image | 120pt × 120pt | Logo or illustration |
| Headline | 24pt, semi-bold | Screen title |
| Body text | 14pt, regular | Description, steps |
| Button (Primary) | 48pt height | Main action (Allow, Start) |
| Button (Secondary) | 48pt height | Alternative action (Skip, Learn More) |
| Progress indicator | 8pt dots | Show position in 3-screen flow |
| Step number | 20pt emoji | Visual for each tutorial step |

---

## Interactions
1. **Screen 1 → Get Started** → Proceed to Screen 2
2. **Screen 1 → Learn More** → Open Safari/Chrome to website (out-of-app)
3. **Screen 2 → Allow** → Request notification permission (native OS dialog), proceed to Screen 3
4. **Screen 2 → Skip** → Skip permission, proceed to Screen 3
5. **Screen 3 → Start Using App** → Close onboarding, show home screen (Inventory)
6. **Back button** → Return to previous screen (or close if on Screen 1)
7. **Skip Tutorial** (any screen) → Jump to home immediately

---

## Accessibility
- [ ] All buttons ≥44pt × 44pt tap target
- [ ] Skip button labeled and easily discoverable
- [ ] Text readable (16pt+) without zoom
- [ ] Heading level semantic structure (h1, h2)
- [ ] Permission text is clear and non-coercive
- [ ] Step numbers use emoji + text (not emoji-only)
- [ ] Progress dots meaningful (alternative text or labeled)
- [ ] Font scales to 2x without breaking layout
- [ ] Color not sole indicator (text + emoji for steps)

---

## Empty State
N/A — Onboarding only appears first time, no empty state needed.

---

## Telemetry Events
- `onboarding_started` - {timestamp, source: "first_launch" | "manual"}
- `onboarding_screen_viewed` - {screen: 1 | 2 | 3}
- `onboarding_permission_requested` - {permission: "notifications", granted: bool}
- `onboarding_completed` - {duration_seconds: int, skipped: bool}
- `onboarding_skipped` - {screen: int, reason: "skip_button" | "back"}

---

## Notes
- **iOS:** Request APNS (Apple Push Notification service) after Screen 2
- **Android:** Use WorkManager or Firebase Cloud Messaging for notifications post-M1
- **Gating:** Show only on first app launch (check `SharedPreferences.hasSeenOnboarding()` or equivalent)
- **Skip option:** Advanced users can skip tutorial from any screen
- **Manual re-trigger:** Add "View Tutorial" in Settings (future) to re-show onboarding
- **Accessibility:** Provide text descriptions for all emoji (screen readers)
- **Performance:** Preload images before showing onboarding flow
