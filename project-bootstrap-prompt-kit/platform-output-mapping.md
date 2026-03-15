# Platform Output Mapping

This document maps prompt outputs to a platform-friendly SDLC data model so operators can track progress, risk, quality, and performance over time.

## 1. Canonical Entities

Use these entities in your platform storage layer:

- `Project`: static profile and constraints.
- `PhaseRun`: one execution of a phase prompt.
- `Artifact`: structured output produced by a prompt.
- `MetricSnapshot`: point-in-time KPIs and operational metrics.
- `RiskItem`: active risk records and trend history.
- `DecisionRecord`: architecture/product/process decisions and rationale.
- `ActionItem`: owner-assigned next steps with due dates.

## 2. SDLC Phase To Prompt Mapping

| SDLC Phase | Prompt ID | Core Artifacts |
|---|---|---|
| Intake/Planning | `orchestrator.init.v1` | Project charter, roadmap, risk register, architecture direction, documentation gap report |
| Discovery | `lifecycle.discovery.v1` | User segments, value hypothesis, discovery backlog |
| Planning | `lifecycle.planning.v1` | Milestone plan, WBS, dependency/critical path, reporting template |
| Architecture | `lifecycle.architecture.v1` | Decision matrix, recommended architecture, ADR starter list |
| Implementation | `lifecycle.implementation.v1` | Sprint tasks, DoD criteria, test plan, telemetry plan, rollout plan |
| Validation/Release | `lifecycle.validation.v1` | Release readiness, quality gap analysis, Go/No-Go recommendation |
| Operations/Optimization | `lifecycle.postrelease.v1` | KPI variance analysis, optimization backlog, next milestone recommendations |
| Governance (parallel) | `governance.weekly.v1` | Weekly status report, risk movement, recovery actions |

## 3. Suggested Storage Paths

If file-based storage is preferred, use a deterministic path structure:

- `planning/projects/<project-id>/intake/`
- `planning/projects/<project-id>/discovery/`
- `planning/projects/<project-id>/planning/`
- `planning/projects/<project-id>/architecture/`
- `planning/projects/<project-id>/implementation/`
- `planning/projects/<project-id>/validation/`
- `planning/projects/<project-id>/operations/`
- `planning/projects/<project-id>/governance/`

Inside each phase folder, store:
- `phase-run.json` (metadata: run id, timestamp, operator, model, inputs)
- `artifacts/` (one file per output artifact)
- `actions.json` (owner, due date, status)
- `metrics.json` (if applicable)

## 4. Progress, Risk, Quality, Performance Views

Minimum platform views:

1. Milestone Progress View
   - Inputs: milestone plan + action item status + completion percentage.
   - Output: RAG status and forecast confidence.
2. Risk View
   - Inputs: risk register + weekly governance movement.
   - Output: top risks, trend direction, mitigation completion.
3. Quality View
   - Inputs: test pass rates, defect trends, coverage, release readiness.
   - Output: quality scorecard and release gate status.
4. Performance and Cost View
   - Inputs: SLO metrics, latency/error trends, cost snapshots.
   - Output: optimization priorities and tradeoff recommendations.

## 5. Recommended Metadata For Every Artifact

Attach this metadata to every artifact for traceability:

- `projectId`
- `phase`
- `promptId`
- `runId`
- `timestampUtc`
- `inputRefs` (docs used: vision/prd/milestones/etc.)
- `assumptions`
- `openQuestions`
- `owner`
- `status`

## 6. Intake Validation Before Orchestration

Validate intake payloads with:

- `machine-readable/required-inputs.schema.json`

If validation fails, create a `documentation-gap-report` action list and block transition from Intake to Discovery until minimum fields pass.

## 7. Example Orchestration Loop

1. Validate intake payload.
2. Run `orchestrator.init.v1` and persist outputs.
3. Execute lifecycle prompts in dependency order.
4. Trigger weekly governance run on cadence.
5. Update scorecards and risk trends after each phase run.
6. At release, archive all artifacts and start next cycle from Operations -> Planning.
