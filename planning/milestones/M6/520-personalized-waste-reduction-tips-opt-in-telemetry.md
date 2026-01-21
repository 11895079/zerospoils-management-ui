# Issue 520: Personalized Waste Reduction Tips (Pro Tier, Opt-In Telemetry)

**Milestone:** M6 (Pro Tier Features)  
**Priority:** P2 (Enhancement, not core Pro launch)  
**Effort:** M (Medium — backend analysis + tip generation logic)  
**Labels:** `pro-tier`, `analytics`, `personalization`, `telemetry-required`, `privacy-sensitive`  
**Dependencies:** Issue 040 (telemetry taxonomy), Issue 470 (cloud sync), Issue 490 (advanced analytics)

---

## Context

Free users get local waste tracking and basic analytics, but no personalized recommendations. Pro users opt-in to telemetry to receive AI-powered tips based on THEIR specific waste patterns. This feature justifies Pro tier pricing by delivering actionable, personalized insights that genuinely help users reduce waste.

**Key Privacy Principle:** Tips require explicit opt-in. Free users = zero telemetry, fully offline. Pro users = optional telemetry with clear value prop ("Get personalized tips based on YOUR waste patterns").

---

## Goal

Enable Pro users to receive weekly personalized waste reduction tips generated from analysis of their waste events (category, reason, frequency patterns). Tips are actionable, timely, and delivered via push notification or in-app banner.

---

## Expected behavior

### Opt-In Flow (First-Time Pro User)

1. **After Pro Upgrade:** User subscribes to Pro tier
2. **Prompt Appears:** "Enable Personalized Tips?"
   - **Title:** "Get Smarter About Reducing Waste"
   - **Body:** "We'll analyze your waste patterns (locally + cloud) to suggest improvements. For example: 'You waste dairy most often — try buying smaller quantities.' No personal data (item names, locations) is shared."
   - **Buttons:** [Enable Tips] [Not Now]
3. **If User Taps "Enable Tips":**
   - Settings → Privacy → Personalized Tips: **ON**
   - Telemetry consent flag set: `telemetry_consent: true`
   - Weekly tip generation begins (first tip delivered after 7 days of data)
4. **If User Taps "Not Now":**
   - Tips remain disabled
   - User can enable later in Settings → Privacy

### Tip Generation Logic (Backend)

**Data Inputs (Anonymized):**
- Waste events from last 30 days:
  - `category` (e.g., "dairy", "produce", "meat")
  - `reason` (e.g., "expired", "spoiled", "forgotten")
  - `waste_percentage` (e.g., 50%, 100%)
  - `timestamp` (to detect patterns: weekends, specific days)

**Pattern Analysis:**
1. **Most Wasted Category:** Identify category with highest waste count
   - Example: 5 dairy items wasted in 30 days → "You waste dairy most often"
2. **Common Waste Reason:** Group by reason
   - Example: 80% of waste is "expired" → "Items expire before you use them"
3. **Temporal Patterns:** Detect weekday/weekend patterns
   - Example: 60% of waste happens Monday-Tuesday → "Leftovers from weekend meals go bad"
4. **Success Patterns:** Identify improvements
   - Example: Waste reduced 10% this month → "You've reduced waste by 10%! Keep it up."

**Tip Generation Rules:**
- **Actionable:** Every tip includes a concrete suggestion (not just "reduce waste")
- **Positive Tone:** Frame as encouragement, not criticism
- **Specific:** Reference user's actual patterns (category, reason)
- **Weekly Cadence:** One tip per week (not overwhelming)

**Example Tips:**
- **High Dairy Waste:** "You've wasted dairy 3 times this month. Try buying smaller quantities (e.g., 1 pint milk instead of half-gallon)."
- **Produce Expires:** "Produce expires fastest for you. Consider meal planning on Sundays to use all your greens and veggies."
- **Weekend Leftovers:** "Leftovers from weekend meals often go bad. Store in clear containers with 'Eat by [date]' labels."
- **Success Story:** "Great job! You've reduced waste by 12% this month. You're saving $8 and avoiding 3kg CO₂."
- **Temperature Alert (if Nest connected):** "Your fridge temp is 20°C (too high). Lower to 3-5°C to extend food freshness."

