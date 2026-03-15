# 03 - Tracking And Governance Prompts

Use these prompts weekly (or per sprint) to maintain delivery control.

## 1. Milestone Health Prompt

```text
Act as a Program Governance Lead.

Inputs:
- Current milestone plan
- Completed work
- Blockers and unresolved dependencies

Generate:
1) Milestone health summary (RAG per milestone)
2) Variance analysis (planned vs actual)
3) Recovery actions for at-risk milestones
4) Owner-assigned action list with due dates
```

## 2. Risk Review Prompt

```text
Act as an Engineering Risk Manager.

Inputs:
- Existing risk register
- New incidents/issues
- Team and dependency changes

Produce:
1) Updated top risks (with movement: up/down/flat)
2) New emerging risks and triggers
3) Mitigation effectiveness review
4) Escalation recommendations
```

## 3. Progress And Throughput Prompt

```text
Act as a Delivery Performance Analyst.

Inputs:
- Backlog status
- Velocity/cycle time/lead time metrics
- Defect trends

Provide:
1) Throughput trend summary
2) Bottleneck diagnosis
3) Forecast of completion confidence
4) Priority rebalancing recommendations
```

## 4. Quality And Reliability Prompt

```text
Act as a Quality Engineering Lead.

Inputs:
- Test pass rates
- Coverage trends
- Incident/error budgets

Produce:
1) Quality scorecard
2) Reliability scorecard vs SLOs
3) Critical quality gaps and required fixes
4) Recommendation: continue, pause, or harden
```

## 5. Performance And Cost Prompt

```text
Act as a Performance and Cost Optimization Lead.

Inputs:
- Latency/throughput/error metrics
- Infra and service costs
- Capacity/utilization data

Generate:
1) Performance trend report
2) Cost drivers and optimization opportunities
3) Tradeoff options (cost vs speed vs reliability)
4) 2-week optimization action plan
```
