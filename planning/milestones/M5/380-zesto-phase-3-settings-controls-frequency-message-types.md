# 380: Zesto Phase 3 — Settings Controls (Frequency, Message Types, Enable/Disable)

**Epic:** Mascot & Gamification  
**Milestone:** M5 (Advanced Features)  
**Priority:** P2  
**Size:** S  
**Dependencies:** 350 (Zesto Phase 1)

---

## Context
Currently, Zesto appears automatically based on triggers with no user control over frequency or message types. Some users may find him delightful, while others may find him distracting. To respect user preferences, we need Settings controls to adjust or disable mascot behavior.

See full specification: `planning/docs/zesto-mascot-spec.md` (Section 7: Settings Integration)

---

## Goal
Add Settings controls for mascot frequency (Always / Milestones Only / Never), message type toggles (Celebrations / Tips / Welcome), and master enable/disable toggle, with default set to "Milestones Only" for balanced engagement.

---

## Expected behavior

### Settings Structure
**Settings → App Preferences → 🥑 Mascot**

```
🥑 Mascot (Zesto)

┌─ ☑️ Enable Mascot
│   Toggle: ON | OFF
│   Description: "Show Zesto for celebrations, tips, and reminders"
│
├─ 📊 Appearance Frequency
│   ○ Always (All events: saves, badges, tips, welcome)
│   ● Milestones Only (Badges, streaks, savings, big wins) [DEFAULT]
│   ○ Never (Completely disable)
│
└─ 💬 Message Types (only visible if frequency ≠ Never)
    ☑️ Celebrations (Saves, badges, streaks)
    ☑️ Tips & Reminders (Storage tips, expiry alerts)
    ☑️ Daily Welcome
```

### Frequency Settings
| Setting | Triggers Shown |
|---------|----------------|
| **Always** | All 10 core triggers (firstItem, consumed, wasted, quickSave, badgeUnlocked, streakMilestone, savingsMilestone, zeroWaste, dailyWelcome, expiryAlert) |
| **Milestones Only** ⭐ DEFAULT | Only: badgeUnlocked, streakMilestone (10/30/100 days), savingsMilestone ($100/$500), zeroWaste |
| **Never** | No mascot appears at all (overrides everything) |

### Message Type Toggles (when "Always" selected)
- **Celebrations:** consumed, quickSave, badgeUnlocked, streakMilestone, savingsMilestone, zeroWaste
- **Tips & Reminders:** wasted (storage tips), expiryAlert (expiring items reminder)
- **Daily Welcome:** dailyWelcome (first open each day)

### Default Configuration (for new users)
```javascript
mascot_settings: {
  enabled: true,
  frequency: "milestones", // "always", "milestones", "never"
  messageTypes: {
    celebrations: true,
    tips: true,
    welcome: true,
  }
}
```

### Behavior Logic
```
if (!mascot_settings.enabled) {
  → Never show mascot (master disable)
}

if (mascot_settings.frequency === "never") {
  → Never show mascot (same as disabled)
}

if (mascot_settings.frequency === "milestones") {
  → Only show for: badgeUnlocked, streakMilestone (10/30/100), savingsMilestone ($100/$500), zeroWaste
  → Ignore all other triggers
}

if (mascot_settings.frequency === "always") {
  → Check message type toggles:
    - If celebrations disabled: skip consumed, quickSave, badgeUnlocked, streakMilestone, savingsMilestone, zeroWaste
    - If tips disabled: skip wasted, expiryAlert
    - If welcome disabled: skip dailyWelcome
}
```

---

## Acceptance criteria (Definition of Done)

### Code Implementation
- [ ] Create `mascot_settings` localStorage object with default values:
  ```javascript
  {
    enabled: true,
    frequency: "milestones",
    messageTypes: {
      celebrations: true,
      tips: true,
      welcome: true,
    }
  }
  ```
