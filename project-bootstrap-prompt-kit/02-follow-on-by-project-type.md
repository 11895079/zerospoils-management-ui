# 02 - Follow-On Prompts By Project Type

Select the project type and run the matching prompts after the master orchestrator.

## 1. Mobile App (Flutter/React Native/Native)

```text
Act as a Mobile Platform Lead.

Given this mobile project context:
<CONTEXT>

Produce:
1) Mobile architecture (offline strategy, sync strategy, state management)
2) Platform parity plan (iOS/Android capability matrix)
3) Performance budget (startup time, frame time, memory)
4) Release channel strategy (internal, beta, production)
5) Device testing matrix (OS versions, screen sizes, network conditions)
```

Follow-on:
- Generate app module boundaries and navigation map.
- Generate mobile telemetry event taxonomy.

## 2. Web App (SPA/SSR/Static + APIs)

```text
Act as a Senior Web Architect.

Using this context:
<CONTEXT>

Create:
1) Frontend architecture and rendering strategy (CSR/SSR/SSG)
2) API boundary design and contract strategy
3) Accessibility baseline and testing plan
4) Core Web Vitals performance budget
5) Security controls (auth, session, CSP, input validation)
```

Follow-on:
- Generate frontend component system roadmap.
- Generate API versioning and deprecation strategy.

## 3. Backend/API Platform

```text
Act as a Principal Backend Engineer.

Given the project requirements:
<CONTEXT>

Produce:
1) Service decomposition and domain boundaries
2) API style guide (REST/GraphQL/gRPC) and contract governance
3) Data model and persistence strategy
4) Reliability plan (timeouts, retries, idempotency, DLQs)
5) SLOs and incident response runbook baseline
```

Follow-on:
- Generate endpoint-level test strategy.
- Generate production observability dashboard specification.

## 4. Data/AI Product

```text
Act as an AI/ML Product Engineering Lead.

Inputs:
<CONTEXT>

Produce:
1) Data pipeline architecture and ownership boundaries
2) Dataset quality and governance framework
3) Model lifecycle plan (training, evaluation, deployment, monitoring)
4) Responsible AI controls (bias, safety, explainability, privacy)
5) Cost/performance optimization strategy for inference and storage
```

Follow-on:
- Generate evaluation benchmark plan.
- Generate model rollback and incident response playbook.

## 5. SaaS Product (Multi-tenant)

```text
Act as a SaaS Platform Architect.

Given this context:
<CONTEXT>

Provide:
1) Tenant isolation model and access controls
2) Billing/metering architecture and events
3) Provisioning and onboarding workflow
4) Feature flag and packaging strategy (tiers/plans)
5) Operational model for scale and noisy-neighbor risks
```

Follow-on:
- Generate tenancy migration strategy.
- Generate account lifecycle and retention controls.

## 6. DevTool / Internal Platform

```text
Act as an Internal Developer Platform Lead.

Using this context:
<CONTEXT>

Produce:
1) Golden paths and developer experience principles
2) Self-service architecture (templates, automation, policy checks)
3) Platform reliability and support model
4) Adoption strategy (metrics, change management, enablement)
5) Governance model (security, compliance, cost visibility)
```

Follow-on:
- Generate platform scorecard for adoption and productivity.
- Generate migration waves for existing teams.
