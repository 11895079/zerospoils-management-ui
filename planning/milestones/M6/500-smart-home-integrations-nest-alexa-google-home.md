# M6-500: Smart Home Integrations — Nest, Alexa, Google Home

**Status:** Planning  
**Milestone:** M6 (Pro Tier Features)  
**Priority:** P1 (Differentiator)  
**Effort:** L (Large — 3 sub-features)  
**Labels:** `pro-tier`, `integrations`, `smart-home`, `iot`

## Context

Smart home integrations add convenience and ambient awareness:
- **Nest/smart thermostat:** Temperature alerts indicate when fridge/pantry conditions might affect food (e.g., "Temp 22°C — check your dairy!")
- **Alexa:** Voice-enabled shopping list (read items from ZeroSpoils, add while cooking)
- **Google Home:** Display expiry items on Smart Display; set reminders for foods to use

These features justify Pro tier subscription and deepen household engagement.

## Goal

Integrate ZeroSpoils with three major smart home ecosystems to:
- Provide ambient awareness (temp alerts → food impact)
- Enable voice-driven workflows (Alexa shopping list)
- Display actionable info on screens (Google Home expiry tab)
- Reduce friction for household members managing food together

## Expected Behavior

### 1. Google Nest / Smart Thermostat Integration

**Feature:** Temperature-based alerts notify users when conditions might affect food

**Trigger:**
- If thermostat temp > 20°C for 2+ hours → alert: "Room temp high — check perishables!"
- If thermostat temp < 15°C for 2+ hours → alert: "Cold weather — ideal for pantry items"
- Used to contextualize waste risk (warm temps = dairy expires faster)

**Implementation:**
- Connect via Google Home API (OAuth + smart home device access)
- Poll thermostat every 30 min or subscribe to temperature change events
- Store temp readings (privacy: local only, not shared)
- Display in app: "Based on your home's temp (22°C), dairy items expire 1-2 days earlier"

**Pro Tier Gating:**
- Free tier: No temp integration
- Pro tier: Full feature + historical temp trend (past 30 days)

---

### 2. Amazon Alexa Integration — Shopping List Sync

**Feature:** Alexa reads items from ZeroSpoils shopping list; users can add via voice

**Workflows:**

*Outbound (ZeroSpoils → Alexa):*
- Sync shopping list to Alexa Lists API
- When user adds item in ZeroSpoils, appears in "Alexa Shopping" list within 2-5 sec
- Alexa can read list: "Alexa, show my shopping list" → "Milk, eggs, bread..."

*Inbound (Alexa → ZeroSpoils):*
- User voice command: "Alexa, add milk to ZeroSpoils shopping list"
- Alexa adds to native list (via ZeroSpoils Alexa Skill)
- Item syncs back to app

**Voice Commands Enabled:**
- "Alexa, add milk to ZeroSpoils" → item added to shopping list
- "Alexa, read my ZeroSpoils shopping list" → Alexa speaks items
- "Alexa, mark eggs as purchased on ZeroSpoils" → mark item (future enhancement)

**Implementation:**
- Create custom Alexa Skill (Amazon Developer Portal)
- Use Alexa Lists API for bidirectional sync
- OAuth for account linking (user logs in via Alexa app → connects to ZeroSpoils)
- Store Alexa device ID + user token for push updates

**Pro Tier Gating:**
- Free tier: No Alexa integration
- Pro tier: Full shopping list sync + voice commands

---

### 3. Google Home / Smart Display Integration

**Feature:** Show expiry tab + reminders on Google Home Hub / Nest Hub Max

**Workflows:**

*Primary (Display):*
- "Hey Google, show me my ZeroSpoils" → Smart Display shows:
  - Items expiring today (red)
  - Items expiring this week (yellow)
  - Quick summary: "3 items expire today"
- Layout: Large card with emoji, item name, expiry time, urgency color

*Secondary (Voice Reminders):*
- Set routine: "Every morning at 8 AM, remind me what expires today"
- Google Assistant reads: "You have 3 items expiring today: milk, carrots, yogurt"
- User can say: "Add milk to shopping list" → syncs back to ZeroSpoils

*Tertiary (Calendar Integration):*
- Optional: Sync expiry dates to Google Calendar
- User sees expiry events on calendar alongside other appointments
- Calendar event includes item name + "days until expiry"
- Example: "🥛 Milk expires in 2 days"

**Implementation:**
- Create Google Home Action (Actions on Google console)
- Use Google Home Graph API for display content
- OAuth for account linking
- Fetch expiry items via API call when user asks
- Calendar sync via Calendar API (optional, user opt-in per event)

**Pro Tier Gating:**
- Free tier: No Google Home integration
- Pro tier: Full display + voice reminders + calendar sync (optional)

---

## Acceptance Criteria

### Google Nest/Thermostat
- [ ] OAuth connection to Google Home
- [ ] Thermostat temperature polling (30-min interval)
- [ ] Alert triggered when temp > 20°C or < 15°C (configurable)
- [ ] Alert displayed in app with context
- [ ] Pro tier feature flag enabled
- [ ] Privacy: Temperature stored locally only (not synced to server)
- [ ] Tests: Unit test for alert logic; integration test for OAuth flow
- [ ] Accessibility: Alerts readable by screen reader

