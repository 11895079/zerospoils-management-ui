# 700 — Management Control Plane for Feature Flags + Remote Config

## Context
Feature flags and Remote Config are in use, but updates are still mostly console-driven and lack a unified management workflow with validation, rollout controls, and audit-friendly change history.

## Goal
Build a management control plane for feature flags and Remote Config that supports safe mutations (dry-run, staged rollout, rollback) with strict role-based authorization.

## Expected behavior
- Operators can view current/default flag values and metadata in one registry.
- Admin can perform dry-run validation before publishing config changes.
- Rollouts can be staged and rolled back quickly.
- Every config change is auditable and linked to actor and reason.

## Acceptance criteria (Definition of Done)
- [ ] Flag registry view includes: key, description, default, current value, owner, last changed.
- [ ] Dry-run validation endpoint checks payload schema and dependency conflicts.
- [ ] Staged rollout controls support percentage rollout and targeted segments.
- [ ] One-click rollback restores previous known-good config snapshot.
- [ ] Change request requires reason/comment and emits immutable audit entry.
- [ ] Non-admin roles cannot mutate flags/config and receive clear 403 responses.
- [ ] UI shows config propagation status and last successful fetch timestamp.

## Out of scope
- Full experimentation platform (A/B test statistics engine).
- Automatic optimization of flag rollout percentages.

## Implementation notes
- Keep precedence model unchanged: `local_override > remote_override > default`.
- Restrict local overrides to debug/internal environments.
- Store config snapshots with checksums for quick diff and rollback validation.

## Test plan
**Automated:**
- API test: dry-run rejects invalid payload and returns conflict details.
- API test: admin can publish config; analyst/support receive 403.
- Integration test: rollback restores previous snapshot and updates active config state.
- Contract test: config diff API reports before/after values deterministically.

**Manual:**
1. Open registry and verify metadata completeness for all managed flags.
2. Submit dry-run with invalid value and verify publish is blocked.
3. Publish staged rollout, then rollback; verify app clients read restored value after fetch window.

## Dependencies
- 130 (feature flags framework)
- 360 (Firebase remote config integration)
- 370 (security hardening)
- 710 (management audit and policy engine)
