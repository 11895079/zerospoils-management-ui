## Context
Reminder design is central to value: helpful, not annoying.

## Goal
Define reminder timing defaults and user controls.

## Expected behavior
- Default lead times exist and are configurable
- Copy is encouraging and non-judgmental

## Acceptance criteria (Definition of Done)
- [ ] Settings screen includes reminder lead time options
- [ ] Notification copy templates defined (expiring today/soon/expired)
- [ ] Document in `docs/notifications.md`
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Not defined

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
**Automated:**
- Verify `docs/notifications.md` contains default lead times and copy templates
- Script validates notification copy follows tone guidelines (encouraging, non-judgmental)
- Check all copy templates include required variables (item_name, expiry_date)

**Manual:**
1. Review notification copy with 3 users for tone and clarity
2. Verify default lead times align with MVP scope (e.g., 3 days, 1 day, day-of)
3. Confirm settings UI wireframe includes lead time configuration
4. Test copy templates with various item names and dates

## Dependencies
- None
