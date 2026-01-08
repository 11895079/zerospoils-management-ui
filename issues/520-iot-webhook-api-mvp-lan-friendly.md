## Context
HA and DIY stations need a simple API to send events to ZeroSpoils.

## Goal
Implement a minimal webhook API for adding/updating inventory items.

## Expected behavior
- External client can add/update items securely
- Requests are authenticated and rate-limited

## Acceptance criteria (Definition of Done)
- [ ] Implement webhook endpoint(s) and token issuance for a user/household
- [ ] Validate payload schema and return deterministic responses
- [ ] Add audit logging for webhook calls
- [ ] Document API in `docs/iot/webhooks.md` with examples
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Public internet exposure by default.

## Implementation notes
- Prefer LAN-only exposure by default.
- Consider running as local service for HA users later.

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
