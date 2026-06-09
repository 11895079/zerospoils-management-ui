# 680 — Management Backend UI: Local Runtime Bootstrap

## Context
The project needs a local-first management control plane that operators can run on demand, while preserving a clean migration path to cloud deployment later. Current planning covers app telemetry and Firebase integrations but does not define local runtime topology for backend management workflows.

## Goal
Stand up the local runtime foundation for the management backend UI: web frontend, management API, background worker, and local analytics store wiring.

## Expected behavior
- Operator can start management stack locally with one command.
- UI, API, and worker run as separate services with shared configuration.
- Runtime can be containerized without code changes (env-driven config).
- Baseline RBAC login and session model works for a small internal team.

## Acceptance criteria (Definition of Done)
- [ ] Local runtime topology documented in `docs/ops/management-ui-local-runtime.md`.
- [ ] Startup/shutdown commands provided (`scripts/` or compose file) with health checks.
- [ ] Services are split into `ui`, `api`, and `worker` processes with clear ports.
- [ ] Configuration is environment-based (no hardcoded secrets in source).
- [ ] Role-aware authentication baseline implemented for `admin`, `analyst`, `support`.
- [ ] Request correlation id is propagated from UI to API and worker logs.
- [ ] Runtime status page shows service health and current config profile (`local`, `staging`, `cloud`).

## Out of scope
- Production cloud deployment automation.
- Enterprise SSO.
- Multi-region topology.

## Implementation notes
- Prefer container-ready process boundaries early to avoid later refactor.
- Keep provider adapters isolated so backend providers can be swapped (Firebase-first now, cloud-agnostic later).
- Include developer-first diagnostics (health endpoint, config dump with secrets redacted).

## Test plan
**Automated:**
- Integration test: local bootstrap command starts all services and each health endpoint reports ready.
- Integration test: invalid/missing required env vars fail fast with actionable error.
- Integration test: role login flow allows authorized routes and blocks forbidden routes.

**Manual:**
1. Run bootstrap command from clean workspace and verify UI/API/worker all report healthy.
2. Stop and restart stack; verify persisted local metadata (non-secret) is retained as expected.
3. Switch profile from local to staging-style env file and verify startup still succeeds.

## Dependencies
- 370 (security hardening baseline)
- 710 (management audit and policy engine)
