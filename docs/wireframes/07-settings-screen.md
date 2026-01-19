# Wireframe 7: Settings Screen

## Purpose
User manages app preferences, notifications, account, and access to help resources.

## Layout
```
┌─────────────────────────────────┐
│ Settings                    ←   │  ← Back button
├─────────────────────────────────┤
│                                 │
│ ACCOUNT & DATA                  │  ← Section header
├─────────────────────────────────┤
│ 👤 Account                 →    │  ← Tap to view profile / sign in
│ 📲 Data Sync              ON   │  ← Toggle for cloud sync (future)
│ 🗑️ Clear All Data              │  ← Destructive action
├─────────────────────────────────┤
│ NOTIFICATIONS & ALERTS          │
├─────────────────────────────────┤
│ 🔔 Notifications           ON   │  ← Toggle (system level)
│ ⏰ Expiry Warning Lead Time     │
│    [3 days ▼]                  │  ← Dropdown (1, 3, 7 days)
│ 🎵 Sound                   ON   │  ← Toggle
│ 📳 Vibration               ON   │  ← Toggle
├─────────────────────────────────┤
│ PREFERENCES                     │
├─────────────────────────────────┤
│ 🌙 Dark Mode              OFF   │  ← Toggle (future)
│ 📅 Date Format                  │
│    [MM/DD/YYYY ▼]              │  ← Dropdown
│ 🍽️ Meal Planning Enabled   OFF   │  ← Feature flag
├─────────────────────────────────┤
│ SUPPORT & FEEDBACK              │
├─────────────────────────────────┤
│ ❓ Help & FAQ                   │  ← Link
│ 💬 Send Feedback               │  ← Link (email/form)
│ ⭐ Rate App                     │  ← Link (App Store)
│ 📋 View Tutorial                │  ← Re-show onboarding
├─────────────────────────────────┤
│ LEGAL                           │
├─────────────────────────────────┤
│ 📜 Privacy Policy               │  ← Link
│ ⚖️ Terms of Service            │  ← Link
│ ©️ About (v1.0.0)               │  ← Info + version
│                                 │
└─────────────────────────────────┘
```

## Components
| Component | Size | Purpose |
|-----------|------|---------|
| AppBar | 56pt | Title + back button |
| Section Header | 40pt | "ACCOUNT & DATA", "NOTIFICATIONS", etc. (gray bg) |
| Setting Row | 48pt | Setting label + toggle or dropdown |
| Toggle Switch | 28pt height | ON/OFF state |
| Dropdown | 40pt | Select option (date format, lead time) |
| Link Row | 48pt | Text link with arrow (→) |
| Divider | 1pt | Between sections |

---

## Interactions
1. **Tap Account row** → Show account info (email, sign-up date) or sign-in flow
2. **Toggle Notifications** → Enable/disable all notifications at system level
3. **Tap Expiry Warning Lead Time dropdown** → Select 1, 3, or 7 days
4. **Toggle Sound/Vibration** → Control notification feedback
5. **Toggle Dark Mode** → Switch theme (future v2)
6. **Tap Date Format dropdown** → Select MM/DD/YYYY, DD/MM/YYYY, or YYYY-MM-DD
7. **Toggle Meal Planning** → Enable meal planning features (v2+)
8. **Tap Help & FAQ** → Open in-app or web help (future)
9. **Tap Send Feedback** → Open email composer or feedback form
10. **Tap Rate App** → Open App Store / Google Play review page
11. **Tap View Tutorial** → Show onboarding flow again
12. **Tap Privacy / Terms** → Open in Safari/Chrome to external links
13. **Tap About** → Show app version, build number, legal info

---

## Account Section Details
- **Not signed in:** Show "Sign In" button, explain cloud sync benefits
- **Signed in:** Show user email, last sync time, option to sign out
- **Cloud Sync:** Save lists, preferences to backend (post-M1)
- **Data export:** Option to export inventory as CSV (v2+)

---

## Notification Settings
| Setting | Values | Default | Effect |
|---------|--------|---------|--------|
| Notifications | ON/OFF | ON | System-level permission |
| Expiry Warning | 1, 3, 7 days | 3 days | Lead time for alerts |
| Sound | ON/OFF | ON | Play notification sound |
| Vibration | ON/OFF | ON | Haptic feedback on alert |

---

## Accessibility
- [ ] All toggles ≥44pt × 44pt tap target
- [ ] Dropdowns clearly labeled with current selection
- [ ] Section headers semantic (h2 or role="heading")
- [ ] Toggle state announced (on/off, enabled/disabled)
- [ ] Links underlined or color + icon (not color-only)
- [ ] Font scales to 2x without breaking layout
- [ ] Toggle labels positioned to left or top (not floating)
- [ ] All interactive elements keyboard accessible

---

## Empty State
N/A — Settings screen always has content (toggles, dropdowns, links).

---

## Destructive Actions
| Action | Confirmation | Result |
|--------|--------------|--------|
| **Clear All Data** | "Delete all items and lists? This cannot be undone." | Wipe local database, reset app to fresh state |
| **Sign Out** | "Are you sure? Your data will remain on this device." | Clear auth token, keep local data |

---

## Feature Flags
| Flag | Purpose | M1 Status |
|------|---------|----------|
| Cloud Sync | Backend data sync | Hidden (future) |
| Dark Mode | Theme toggle | Hidden (future) |
| Meal Planning | Recipe suggestions | Hidden (future) |

---

## Telemetry Events
- `settings_opened` - {}
- `notification_toggle_changed` - {notifications_enabled: bool}
- `expiry_warning_changed` - {lead_time_days: int}
- `sound_toggle_changed` - {sound_enabled: bool}
- `vibration_toggle_changed` - {vibration_enabled: bool}
- `theme_changed` - {theme: "light" | "dark"}
- `help_tapped` - {}
- `feedback_sent` - {method: "email" | "form"}
- `rate_app_tapped` - {}
- `tutorial_reviewed` - {}
- `privacy_opened` - {}
- `terms_opened` - {}

---

## Notes
- **Notification permissions:** iOS requires explicit system permission; Android 12+ requires POST_NOTIFICATIONS permission
- **Local storage:** All settings saved to SharedPreferences (Android) or UserDefaults (iOS)
- **Sync strategy:** Settings stored locally; synced to backend when available (v2)
- **Help center:** Link to in-app or external FAQ (handled in separate issue)
- **Version display:** Auto-fetched from `pubspec.yaml` (Dart packaging)
- **Legal links:** Point to hosted privacy policy and terms of service
- **Dark mode:** Implement with Material 3 theme system (v2+)