### Tip Delivery Mechanisms

**1. Push Notification (Weekly)**
- **Trigger:** Every Monday at 9 AM (user's local time)
- **Content:** Tip title (e.g., "💡 Tip: Reduce dairy waste")
- **Tap Action:** Opens tip detail page in app

**2. In-App Banner (Home Screen)**
- **Placement:** Top of Inventory tab (dismissible)
- **Visual:** Light blue banner with 💡 icon
- **Content:** Full tip text (2-3 sentences)
- **Actions:** [Dismiss] [View History]

**3. Tip History Page**
- **Location:** Settings → Personalized Tips → History
- **Content:** List of all tips received (ordered by date, newest first)
- **Interaction:** Tap tip to expand and see full text

### Settings & Privacy Controls

**Settings → Privacy → Personalized Tips**
- **Toggle:** ON / OFF (default: OFF for new users)
- **Description:** "Analyze waste patterns to suggest improvements. Requires cloud sync of anonymized waste events (category, reason, frequency — no item names or locations)."
- **Data Usage:** "Used: [5.2 MB] over last 30 days"
- **[View Tip History]** → Opens history page
- **[Delete My Data]** → Deletes all telemetry (irreversible, disables tips)

**When User Disables Tips:**
- **Confirmation Dialog:** "Disable personalized tips? Your waste data will no longer be analyzed. You can re-enable anytime."
- **Actions:** [Disable Tips] [Cancel]
- **Effect:** Telemetry stops, no new tips generated, existing tips remain in history

---

## Acceptance criteria (Definition of Done)

**Backend (Tip Generation Service):**
- [x] Pattern analysis algorithm implemented (most wasted category, common reasons, temporal patterns)
- [x] Tip generation logic with rules (actionable, positive, specific, weekly cadence)
- [x] Weekly cron job scheduled (Monday 9 AM, user's local timezone)
- [x] Tip delivery via push notification + in-app banner
- [x] Tip storage (user's tip history persisted in cloud DB)

**Frontend (Opt-In Flow):**
- [x] Pro upgrade triggers opt-in prompt ("Enable Personalized Tips?")
- [x] Prompt UI matches design tokens (gradient, spacing, typography)
- [x] "Enable Tips" → Sets `telemetry_consent: true`, syncs to backend
- [x] "Not Now" → Dismisses prompt, user can enable in Settings later

**Frontend (Tip Display):**
- [x] Push notification opens tip detail page on tap
- [x] In-app banner displayed on Inventory tab (top, dismissible)
- [x] Banner shows tip text (2-3 sentences, 💡 icon)
- [x] Banner dismiss action persists (don't show same tip again)

**Settings & Privacy:**
- [x] Settings → Privacy → Personalized Tips toggle (ON/OFF)
- [x] Toggle description explains data usage (anonymized waste events)
- [x] "View Tip History" opens history page (all tips, ordered by date)
- [x] "Delete My Data" button with confirmation dialog (irreversible)
- [x] Disabling tips stops telemetry, keeps existing history

**Data Privacy:**
- [x] Telemetry is opt-in only (default: OFF for all users)
- [x] No PII in telemetry (no item names, dates, locations)
- [x] Anonymized data only: category, reason, waste %, timestamp
- [x] User can delete all telemetry data anytime (irreversible)

**Tests:**
- [x] Unit test: Pattern analysis logic (most wasted category, common reasons)
- [x] Unit test: Tip generation rules (actionable, positive, specific)
- [x] Integration test: Opt-in flow (enable/disable, settings sync)
- [x] Integration test: Tip delivery (push notification, banner display)
- [x] E2E test: User enables tips → Waits 7 days → Receives first tip
- [x] Privacy test: Disabled tips = zero telemetry sent to backend

**Telemetry (Instrumentation):**
- [x] Event: `tips_opt_in_shown` (properties: `user_id`, `pro_tier: true`)
- [x] Event: `tips_enabled` (properties: `user_id`, `timestamp`)
- [x] Event: `tips_disabled` (properties: `user_id`, `timestamp`, `reason`)
- [x] Event: `tip_delivered` (properties: `user_id`, `tip_id`, `tip_category`, `delivery_method: [notification|banner]`)
- [x] Event: `tip_viewed` (properties: `user_id`, `tip_id`, `view_duration_seconds`)
- [x] Event: `tip_dismissed` (properties: `user_id`, `tip_id`)
- [x] Event: `tip_history_viewed` (properties: `user_id`, `tip_count`)

**Offline-First Behavior:**
- [x] Tips cached locally (work offline after first sync)
- [x] New tips sync when online (silent background fetch)
- [x] Disabling tips works offline (syncs when online)

**Accessibility:**
- [x] Opt-in prompt: Screen reader announces title + body text
- [x] Banner: Dismissible via keyboard (ESC key)
- [x] Tip history: Navigate with arrow keys, tap targets ≥44pt
- [x] Push notification: VoiceOver reads tip text

---

## Out of scope

- **Community Tips (M7+):** Anonymized tips from other users ("People who reduced dairy waste did X")
- **Tip Categories (M7+):** Filter tips by category (dairy, produce, leftovers, budgeting)
- **Tip Rating (M7+):** User can rate tips (helpful/not helpful) to improve algorithm
- **Multi-Language Tips (M7+):** Localize tips for non-English users
- **Tip Push Frequency Control (M7+):** User can adjust cadence (weekly, biweekly, monthly)

---

## Implementation notes

### Backend Architecture

**Tip Generation Service (Python/Node.js):**
```python
class TipGenerator:
    def generate_weekly_tip(user_id: str) -> Tip:
        # 1. Fetch waste events (last 30 days)
        waste_events = fetch_waste_events(user_id, days=30)
        
        # 2. Analyze patterns
        most_wasted_category = analyze_most_wasted(waste_events)
        common_reason = analyze_common_reason(waste_events)
        temporal_pattern = analyze_temporal_pattern(waste_events)
        
        # 3. Generate tip based on priority
        if most_wasted_category:
            return generate_category_tip(most_wasted_category)
        elif common_reason == "expired":
            return generate_expiry_tip()
        elif temporal_pattern == "weekends":
            return generate_leftover_tip()
        else:
            return generate_encouragement_tip(waste_events)
    
    def generate_category_tip(category: str) -> Tip:
        templates = {
            "dairy": "You've wasted dairy {count} times this month. Try buying smaller quantities (e.g., 1 pint milk instead of half-gallon).",
            "produce": "Produce expires fastest for you. Consider meal planning on Sundays to use all your greens and veggies.",
            # ...more templates
        }
        return Tip(
            id=generate_uuid(),
            title=f"💡 Tip: Reduce {category} waste",
            text=templates[category].format(count=3),
            category=category,
            created_at=now()
        )
```

**Cron Job (Weekly Delivery):**
```python
# Runs every Monday at 9 AM (user's local timezone)
@cron("0 9 * * MON")
def deliver_weekly_tips():
    pro_users = fetch_pro_users_with_tips_enabled()
    for user in pro_users:
        tip = TipGenerator.generate_weekly_tip(user.id)
        send_push_notification(user.id, tip.title, tip.text)
        save_tip_to_history(user.id, tip)
        track_event("tip_delivered", {
            "user_id": user.id,
            "tip_id": tip.id,
            "tip_category": tip.category,
            "delivery_method": "notification"
        })
```

### Frontend Architecture (Flutter)

**Opt-In Prompt Widget:**
```dart
class TipsOptInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Get Smarter About Reducing Waste"),
      content: Text(
        "We'll analyze your waste patterns (locally + cloud) to suggest improvements. "
        "For example: 'You waste dairy most often — try buying smaller quantities.' "
        "No personal data (item names, locations) is shared."
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await TipsService.enableTips();
            TelemetryService.track("tips_enabled", {
              "user_id": currentUser.id,
              "timestamp": DateTime.now().toIso8601String()
            });
            Navigator.of(context).pop();
          },
          child: Text("Enable Tips"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Not Now"),
        ),
      ],
    );
  }
}
```

**In-App Banner Widget:**
```dart
class TipBanner extends StatelessWidget {
  final Tip tip;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFE3F2FD), // Light blue
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text("💡", style: TextStyle(fontSize: 24)),
          SizedBox(width: 12),
          Expanded(
            child: Text(tip.text, style: TextStyle(fontSize: 14)),
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              TipsService.dismissTip(tip.id);
              TelemetryService.track("tip_dismissed", {
                "user_id": currentUser.id,
                "tip_id": tip.id
              });
            },
          ),
        ],
      ),
    );
  }
}
```

**Settings → Privacy → Personalized Tips:**
```dart
class PersonalizedTipsSettings extends StatefulWidget {
  @override
  _PersonalizedTipsSettingsState createState() => _PersonalizedTipsSettingsState();
}

class _PersonalizedTipsSettingsState extends State<PersonalizedTipsSettings> {
  bool _tipsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadTipsPreference();
  }

  Future<void> _loadTipsPreference() async {
    final enabled = await TipsService.isTipsEnabled();
    setState(() => _tipsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text("Personalized Tips"),
      subtitle: Text(
        "Analyze waste patterns to suggest improvements. "
        "Requires cloud sync of anonymized waste events (category, reason, frequency)."
      ),
      trailing: Switch(
        value: _tipsEnabled,
        onChanged: (enabled) async {
          if (enabled) {
            await TipsService.enableTips();
            TelemetryService.track("tips_enabled", {"user_id": currentUser.id});
          } else {
            final confirmed = await _showDisableConfirmation();
            if (confirmed) {
              await TipsService.disableTips();
              TelemetryService.track("tips_disabled", {
                "user_id": currentUser.id,
                "reason": "user_disabled"
              });
            }
          }
          setState(() => _tipsEnabled = enabled);
        },
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TipHistoryPage()),
      ),
    );
  }

  Future<bool> _showDisableConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Disable personalized tips?"),
        content: Text(
          "Your waste data will no longer be analyzed. "
          "You can re-enable anytime."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("Disable Tips"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("Cancel"),
          ),
        ],
      ),
    ) ?? false;
  }
}
```

### Privacy Validation (Unit Test)

```dart
void testTipContentIsAnonymized() {
  final waste_events = [
    WasteEvent(itemName: "Milk", category: "dairy", reason: "expired"),
    WasteEvent(itemName: "Yogurt", category: "dairy", reason: "spoiled"),
  ];
  
  final tip = TipGenerator.generateCategoryTip("dairy", waste_events);
  
  // Assert: Tip text contains NO item names
  expect(tip.text.contains("Milk"), isFalse);
  expect(tip.text.contains("Yogurt"), isFalse);
  
  // Assert: Tip text contains only category and actionable advice
  expect(tip.text.contains("dairy"), isTrue);
  expect(tip.text.contains("smaller quantities"), isTrue);
}
```

---

## Test plan

### Automated Tests

**Backend:**
1. **Unit test: Pattern analysis logic**
   - Input: 5 dairy waste events, 2 produce, 1 meat
   - Output: `most_wasted_category = "dairy"`
2. **Unit test: Tip generation rules**
   - Input: Category = "dairy", count = 3
   - Output: Tip text = "You've wasted dairy 3 times this month. Try buying smaller quantities."
3. **Unit test: Privacy validation**
   - Input: Waste event with `itemName: "Milk"`
   - Output: Tip text does NOT contain "Milk"
4. **Integration test: Cron job execution**
   - Trigger: Manual cron execution
   - Verify: Pro users with tips enabled receive push notifications
   - Verify: Tip saved to history table

**Frontend:**
1. **Widget test: Opt-in prompt renders**
   - Verify: Title = "Get Smarter About Reducing Waste"
   - Verify: Two buttons: "Enable Tips", "Not Now"
2. **Widget test: Banner displays tip text**
   - Input: Tip = "You waste dairy most often..."
   - Verify: Banner shows emoji + text
   - Verify: Dismiss button present
3. **Integration test: Enable tips flow**
   - Action: Tap "Enable Tips"
   - Verify: `telemetry_consent: true` saved to local DB
   - Verify: Telemetry event `tips_enabled` tracked
4. **Integration test: Disable tips flow**
   - Action: Toggle OFF in Settings
   - Verify: Confirmation dialog appears
   - Verify: After confirming, `telemetry_consent: false` saved
5. **E2E test: Full tip lifecycle**
   - Action: Enable tips → Wait 7 days (fast-forward in test)
   - Verify: Push notification delivered
   - Action: Tap notification
   - Verify: Tip detail page opens
   - Action: Dismiss tip
   - Verify: Banner removed, event `tip_dismissed` tracked

### Manual Tests

1. **Opt-In Flow:**
   - Upgrade to Pro tier
   - Verify opt-in prompt appears within 5 seconds
   - Tap "Enable Tips" → Settings → Privacy → Personalized Tips shows **ON**
   - Tap "Not Now" → Prompt dismisses, tips remain OFF

2. **Tip Delivery (Wait 7 Days):**
   - Enable tips
   - Add waste events over 7 days (at least 3 items in same category)
   - On Day 8 (Monday 9 AM), verify push notification appears
   - Tap notification → Verify tip detail page opens with relevant advice

3. **In-App Banner:**
   - After receiving tip, open Inventory tab
   - Verify banner appears at top (light blue, 💡 icon, tip text)
   - Tap dismiss → Verify banner disappears
   - Re-open app → Verify same tip does NOT reappear

4. **Tip History:**
   - Settings → Privacy → Personalized Tips → View History
   - Verify: All received tips listed (ordered by date, newest first)
   - Tap a tip → Verify: Full text displayed

5. **Disable Tips:**
   - Settings → Privacy → Personalized Tips → Toggle OFF
   - Verify: Confirmation dialog appears
   - Confirm → Verify: Tips disabled, no new tips received

6. **Privacy Validation:**
   - Review all tip text generated
   - Verify: No item names (e.g., "Milk", "Yogurt") appear
   - Verify: Only category + advice (e.g., "dairy", "buy smaller quantities")

7. **Offline Behavior:**
   - Enable tips while online
   - Go offline (airplane mode)
   - Open app → Verify: Last tip still visible in history
   - Disable tips offline → Re-connect → Verify: Settings synced to backend

8. **Accessibility:**
   - Enable VoiceOver (iOS) or TalkBack (Android)
   - Verify: Opt-in prompt reads title + body text
   - Verify: Banner dismissible via swipe or tap
   - Verify: Tip history navigable with screen reader

---

## Dependencies

**Prerequisite Issues:**
- **Issue 040:** Telemetry taxonomy (defines event schema, anonymization rules)
- **Issue 470:** Cloud sync (Pro tier backend for storing tips + telemetry)
- **Issue 490:** Advanced analytics (shares pattern analysis infrastructure)

**Concurrent Issues:**
- **Issue 500:** Smart home integrations (Nest temp alerts can feed into tips)
- **Issue 495:** Data export (tips history exportable as part of user data)

**Blocking Issues:**
- None (can proceed once M6 Pro tier backend is deployed)

---

## Notes

**Privacy-First Design:**
- Tips are 100% opt-in (no dark patterns, no auto-enable)
- Free users never see telemetry prompts (keeps free tier fully offline)
- Pro users control their data (enable/disable anytime, delete all data)

**Why Pro Tier?**
- Backend costs: Pattern analysis + tip generation + push notifications + storage
- Value justification: Personalized insights worth $2.99/month
- Differentiates from Free tier: Free = local tracking, Pro = actionable insights

**User Benefit:**
- **Actionable:** Tips include concrete suggestions (not generic advice)
- **Timely:** Weekly cadence (not overwhelming, not too infrequent)
- **Positive Framing:** Encouragement, not criticism ("You've reduced waste by 10%!")

**Technical Considerations:**
- Tip generation logic should be extensible (easy to add new tip types in M7)
- Tip history persisted locally + cloud (offline-first, syncs when online)
- Push notification infrastructure reused for other Pro features (expiry reminders, household updates)

---

## Related Issues

- **Issue 040:** Telemetry taxonomy (event schema for tips instrumentation)
- **Issue 470:** Cloud sync (Pro tier backend for tip storage)
- **Issue 490:** Advanced analytics (pattern analysis infrastructure)
- **Issue 500:** Smart home integrations (Nest temp alerts → tips)
- **Issue 310:** Shareable progress cards (social proof + tips = motivation)
- **Issue 300:** Achievement badges (tips can trigger badge-related advice)
