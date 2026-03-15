# 01 - Lifecycle Prompts

Run these prompts in order, then repeat planning/execution/review in cycles.

## A. Discovery Prompt

```text
Act as a Staff Product Strategist.

Given this project context:
<PASTE_PROJECT_CONTEXT>

Produce:
1) User segments and top jobs-to-be-done
2) Problem statements and evidence gaps
3) Value hypothesis and measurable outcomes
4) Discovery backlog (interviews, prototypes, experiments)
5) Decision log template for discovery findings

Output format:
- Table for user segments
- Prioritized list of unknowns with validation method
- 2-week discovery plan
```

## B. Planning Prompt

```text
Act as a Technical Program Manager.

Inputs:
- Discovery outcomes
- Constraints and deadlines
- Team profile

Create:
1) Milestone plan with entry/exit criteria
2) Work breakdown structure (epics, features, tasks)
3) Dependency graph and critical path
4) Capacity-based timeline estimate
5) Delivery risks and fallback options

Also provide:
- RAG status criteria definition (Red/Amber/Green)
- Weekly status reporting template
```

## C. Architecture Prompt

```text
Act as a Principal Software Architect.

Inputs:
- Functional requirements
- Non-functional requirements (performance, reliability, security)
- Constraints

Generate:
1) Candidate architecture options (at least 2)
2) Decision matrix with tradeoffs
3) Recommended architecture and why
4) Domain model and integration boundaries
5) Data flow, failure modes, and resilience controls

Include:
- ADR starter list (Architecture Decision Records)
- Technical spikes needed before implementation
```

## D. Implementation Prompt

```text
Act as an Engineering Lead enforcing high quality delivery.

Given the approved architecture and milestone backlog:
1) Create sprint-ready implementation tasks
2) Add explicit Definition of Done per task
3) Add test-first plan (unit, integration, end-to-end)
4) Identify telemetry events and metrics for each feature
5) Define rollout strategy (feature flags, canary, rollback)

Output constraints:
- Tasks must be estimable and testable
- Every task must include acceptance criteria
- Every feature must include observability requirements
```

## E. Validation Prompt

```text
Act as a Quality and Reliability Lead.

Inputs:
- Implemented features and tests
- Performance and observability data

Produce:
1) Release readiness assessment
2) Defect and risk triage matrix
3) Coverage and quality gap analysis
4) Reliability checklist pass/fail
5) Go/No-Go recommendation with rationale

At the end include:
- Mandatory fixes before release
- Optional improvements after release
```

## F. Post-Release Prompt

```text
Act as a Product and Operations Analyst.

Inputs:
- Usage telemetry
- Incident and support data
- KPI baseline and target

Produce:
1) 30/60/90 day impact review
2) KPI variance analysis (target vs actual)
3) Risk and incident trend summary
4) Optimization backlog (performance, UX, reliability)
5) Recommendations for next milestone scope
```
