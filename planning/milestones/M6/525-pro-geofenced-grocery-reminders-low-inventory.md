# Issue 525: Pro Geofenced Grocery Reminders for Low Inventory

**Milestone:** M6 (Pro Tier Features)
**Priority:** P2 (High-value Pro differentiator, not core subscription plumbing)
**Effort:** M (Medium — local location triggers, heuristics, preferences, paywall gating)
**Labels:** `pro`, `mobile`, `notifications`, `location`, `privacy-sensitive`, `telemetry-required`

## Context

Users often realize they are out of staples only after they leave the store or get home. ZeroSpoils already tracks inventory, shopping lists, and reminder preferences, but it does not yet use place context to surface timely shopping prompts.

This feature adds a Pro-only reminder when the app detects the user is near a grocery store, especially one they visit regularly, and inventory is low or likely due for replenishment. The first version should work offline-first and keep the location model privacy-preserving by storing store affinity locally.

## Goal

Deliver a Pro-tier grocery proximity reminder that triggers a local notification or in-app pop-up when the user is near a recognized grocery store and has low-stock or soon-needed items.

## Expected behavior

### Feature entry and consent

1. Pro user opens Settings → Notifications → Grocery reminders.
2. User enables a toggle: `Nearby store reminders`.
3. App explains:
   - Uses background location only to detect proximity to grocery stores.
   - Store visit patterns are learned locally on-device.
   - Reminders use shopping list items plus low-inventory heuristics.
4. If OS location permission is missing, app requests foreground/background permission with clear rationale.

### Store affinity model

1. App detects visits to grocery-store POIs or user-confirmed stores.
2. Repeated visits to the same store increase a local affinity score.
3. Stores with high affinity are marked as `regular stores` and prioritized for reminders.
4. User can review and remove regular stores from Settings.

### Reminder trigger logic

1. App detects entry into a grocery-store geofence.
2. App evaluates reminder candidates:
   - Items already on shopping list.
   - Staple items predicted as low based on local inventory/replenishment heuristics.
   - Optional user-pinned staples.
3. If candidates exist and cooldown rules allow, app shows a local notification and optionally an in-app sheet.
4. Notification example:
   - Title: `Near your grocery store`
   - Body: `You're near FreshCo and may need milk, eggs, and bread.`
5. Tapping the reminder opens Shopping List with highlighted suggested items and source context.

### Cooldowns and spam prevention

- Maximum one reminder per store visit window.
- Respect global notification settings and Do Not Disturb hours if already configured.
- Do not remind again for the same candidate set within 24 hours unless the list changes materially.
- If user dismisses three consecutive reminders for a store, reduce reminder frequency for that store.

## Acceptance criteria (Definition of Done)

### Product behavior
- [ ] Pro entitlement gates the feature; free users see locked state and upgrade CTA.
- [ ] Settings includes `Nearby store reminders` toggle with explanatory copy.
- [ ] User can enable/disable grocery proximity reminders independently of standard expiry reminders.
- [ ] Reminder only triggers when both location context and reminder candidates exist.
- [ ] Shopping-list items are included as first-priority reminder candidates.
- [ ] Regular-store affinity is learned locally and exposed in settings for review/removal.
- [ ] Trigger respects cooldowns to avoid notification spam.

### Data and privacy
- [ ] Exact location history is not uploaded by default.
- [ ] Store affinity and visit counts are stored locally for v1.
- [ ] User can clear learned stores and reset reminder learning.
- [ ] Permission rationale explains why background location is needed.
- [ ] Telemetry excludes exact coordinates and store addresses.

### UX
- [ ] Free users see a clear Pro upsell state without broken controls.
- [ ] Reminder tap opens Shopping List with source context (`near_store_reminder`).
- [ ] Reminder content caps visible items and summarizes overflow (`+2 more`).
- [ ] In-app sheet and notification copy use established design tokens and accessible labels.

