# WI-0004: Feature Flags Control Plane

## Metadata

- Status: `todo`
- Milestone: `M2`
- Owner: `unassigned`
- Priority: `P2`
- Target Date: `2026-07-08`
- Dependencies: `WI-0001`
- Linked Issue: `700`

## Context

Management features need controlled rollout and safe toggling. The current plan
mentions remote config sync, but the workitem needs explicit requirements for a
user-friendly custom editor that can safely modify Firebase Remote Config
without hardcoded parameter assumptions.

## Remote Config Data Shape (Firebase)

The Firebase Remote Config template should be treated as dynamic JSON with
these top-level structures:

- `etag`: optimistic concurrency token required for safe update
- `parameters`: map of parameter key -> parameter definition
- `conditions`: ordered list of condition expressions
- `version`: template metadata (`versionNumber`, `updateUser`, `updateTime`)

Expected parameter definition shape:

- `defaultValue.value`: string
- `conditionalValues[conditionName].value`: string (optional)
- `description`: string (optional)
- `valueType`: one of `STRING | BOOLEAN | NUMBER | JSON`

Expected condition definition shape:

- `name`: unique condition name
- `expression`: Firebase condition expression
- `tagColor`: optional display tag

Notes on nature of data:

- Remote Config values are string-backed even when interpreted as boolean,
  numeric, or JSON by clients.
- Parameters may be added/removed externally and should be discovered at runtime.
- Unknown/new parameter shapes must be rendered safely as read-only until type
  mapping is confirmed.

## Scope

- In scope:
  - Build a custom management UI for viewing and editing Firebase Remote Config
    parameters and conditions.
  - Implement dynamic discovery of remote config keys/conditions from live
    template fetch (no static frontend key list).
  - Build API endpoints for read/update/validate/publish with role checks and
    etag-based conflict handling.
  - Provide typed editing controls derived from `valueType` (toggle, number,
    JSON editor, string input) with preview and validation errors.
  - Capture full audit trail for config changes (who, before/after, correlation
    ID, rollback target version).
  - Preserve feature-flag rendering in frontend using resolved remote values.
- Out of scope:
  - Per-user experimentation and advanced segmentation strategy design.
  - Replacing Firebase as the remote config source of truth.
  - Mobile-side fetch/activation lifecycle changes beyond compatibility checks.

## Acceptance Criteria

- [ ] Admin UI dynamically lists parameters/conditions from Firebase Remote
      Config template and refreshes without redeploy when keys change.
- [ ] Authorized users can edit and publish parameter values (default and
      conditional) through typed controls with client/server validation.
- [ ] Update operations use `etag` and return clear conflict responses when
      template changed externally.
- [ ] Failed publish attempts provide actionable diagnostics (invalid condition,
      invalid JSON, stale etag, permission denied).
- [ ] Successful publishes increment template version and are visible in
      `/api/remote-config/history` with diff summary.
- [ ] Frontend behavior changes according to resolved remote-config values.
- [ ] Changes are auditable and rollback-capable by selecting a prior template
      version.

## Definition of Done

- [ ] Code implemented
- [ ] Tests added/updated
- [ ] Docs updated
- [ ] Merged to main

## Test Plan

Automated:

- API unit tests for template parse/mapping, etag conflict flow, and validation
  errors (`BOOLEAN/NUMBER/JSON` coercion and rejection cases).
- API integration tests for fetch -> edit -> publish -> history/rollback flows
  using mocked Firebase Admin SDK responses.
- Frontend component tests for dynamic form generation from discovered
  parameters and condition-aware editing.
- E2E test for admin editing a discovered parameter, publishing, and observing
  updated value/state in dashboard.

Manual:

- Add a new parameter directly in Firebase Console; verify it appears in the
  management UI without code changes.
- Simulate concurrent edit from console; verify stale etag conflict guidance in UI.
- Publish an invalid JSON value; verify validation prevents publish and shows
  field-level error.
- Roll back to previous template version and verify value restoration.
