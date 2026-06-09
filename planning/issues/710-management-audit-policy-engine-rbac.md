# 710 — Management Audit + Policy Engine (Operator RBAC)

## Context
The management backend UI introduces privileged operations (flag mutations, moderation actions, entitlement updates). These operations require a single policy engine and immutable audit model to prevent unsafe ad hoc permission checks.

## Goal
Implement the operator RBAC policy engine and immutable audit trail used by all management backend mutation endpoints.

## Expected behavior
- Every privileged API route is guarded by centralized policy checks.
- Role model supports `admin`, `analyst`, and `support` with explicit allowlists.
- Every mutation emits immutable audit records with before/after summaries.
- Denials are observable with clear reason codes.

## Acceptance criteria (Definition of Done)
- [ ] Central policy engine implemented with default-deny behavior.
- [ ] Role/action permission matrix documented in `docs/ops/management-rbac-policy.md`.
- [ ] Middleware/decorator guard adopted by all management mutation endpoints.
- [ ] Immutable audit log schema implemented: actor_id, actor_role, action, resource_type, resource_id, before_json, after_json, request_id, created_at.
- [ ] Audit viewer endpoint supports filtering by actor, action, resource, and date range.
- [ ] Denied actions are logged with reason codes and surfaced in operator telemetry.
- [ ] Tamper controls documented (append-only writes, no update/delete path for audit rows).

## Out of scope
- Enterprise approval workflow orchestration.
- External SIEM integration.

## Implementation notes
- Keep policy definitions declarative (config/table-based) to simplify review and change control.
- Use request correlation id everywhere so audit rows map to logs and UI actions.
- Avoid embedding business logic directly inside per-endpoint permission checks.

## Test plan
**Automated:**
- Unit test: role/action matrix enforces expected allow/deny results.
- Integration test: guarded endpoints reject unauthorized role and emit denial audit/telemetry record.
- Integration test: successful privileged mutation writes immutable audit row with before/after payload.
- Negative test: attempts to mutate/delete audit rows are blocked.

**Manual:**
1. Log in as support role and attempt privileged config mutation; verify denial + reason.
2. Log in as admin and perform mutation; verify audit row appears with expected fields.
3. Filter audit viewer by action/resource/date and verify deterministic results.

## Dependencies
- 680 (management UI local runtime bootstrap)
- 700 (feature flags and Remote Config control plane)
- 545 (household and management RBAC alignment)