### Tests
- [ ] Unit test: low-inventory candidate selector prioritizes shopping-list items and staples.
- [ ] Unit test: store-affinity scorer promotes repeated stores and cools down ignored stores.
- [ ] Unit test: cooldown logic suppresses duplicate reminder sets.
- [ ] Widget test: Pro-gated settings row renders locked/unlocked states correctly.
- [ ] Widget test: tapping reminder deep-links into Shopping List with highlighted source context.
- [ ] Integration test: simulated geofence entry with low-stock candidates schedules one reminder.
- [ ] Integration test: repeated geofence events inside cooldown window do not create duplicates.

### Telemetry
- [ ] `near_store_reminder_enabled_changed` { enabled: bool, pro_user: bool }
- [ ] `near_store_detected` { trigger_source, regular_store: bool, candidate_count }
- [ ] `near_store_reminder_sent` { regular_store: bool, candidate_count, source_breakdown }
- [ ] `near_store_reminder_opened` { regular_store: bool, candidate_count }
- [ ] `near_store_reminder_dismissed` { regular_store: bool, candidate_count }
- [ ] `regular_store_learned` { visit_count_bucket, store_type }
- [ ] `regular_store_removed` { previous_visit_count_bucket }

### Offline-first and accessibility
- [ ] Store-affinity learning works offline.
- [ ] Reminder candidate evaluation works offline using local inventory + shopping list data.
- [ ] Settings and reminder surfaces expose semantic labels and 44pt+ tap targets.
- [ ] Permission-denied state provides accessible fallback guidance.

## Out of scope

- Cloud-synced store affinity across devices.
- Price comparison between stores.
- Third-party retailer APIs or loyalty-card integrations.
- Real-time traffic/travel-time optimization.
- Automatic purchase confirmation based on store exit.

## Implementation notes

- Implement v1 with local geofencing and local preference storage; avoid backend dependency for core behavior.
- Reuse existing notification infrastructure from M3/190 for scheduling and tap attribution.
- Reuse shopping-list and replenishment heuristics where available; if M5/155 is incomplete, use a simpler local low-stock selector first.
- Build on Issue 530 for learned-store persistence, suppression state, and reminder preference storage.
- Keep store learning coarse-grained: store identifier, category, visit count, last seen timestamp, reminder suppression score.
- Surface this in Settings under a Pro section or Notifications subsection, depending on final IA.
- Feature should hard-depend on entitlement gating from Issue 410 / purchase flow from Issue 420.
- Consider platform constraints explicitly:
  - Android: background location + geofencing API.
  - iOS: location authorization tiers and reduced background execution allowances.
- Store POI detection may need a local curated grocery-category list or platform place APIs; document fallback if store-name resolution is unavailable.

## Test plan

**Automated:**
- Unit test: candidate selector returns shopping-list items first, then replenishment suggestions.
- Unit test: `RegularStoreLearningService` updates visit counts and demotes repeatedly ignored stores.
- Unit test: reminder cooldown prevents duplicate notifications for same store + candidate fingerprint.
- Widget test: settings row shows paywall CTA for free users and toggle for Pro users.
- Widget test: reminder tap opens Shopping List with `near_store_reminder` attribution.
- Integration test: mocked geofence event near regular store with low inventory triggers one reminder.
- Integration test: second mocked geofence within cooldown triggers no reminder.

**Manual:**
1. Upgrade to Pro test entitlement and enable `Nearby store reminders`.
2. Grant location permission, simulate entry near a grocery store, verify reminder appears only when shopping list/low-stock candidates exist.
3. Tap reminder and verify Shopping List opens with highlighted suggested items.
4. Re-enter same store geofence within cooldown window and verify no duplicate reminder is shown.
5. Dismiss reminders repeatedly for one store and verify frequency drops.
6. Remove a learned regular store in Settings and verify reminders no longer treat it as preferred.
7. Disable the feature and verify no reminders are triggered on subsequent geofence events.

## Dependencies

- Issue 180: Reminder preferences UI
- Issue 190: Notification scheduling integration
- Issue 210: Shopping list UI
- Issue 410: Pro subscription strategy + feature gating
- Issue 420: In-app purchases (IAP) + entitlement storage
- Issue 155: Smart replenishment (optional enhancement for stronger low-stock suggestions)
- Issue 530: Pro store affinity and grocery reminder preferences model