### Alexa Shopping List
- [ ] Alexa Skill created and published
- [ ] OAuth account linking working
- [ ] Outbound sync: ZeroSpoils item → Alexa Lists (latency < 5 sec)
- [ ] Inbound sync: Alexa voice command → ZeroSpoils shopping list
- [ ] Voice commands: "Alexa, add [item] to ZeroSpoils"
- [ ] Pro tier feature flag enabled
- [ ] Analytics: Track voice command usage (item added, list read)
- [ ] Tests: Integration test with Alexa simulator; E2E test on real device

### Google Home Display
- [ ] Google Action created and published
- [ ] Display card renders with correct layout (expiry items, colors)
- [ ] Voice command works: "Show my ZeroSpoils"
- [ ] Reminder routine can be set (user creates via Google Home app)
- [ ] Calendar sync (optional): Expiry dates appear on Google Calendar
- [ ] Pro tier feature flag enabled
- [ ] Analytics: Track display shows, voice commands, calendar syncs
- [ ] Tests: Integration test with Actions on Google simulator; E2E on Nest Hub

### Cross-Feature
- [ ] All features require Pro tier (free tier users see "Upgrade to enable")
- [ ] Disconnection: User can revoke access via app settings
- [ ] No personal data sent to third parties (only shopping list, expiry times, temp readings)
- [ ] Rate limiting: API calls throttled to prevent abuse
- [ ] Error handling: Graceful degradation if API unavailable

## Out of Scope

- Apple Home / HomeKit integration (M7, separate iOS-only feature)
- IFTTT / Zapier (automation platform, future enhancement)
- Advanced automations (e.g., "If dairy expires today, send SMS") — M7
- Multi-home support (multiple houses per account) — M7

## Implementation Notes

### Authentication Pattern (All 3)

```dart
// Generic smart home auth flow
class SmartHomeService {
  Future<void> connectToGoogleHome() async {
    // 1. Launch OAuth in browser
    final result = await _launchGoogleOAuth();
    
    // 2. Store tokens securely
    await _secureStorage.saveToken('google_home_token', result.token);
    
    // 3. Fetch and store home ID + device IDs
    final devices = await _fetchGoogleHomeDevices();
    await _db.saveGoogleHomeDevices(devices);
  }

  Future<void> disconnectFromGoogleHome() async {
    // 1. Revoke OAuth token
    await _revokeGoogleOAuthToken();
    
    // 2. Clear local data
    await _secureStorage.deleteToken('google_home_token');
    await _db.clearGoogleHomeDevices();
  }
}
```

### Theming / Privacy Controls

```dart
// User settings for smart home features
class SmartHomeSettings {
  bool nestTempAlertsEnabled = true;
  bool alexaShoppingListSync = true;
  bool googleHomeDisplay = true;
  bool googleCalendarSync = false; // Opt-in calendar

  // What data to share
  bool shareShoppingListWithAlexaHousehold = true;
  bool shareExpiryWithGoogleHome = true;
}
```

### API Limits & Rate Limiting

- **Nest:** 1 query per 30 min (free tier)
- **Alexa:** 10 list updates per minute (standard)
- **Google Home:** 5 action requests per minute (standard)
- Implement local caching to stay within limits

## Test Plan

**Automated:**
- Unit test: OAuth token refresh logic
- Unit test: Temp alert trigger conditions (> 20°C, < 15°C)
- Unit test: Alexa list sync (item added → Alexa payload generated)
- Integration test: OAuth flow with mock APIs
- Integration test: Thermostat polling + alert dispatch

**Manual:**
1. **Nest:** Connect account → set temp > 20°C → wait 30 min → alert appears
2. **Alexa:** 
   - Add item in ZeroSpoils → open Alexa app → verify item appears in list
   - Say "Alexa, add carrots to ZeroSpoils" → check app → item appears
3. **Google Home:** 
   - Connect account → ask "Hey Google, show my ZeroSpoils" → Display Hub shows expiry card
   - Set morning routine reminder → test on real device
   - (Optional) Sync calendar → check Google Calendar for expiry events
4. **Disconnect:** Revoke access in app → verify no data sent to APIs
5. **Error handling:** Unplug Nest → verify app handles gracefully (no crashes)

## Dependencies

- **Pro Tier Gate** (Issue 130): Feature flag framework to restrict to Pro users
- **OAuth Setup** (M5): Secure token storage + refresh logic
- **Cloud API Infrastructure** (M5): Backend endpoints for OAuth callback, token exchange
- **Household Sync** (Issue 470): Pro tier requires cloud backend for syncing to other devices

## Related Issues

- **Issue 130:** Feature flags (gate smart home behind Pro tier)
- **Issue 470:** Household accounts (Pro tier users want to share smart home displays)
- **Issue 500:** Advanced automations (M7, builds on this)
- **Issue 510:** Apple Home (M7, HomeKit integration for iOS)

---

## Monetization Impact

- **Differentiator:** Smart home integration is rare in food waste apps (major competitive advantage)
- **Household stickiness:** Families with Alexa/Google Home will depend on app daily
- **Pro tier upgrade driver:** "Free for 14 days, then $2.99/month" messaging for smart home features
- **Cross-sell:** Lead Nest/Alexa/Google users to Pro tier conversion

**Success:** Pro tier users integrate ZeroSpoils into their daily routines via voice & ambient displays; engagement increases; churn decreases.
