# Planning Workspace

This folder tracks delivery using milestones and workitems.

## Structure

- `milestones/`: Milestone-level scope, status, and exit criteria.
- `workitems/`: Executable items with owner, status, dependencies, and Definition of Done.
- `epics/`: Cross-milestone outcomes and source/feature coverage; see [EPIC-0001](epics/EPIC-0001-beta-to-public-launch-operations.md) for beta-to-public-launch reporting.
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
- **EPIC-0001 (M4–M5):** Beta go/no-go, launch telemetry integrity, support/release operations, product outcomes, worker/MAF visibility and public rollout. **P0 beta safety/data first**; [management UI #9](https://github.com/11895079/zerospoils-management-ui/issues/9) is the parent tracker. Existing local-worker [#8](https://github.com/11895079/zerospoils-management-ui/issues/8) remains authoritative for its integration.
