## Context
Offline-first is a core promise; storage must be reliable.

## Goal
Implement local persistence for Items with reliable CRUD operations and migration strategy. ShoppingList and Events repositories deferred to separate issues (M2/101, M2/102).

## Expected behavior
- CRUD persists across restarts
- Migration strategy exists

## Acceptance criteria (Definition of Done)
- [ ] Repository layer abstracts storage
- [ ] Migration mechanism documented + tested
- [ ] Optional encryption-at-rest evaluated and decision recorded
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- ShoppingList repository (deferred to M2/101)
- Events audit log repository (deferred to M2/102)
- Encryption-at-rest implementation (deferred to M3 security)
- Data export/import UI (M3)
- Background sync workers (M3)
- Multi-user access/household sharing (M6)
- Full-text search indexing (M4)

## Implementation notes
- Consider Drift if relational queries needed.
- Add versioned migrations and tests.
- Hive supports encrypted boxes (AES-256) - evaluate but defer to M3 unless security critical
- Track schema version in metadata box for migration decisions

## Performance Requirements
- getAllItems: <100ms for 1000 items
- saveItem: <50ms per item
- deleteItem: <50ms per item
- getItemsByCategory: <100ms for 1000 items
- getItemsExpiringSoon: <100ms for 1000 items
- Database init: <500ms cold start
- Migration: <2s for existing data upgrade

## Encryption Evaluation
Hive provides optional AES-256 encryption via encrypted boxes:
**Pros:** Built-in support, transparent encryption, key-based access control
**Cons:** Performance overhead, key storage/rotation complexity, not needed for MVP
**Decision for M2:** Skip (not in MVP scope). Create M3 issue for encryption implementation if needed.
**Alternative:** Use Hive's normal boxes for M2, migrate to encrypted boxes in M3 with migration logic.

## Test plan
**Automated:**
- Unit test: HiveDatabase.init() opens boxes and performs migrations
- Unit test: Repository CRUD operations (saveItem, getItem, deleteItem, clear)
- Unit test: Repository filtering (getItemsByCategory, getItemsExpiringSoon)
- Unit test: Data persists across repository close/reopen cycles
- Unit test: Migration from v0 to v1 executes without data loss
- Integration test: App restart preserves stored items

**Manual:**
1. Add 3 items via UI → close app → reopen → verify all 3 items present
2. Add item with expiry 2 days away → verify appears in "expiring soon" list
3. Delete item → verify removed and not present after restart
4. Add 10+ items → verify getAllItems returns all items quickly (<100ms)
5. Force crash (kill process) → reopen → verify data intact

## Dependencies
- None
