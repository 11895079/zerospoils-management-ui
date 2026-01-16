## Context
IoT expands attack surface; do a focused security pass before shipping integrations.

## Goal
Harden auth, tokens, and network exposure paths for IoT/HA features.

## Expected behavior
- Tokens are scoped and rotatable
- Default posture is least privilege
- Threat model exists

## Acceptance criteria (Definition of Done)
- [ ] Create `docs/security/iot-threat-model.md` (assets, threats, mitigations)
- [ ] Implement token scopes + rotation strategy
- [ ] Add rate limits and audit logging for webhook endpoints
- [ ] Add guidance for HA users (LAN-only, reverse proxy warnings)
- [ ] Unit/widget/integration tests added or updated
- [ ] Telemetry added/updated (event names + key properties)
- [ ] Offline-first behavior verified (where applicable)
- [ ] Accessibility basics (labels, contrast, tap targets)

## Out of scope
- Full pentest.

## Implementation notes
- Keep codebase modular (domain/data/ui layers).

## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 

## Dependencies
- None
