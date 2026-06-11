# WI-0005: Audit Policy and RBAC Enforcement

## Metadata

- Status: `todo`
- Milestone: `M3`
- Owner: `unassigned`
- Priority: `P1`
- Target Date: `2026-07-18`
- Dependencies: `WI-0004`
- Linked Issue: `710`

## Context

Security-sensitive updates require consistent role checks and auditable policy decisions.

## Scope

- In scope:
  - Standardize role checks for protected mutation endpoints
  - Capture policy decision logs with correlation ID and actor role
  - Add policy test matrix for allowed/denied actions
- Out of scope:
  - External IAM federation

## Acceptance Criteria

- [ ] Policy enforcement exists on all protected write endpoints
- [ ] Audit records include actor, action, result, and timestamp
- [ ] Test suite verifies key allow/deny scenarios

## Definition of Done

- [ ] Code implemented
- [ ] Tests added/updated
- [ ] Docs updated
- [ ] Merged to main
