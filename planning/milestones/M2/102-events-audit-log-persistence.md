## Context
Audit trail is critical for analytics and understanding user behavior with food waste. Events track creation, consumption, and wastage actions.

## Goal
Implement local persistence for Events (audit log) with flexible JSON metadata for event-driven analytics.

## Expected behavior
- Log item lifecycle events (created, consumed, wasted, edited)
- Store flexible metadata per event type
- Query events by type, item, date range
- Events persist for analytics reporting

## Acceptance criteria (Definition of Done)
- [ ] Repository layer abstracts storage (HiveEventRepository)
- [ ] CRUD operations implemented (add, query, clear)
- [ ] Query operations (getByItemId, getByType, getByDateRange)
- [ ] Unit tests added or updated (10+ tests)
- [ ] Offline-first behavior verified
- [ ] Event schema matches planning/docs/data-model.md
- [ ] Data persists across restarts
- [ ] Accessibility basics (N/A for audit log)

## Out of scope
- Real-time event streaming (M6+)
- Event replay/time travel (Pro feature)
- Encrypted event storage (M3)
- Cloud event sync (M6)
- Event deletion/archival UI (M3)

## Implementation notes
- Reuse HiveDatabase infrastructure from M2/100
- Schema: id, item_id (nullable), event_type enum, timestamp, metadata (JSON string)
- Indexes: (timestamp desc), (item_id, timestamp), (event_type)
- Event types: item_created, item_consumed, item_wasted, item_edited, item_deleted, app_installed
- Metadata is flexible JSON - varies by event_type (see planning/docs/data-model.md)
- Use TypeAdapter for DateTime/UUID serialization
- Metadata stored as JSON string (Hive doesn't have native JSON type)

## Test plan
**Automated:**
- Unit test: addEvent persists with correct metadata
- Unit test: getByItemId returns all events for item
- Unit test: getByType returns correct event type
- Unit test: getByDateRange filters by timestamp window
- Unit test: Metadata is preserved (JSON round-trip)
- Unit test: Event with null item_id (app-level events) handled correctly
- Unit test: Timestamp ordering maintained
- Unit test: Large event volumes (1000+) queried efficiently (<200ms)
- Unit test: Data persists across app restarts
- Unit test: Old events don't impact performance

**Manual:**
1. Create item \u2192 verify item_created event logged
2. Consume item \u2192 verify item_consumed event with quantity_consumed metadata
3. Waste item \u2192 verify item_wasted event with waste_reason metadata
4. Check event dashboard (if UI exists) \u2192 verify all events appear
5. Export events (if available) \u2192 verify JSON metadata readable
6. Force crash \u2192 reopen \u2192 verify events still queryable

## Dependencies
- M2/100 (HiveDatabase infrastructure)
- Must complete before M3/XXX (analytics reporting)

## Telemetry
Log to local queue:
- `event_logged`: {event_type, item_id_present, metadata_size_bytes}
- Track event creation latency (<50ms target)

## Future Considerations
- Batch export events for cloud analytics (M6)
- Implement event compaction (remove duplicate/redundant events)
- Add event query language for complex filtering
- Implement time-series aggregations for analytics dashboards