- [ ] Update `showMascot()` to check settings before displaying:
  - If `enabled === false`, return early (don't show)
  - If `frequency === "never"`, return early
  - If `frequency === "milestones"`, filter triggers (only show major milestones)
  - If `frequency === "always"`, check message type toggles
- [ ] Implement trigger → message type mapping:
  ```javascript
  const triggerMessageTypes = {
    consumed: 'celebrations',
    quickSave: 'celebrations',
    badgeUnlocked: 'celebrations',
    streakMilestone: 'celebrations',
    savingsMilestone: 'celebrations',
    zeroWaste: 'celebrations',
    wasted: 'tips',
    expiryAlert: 'tips',
    dailyWelcome: 'welcome',
  };
  ```

### Settings UI
- [ ] Add "Mascot (Zesto)" section to Settings → App Preferences
- [ ] Add master toggle: "Enable Mascot" (ON/OFF switch)
- [ ] Add frequency radio buttons: Always / Milestones Only / Never (default: Milestones Only)
- [ ] Add message type checkboxes: Celebrations / Tips / Daily Welcome (only visible if frequency = Always)
- [ ] Disable message type checkboxes if frequency ≠ Always (grayed out)
- [ ] Update localStorage on every settings change (real-time sync)

### UI/UX
- [ ] Settings changes take effect immediately (no app restart required)
- [ ] If user disables mascot mid-appearance, current mascot dismisses gracefully
- [ ] "Milestones Only" is pre-selected for new users (balanced default)
- [ ] Tooltips explain what each frequency setting includes (hover or tap "ⓘ" icon)

### Telemetry
- [ ] `mascot_settings_changed` event fires with properties:
  - `setting_changed`: "enabled" / "frequency" / "messageTypes"
  - `new_value`: updated value
  - `previous_value`: old value
- [ ] `mascot_disabled_permanently` event fires if user sets frequency to "Never"

### Accessibility
- [ ] All toggles and radio buttons keyboard accessible (Tab, Enter, Space)
- [ ] Tooltips are screen-reader friendly (ARIA labels)
- [ ] Settings descriptions clearly explain impact ("Zesto will only appear for big achievements")

### Tests
- [ ] Unit test: Set frequency to "Never" → verify `showMascot()` returns early (no mascot)
- [ ] Unit test: Set frequency to "Milestones Only" → trigger `consumed` → verify mascot NOT shown
- [ ] Unit test: Set frequency to "Milestones Only" → trigger `badgeUnlocked` → verify mascot shown
- [ ] Unit test: Set frequency to "Always" + disable "Tips" → trigger `wasted` → verify mascot NOT shown
- [ ] Unit test: Set frequency to "Always" + enable all types → trigger `consumed` → verify mascot shown
- [ ] Widget test: Toggle master switch OFF → verify mascot dismisses if currently visible
- [ ] Integration test: Change settings → trigger event → verify settings respected

---

## Out of scope
- Per-page mascot controls ("Never show on Shopping List page") — defer to M6+
- Mascot animation speed controls — defer to M6+
- Custom frequency slider (e.g., "Show every 5th trigger") — defer to M6+
- Scheduled quiet hours ("Don't show between 10pm-7am") — defer to M6+

---

## Implementation notes

### Updated showMascot() Function
```dart
void showMascot(String messageType) {
  // Load settings
  final settings = localStorage.getMap('mascot_settings') ?? {
    'enabled': true,
    'frequency': 'milestones',
    'messageTypes': {
      'celebrations': true,
      'tips': true,
      'welcome': true,
    }
  };
  
  // Master disable check
  if (!settings['enabled'] || settings['frequency'] == 'never') {
    return; // Don't show mascot
  }
  
  // Frequency filtering
  if (settings['frequency'] == 'milestones') {
    final milestonesTriggers = [
      'badgeUnlocked',
      'streakMilestone',  // Only 10/30/100 days (filter in trigger logic)
      'savingsMilestone', // Only $100/$500 (filter in trigger logic)
      'zeroWaste',
    ];
    
    if (!milestonesTriggers.contains(messageType)) {
      return; // Not a milestone trigger, skip
    }
  }
  
  // Message type filtering (only if "Always" mode)
  if (settings['frequency'] == 'always') {
    final triggerType = triggerMessageTypes[messageType];
    if (triggerType != null && !settings['messageTypes'][triggerType]) {
      return; // User disabled this message type
    }
  }
  
  // ... (proceed with anti-spam logic, message selection, display)
}
```

### Settings UI (HTML)
```html
<div class="accordion-section">
  <div class="accordion-header" onclick="toggleAccordion(this)">
    <div>
      <div class="setting-label">🥑 Mascot (Zesto)</div>
      <div class="setting-description">Customize when Zesto appears</div>
    </div>
    <span class="accordion-chevron">›</span>
  </div>
  
  <div class="accordion-body">
    <!-- Master Toggle -->
    <div class="setting-item">
      <div class="setting-info">
        <div class="setting-name">Enable Mascot</div>
        <div class="setting-detail">Show Zesto for celebrations, tips, and reminders</div>
      </div>
      <label class="toggle-switch">
        <input type="checkbox" id="mascotEnabled" checked onchange="updateMascotSettings('enabled', this.checked)">
        <span class="toggle-slider"></span>
      </label>
    </div>
    
    <!-- Frequency Radio Buttons -->
    <div class="setting-item">
      <div class="setting-info">
        <div class="setting-name">Appearance Frequency</div>
      </div>
      <div class="radio-group">
        <label class="radio-item">
          <input type="radio" name="mascotFrequency" value="always" onchange="updateMascotSettings('frequency', 'always')">
          <span>Always</span>
          <div class="radio-detail">All events: saves, badges, tips, welcome</div>
        </label>
        <label class="radio-item">
          <input type="radio" name="mascotFrequency" value="milestones" checked onchange="updateMascotSettings('frequency', 'milestones')">
          <span>Milestones Only</span>
          <div class="radio-detail">Badges, streaks, savings, big wins</div>
        </label>
        <label class="radio-item">
          <input type="radio" name="mascotFrequency" value="never" onchange="updateMascotSettings('frequency', 'never')">
          <span>Never</span>
          <div class="radio-detail">Completely disable mascot</div>
        </label>
      </div>
    </div>
    
    <!-- Message Type Toggles (only visible if frequency = always) -->
    <div class="setting-item" id="messageTypesSection" style="display: none;">
      <div class="setting-info">
        <div class="setting-name">Message Types</div>
      </div>
      <div class="checkbox-group">
        <label class="checkbox-item">
          <input type="checkbox" checked onchange="updateMascotMessageType('celebrations', this.checked)">
          <span>Celebrations (Saves, badges, streaks)</span>
        </label>
        <label class="checkbox-item">
          <input type="checkbox" checked onchange="updateMascotMessageType('tips', this.checked)">
          <span>Tips & Reminders (Storage tips, expiry alerts)</span>
        </label>
        <label class="checkbox-item">
          <input type="checkbox" checked onchange="updateMascotMessageType('welcome', this.checked)">
          <span>Daily Welcome</span>
        </label>
      </div>
    </div>
  </div>
</div>

<script>
function updateMascotSettings(setting, value) {
  const settings = JSON.parse(localStorage.getItem('mascot_settings')) || {};
  const previousValue = settings[setting];
  settings[setting] = value;
  localStorage.setItem('mascot_settings', JSON.stringify(settings));
  
  // Show/hide message types section
  if (setting === 'frequency') {
    document.getElementById('messageTypesSection').style.display = 
      value === 'always' ? 'block' : 'none';
  }
  
  // Dismiss active mascot if disabled
  if ((setting === 'enabled' && !value) || (setting === 'frequency' && value === 'never')) {
    dismissMascot();
  }
  
  // Telemetry
  logEvent('mascot_settings_changed', {
    setting_changed: setting,
    new_value: value,
    previous_value: previousValue,
  });
}

function updateMascotMessageType(type, enabled) {
  const settings = JSON.parse(localStorage.getItem('mascot_settings')) || {};
  settings.messageTypes = settings.messageTypes || {};
  settings.messageTypes[type] = enabled;
  localStorage.setItem('mascot_settings', JSON.stringify(settings));
  
  logEvent('mascot_settings_changed', {
    setting_changed: `messageTypes.${type}`,
    new_value: enabled,
  });
}
</script>
```

### CSS for Settings UI
```css
.radio-group {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 12px;
}

.radio-item {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px;
  background: #f8f9fa;
  border-radius: 8px;
  cursor: pointer;
}

.radio-item input[type="radio"] {
  margin-top: 2px;
}

.radio-item span {
  font-weight: 500;
  color: #333;
}

.radio-detail {
  font-size: 12px;
  color: #666;
  margin-top: 4px;
}

.checkbox-group {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-top: 12px;
}

.checkbox-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px;
  cursor: pointer;
}

.checkbox-item input[type="checkbox"] {
  width: 18px;
  height: 18px;
}
```

---

## Test plan

### Automated tests

**Unit tests (frequency filtering):**
1. Unit test: Set frequency to "Never" → trigger any event → verify mascot NOT shown
2. Unit test: Set frequency to "Milestones Only" → trigger `consumed` → verify mascot NOT shown
3. Unit test: Set frequency to "Milestones Only" → trigger `badgeUnlocked` → verify mascot shown
4. Unit test: Set frequency to "Milestones Only" → trigger `streakMilestone` (5 days) → verify mascot NOT shown (not milestone)
5. Unit test: Set frequency to "Milestones Only" → trigger `streakMilestone` (10 days) → verify mascot shown

**Unit tests (message type filtering):**
6. Unit test: Set frequency to "Always" + disable "Celebrations" → trigger `consumed` → verify mascot NOT shown
7. Unit test: Set frequency to "Always" + disable "Tips" → trigger `wasted` → verify mascot NOT shown
8. Unit test: Set frequency to "Always" + disable "Welcome" → trigger `dailyWelcome` → verify mascot NOT shown
9. Unit test: Set frequency to "Always" + enable all types → trigger `consumed` → verify mascot shown

**Widget tests (UI):**
10. Widget test: Toggle master switch OFF → verify mascot dismisses if currently visible
11. Widget test: Select "Never" frequency → verify message type checkboxes grayed out (disabled)
12. Widget test: Select "Always" frequency → verify message type checkboxes become active

**Telemetry tests:**
13. Unit test: Change frequency setting → verify `mascot_settings_changed` event fires
14. Unit test: Toggle message type → verify `mascot_settings_changed` event fires

### Manual testing

**Frequency filtering:**
1. Set frequency to "Never" → add item → verify mascot doesn't appear
2. Set frequency to "Milestones Only" → consume item → verify mascot doesn't appear
3. Set frequency to "Milestones Only" → earn badge → verify mascot DOES appear
4. Set frequency to "Always" → consume item → verify mascot appears

**Message type filtering:**
5. Set frequency to "Always" → uncheck "Celebrations" → consume item → verify mascot doesn't appear
6. Set frequency to "Always" → uncheck "Tips" → waste item → verify storage tip doesn't appear
7. Set frequency to "Always" → uncheck "Welcome" → open app → verify daily welcome doesn't appear
8. Set frequency to "Always" → check all types → verify all triggers work

**Settings UI:**
9. Toggle master switch OFF → verify mascot dismisses immediately if visible
10. Change frequency while mascot visible → verify mascot respects new setting on next trigger
11. Select "Milestones Only" → verify message type checkboxes are grayed out (disabled)
12. Select "Always" → verify message type checkboxes become active

**Persistence:**
13. Set frequency to "Never" → close app → reopen → verify setting persisted (no mascot)
14. Set message types to custom config → close app → reopen Settings → verify checkboxes reflect saved state

**Edge cases:**
15. Rapidly toggle settings while mascot visible → verify no visual glitches
16. Set frequency to "Milestones Only" → trigger 20 regular events → verify mascot never appears (prevents spam)

---

## Dependencies
- **350:** Zesto Phase 1 — Core triggers (must be implemented first)

---

## Related issues
- **350:** Zesto Phase 1 — Core triggers (prerequisite)
- **370:** Zesto Phase 3 — Tap-to-cycle tips (parallel feature)
- **375:** Zesto Phase 3 — Unlockable mascots (parallel feature)

---

## Milestone placement: M5 (Advanced Features)
This is a **user control feature** that respects diverse preferences. Not required for MVP, but important for launch readiness to avoid alienating users who find mascots distracting. M5 is appropriate for this polish.
