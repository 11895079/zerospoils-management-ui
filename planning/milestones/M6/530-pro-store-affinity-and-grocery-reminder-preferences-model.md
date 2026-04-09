# Issue 530: Pro Store Affinity and Grocery Reminder Preferences Model

**Milestone:** M6 (Pro Tier Features)
**Priority:** P2 (Foundation for Issue 525)
**Effort:** S (Small-to-medium — local models, persistence, migration, settings plumbing)
**Labels:** `pro`, `mobile`, `location`, `data-model`, `privacy-sensitive`

## Context

Issue 525 defines Pro geofenced grocery reminders, but that feature depends on a durable local model for:

- learned regular grocery stores
- reminder cooldown/suppression state
- user-managed pinned staples and opt-in preferences
- attribution metadata needed to explain why a reminder appeared

Without a dedicated data-model issue, the reminder implementation will likely scatter this logic across UI, services, and notification handlers.

## Goal

Define and persist the local data model needed for Pro grocery proximity reminders, including store affinity, reminder suppression, and user preferences.

## Expected behavior

### Learned store model

1. App can persist a learned store record with:
   - stable local store identifier
   - display name (if known)
   - store category/type
   - visit count
   - last seen timestamp
   - affinity tier or score
   - suppression state
2. Store records can be listed, updated, cleared, and removed locally.

### Reminder preference model

1. App persists whether nearby-store reminders are enabled.
2. App persists per-store suppression or mute state.
3. App persists reminder cooldown metadata:
   - last reminder timestamp
   - last candidate fingerprint
   - dismissal count bucket
4. App persists user-pinned staple candidates if feature is enabled in v1.

### Settings support

1. Settings can load the learned-store list and reminder preferences.
2. User can remove a learned store or reset all grocery reminder learning.
3. Clearing reminder learning removes suppression state and learned affinity data.

## Acceptance criteria (Definition of Done)

### Data model
- [ ] Local model exists for learned grocery stores.
- [ ] Local model exists for grocery reminder preferences and cooldown metadata.
- [ ] Model supports schema migration for future cloud-sync expansion.
- [ ] Persistence layer is testable and independent from widget code.

### Behavior
- [ ] Learned store records can be inserted, updated, and removed locally.
- [ ] Reminder preference state survives app restart.
- [ ] Reset action clears learned stores, suppression, and cooldown state.
- [ ] Per-store suppression can be toggled without removing the store entirely.

### Tests
- [ ] Unit test: store affinity record persists and reloads correctly.
- [ ] Unit test: cooldown metadata persists and updates atomically.
- [ ] Unit test: reset action clears all grocery reminder learning state.
- [ ] Widget test: settings data source renders learned stores and reset action state.

### Privacy and offline-first
- [ ] No exact coordinate history is persisted in this model.
- [ ] All state works offline and remains local in v1.
- [ ] Stored fields are coarse-grained and safe for telemetry-free operation.

## Out of scope

- Geofence trigger implementation.
- Place API integration.
- Cloud sync of learned stores.
- Advanced retailer metadata such as prices, aisles, or loyalty programs.

## Implementation notes

- Prefer a dedicated local store/service rather than reusing unrelated settings blobs.
- Keep identifiers abstract enough to survive future provider changes in place detection.
- Model should support future sync but default to local-only for v1.
- Consider Hive or SharedPreferences only if the schema remains simple; otherwise use a typed local store.
- Expose a clear repository/service seam for Issue 525 to consume.

## Test plan

**Automated:**
- Unit test: learned store record create/update/remove.
- Unit test: reminder preference and cooldown persistence.
- Unit test: reset clears stores and suppression state.
- Widget test: settings list reflects stored learned stores.

**Manual:**
1. Enable nearby-store reminders and restart app; verify preference persists.
2. Seed one learned store and verify it appears in Settings.
3. Suppress that store and verify the setting persists across restart.
4. Reset learned store data and verify list and suppression state are cleared.

## Dependencies

- Issue 410: Pro subscription strategy + feature gating
- Issue 420: In-app purchases (IAP) + entitlement storage
- Issue 525: Pro geofenced grocery reminders for low inventory