# Planning Workspace

This folder tracks delivery using milestones and workitems.

## Structure

- `milestones/`: Milestone-level scope, status, and exit criteria.
- `workitems/`: Executable items with owner, status, dependencies, and Definition of Done.
- `progress.md`: Single dashboard for overall status and weekly updates.

## Workflow

1. Add or update workitems in `workitems/`.
2. Link each workitem to a milestone in `milestones/README.md`.
3. Update `progress.md` whenever status changes.
4. Keep status values consistent: `todo`, `in-progress`, `blocked`, `done`.

## Status Rules

- `todo`: Not started.
- `in-progress`: Active implementation.
- `blocked`: Waiting on dependency, review, or environment.
- `done`: Acceptance criteria met and merged.

## Current Focus

Issue-aligned roadmap for management UI delivery after Phase 0:

- Issue 690: Telemetry ETL and DuckDB marts
- Issue 700: Feature flags control plane
- Issue 710: Audit and policy engine RBAC
