# WI-0002: DuckDB Analytics Marts

## Metadata

- Status: `done`
- Milestone: `M1`
- Owner: `unassigned`
- Priority: `P1`
- Target Date: `2026-06-27`
- Dependencies: `WI-0001`
- Linked Issue: `690`

## Context

Current dashboard APIs use random mock generators. Replace with deterministic DuckDB marts.

## Scope

- In scope:
  - Define marts for core dashboard metrics
  - Update API routes to read from marts
  - Validate query latency and shape compatibility
- Out of scope:
  - Historical backfill from external production systems

## Acceptance Criteria

- [x] `/api/metrics/*` uses DuckDB-backed queries
- [x] Summary and history payload formats remain compatible
- [x] Error handling and fallback behavior documented

## Definition of Done

- [x] Code implemented
- [x] Tests added/updated
- [x] Docs updated
- [x] Merged to main
