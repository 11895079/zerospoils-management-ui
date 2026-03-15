# Project Bootstrap Prompt Kit

This folder contains reusable prompts for spinning up software development projects in a consistent, operator-friendly way.

The kit is designed for:
- Human operators running projects repeatedly with a clear process.
- Vibe engineering platforms that need structured prompts and deterministic follow-on flows.

## End-To-End SDLC Coverage

This kit is intended to guide a project through the full SDLC:

1. Intake and context capture
2. Discovery and validation
3. Planning and milestone definition
4. Architecture and design decisions
5. Implementation planning and execution
6. Testing, quality, and release readiness
7. Release, post-release monitoring, and optimization
8. Handoff, scaling, and continuous governance

The prompts are sequenced so operators can repeat the same workflow across projects while preserving traceability.

## Folder Structure

- `00-master-orchestrator.md`: Primary prompt that starts and governs the full process.
- `01-lifecycle-prompts.md`: Reusable prompts for each delivery phase.
- `02-follow-on-by-project-type.md`: Follow-on prompts by project type.
- `03-tracking-and-governance-prompts.md`: Prompts for milestones, risks, progress, quality, performance.
- `04-handoff-and-scaling-prompts.md`: Prompts for handoffs, onboarding, and scaling teams.
- `templates/`: Output templates that the prompts ask the AI to produce.
- `machine-readable/`: JSON assets for platform orchestration, prompt routing, and input validation.
- `platform-output-mapping.md`: SDLC output-to-data-model mapping for platform storage and dashboards.

## Required Inputs And Documentation

Yes, this kit now explicitly covers documentation and required inputs such as PRD and Vision artifacts.

Minimum recommended inputs before running the full flow:
- Vision document (purpose, target outcome, strategic fit)
- PRD (users, requirements, constraints, acceptance criteria)
- Scope and milestone draft
- Architecture constraints and technology preferences
- Security/compliance requirements
- Telemetry and KPI expectations
- Release and operations constraints

If inputs are missing, the orchestrator prompts generate a gap report and discovery tasks.

### Mapping To This Repository's Planning Model

The kit is compatible with artifacts commonly stored under planning-style structures like this repo:
- Vision and strategy docs
- PRD and product docs
- Milestone issue definitions
- Architecture notes and diagrams
- Telemetry taxonomy and schemas
- Release and operational checklists

## Standard Workflow

1. Use `00-master-orchestrator.md` to initialize a project.
2. Generate baseline artifacts using templates under `templates/`.
3. Run lifecycle prompts from `01-lifecycle-prompts.md` in sequence.
4. Inject the project-type prompt set from `02-follow-on-by-project-type.md`.
5. Continuously run governance prompts from `03-tracking-and-governance-prompts.md`.
6. Use handoff prompts from `04-handoff-and-scaling-prompts.md` for transitions.

## Machine-Readable Integration

Use files in `machine-readable/` to integrate this kit into a vibe engineering platform:
- `prompt-registry.json`: Prompt catalog with IDs, phases, dependencies, and required inputs.
- `workflow.json`: SDLC state machine defining phase order and transitions.
- `required-inputs.schema.json`: JSON schema to validate intake payloads (Vision, PRD, constraints, KPIs).
- `sample-intake.json`: Example payload that satisfies the intake schema.
- `resolve-next-prompts.ps1`: Lightweight runner that prints prompt sequence and project-type follow-on route.

Integration pattern:
1. Validate intake payload with `required-inputs.schema.json`.
2. Resolve initial prompt route from `workflow.json`.
3. Execute prompts from `prompt-registry.json` in dependency order.
4. Persist outputs as milestone snapshots and governance records.

Quick-start commands (PowerShell from `project-bootstrap-prompt-kit/machine-readable/`):

```powershell
# Show sequence for a mobile project with governance track
./resolve-next-prompts.ps1 -ProjectType mobile -IncludeGovernance

# Show sequence for a backend project
./resolve-next-prompts.ps1 -ProjectType backend
```

## Recommended Platform Integration Pattern

For a guided platform flow:
- Step 1: Intake
  - Ask project type, scope, users, constraints, and success metrics.
- Step 2: Plan Generation
  - Run master orchestrator to produce roadmap, milestones, risks, and architecture.
- Step 3: Execution Loop
  - Re-run planning, implementation, and quality prompts each cycle.
- Step 4: Governance Loop
  - Re-run risk, progress, and performance prompts at fixed cadence.
- Step 5: Release and Post-Release
  - Use release-readiness, launch, and retrospective prompts.

## How To Reuse For Any New Project

1. Copy this folder into the target repository.
2. Fill placeholders in prompts (project type, constraints, timeline, team size).
3. Run prompts in the listed order.
4. Store all generated outputs in a dedicated `planning/` or `project/` folder.
5. Repeat the same loop each milestone or sprint.

## Prompting Conventions

All prompts in this kit use:
- Role context
- Input schema
- Required outputs
- Quality gate checks
- Suggested next prompts

This keeps runs deterministic and reusable across teams and projects.
