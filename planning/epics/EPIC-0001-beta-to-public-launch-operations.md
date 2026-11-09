# EPIC-0001 — ZeroSpoils beta-to-public-launch operations cockpit

**Status:** `todo` (groomed proposal, 2026-11-09). **Epic issue:** [management UI #9](https://github.com/11895079/zerospoils-management-ui/issues/9). **Owner:** ZeroSpoils product/engineering owner; delivery assignments unallocated.

## Outcome and owner journeys

Create one **reliable operations window** using the existing React/Ant Design frontend, Express read APIs and DuckDB marts; **do not build a second dashboard**. It serves a founder operating invited beta cohorts today, preparing iOS/Android public stores, managing the launch's first 48 hours and choosing post-launch features. Must answer: *Is it safe to invite or expand? Where are people getting stuck? Are we actually reducing waste? What needs a human decision or follow-up? Are the app and coding automation healthy?*

This epic spans [M4 beta operations](../milestones/M4/README.md) and [M5 public launch and product learning](../milestones/M5/README.md). Work includes source-contract, privacy and reporting gates **before** polished charts. The UI is observational: no automatic launch, invitations, paid purchases, merges or feature-flag changes.

## Baseline: reuse and gaps

- **Already present:** local-first management UI, React dashboard, Express API, DuckDB marts/ETL, Remote Config foundation and tests from WI-0000–0006; existing GitHub labels/terminal `gh-dash`; ZeroSpoils telemetry export [M5/800](https://github.com/11895079/zerospoils/blob/main/planning/milestones/M5/800-funnel-telemetry-export-make-product-analytics-reachable.md) and KPI script [M5/970](https://github.com/11895079/zerospoils/blob/main/planning/milestones/M5/970-launch-metrics-script-kpi-tree.md).
- **Critical gap:** [M5/861](https://github.com/11895079/zerospoils/blob/main/planning/milestones/M5/861-management-dashboard-reads-mock-data-not-real-telemetry.md) records synthetic telemetry/feedback endpoints. Verify the current end-to-end state before reporting any KPI as live. Do not assume DuckDB mart tests prove the dashboard uses real Firestore.
- **Existing owner-approved separate work:** [management UI issue #8](https://github.com/11895079/zerospoils-management-ui/issues/8) / [ZeroSpoils M6/1111](https://github.com/11895079/zerospoils/blob/main/planning/milestones/M6/1111-live-worker-monitoring-in-the-management-ui.md) owns local worker monitoring; [M6/1107](https://github.com/11895079/zerospoils/blob/main/planning/milestones/M6/1107-worker-agent-metrics.md) owns the agent metric emitter; [ZeroSpoils #1340](https://github.com/11895079/zerospoils/issues/1340) owns **optional** read-only MAF shadow QA. These are dependencies/interfaces, not clones or new worker implementations.
- **Canonical release plans:** [beta launch plan](https://github.com/11895079/zerospoils/blob/main/planning/launch/beta-launch-plan.md), [post-launch playbook](https://github.com/11895079/zerospoils/blob/main/planning/launch/post-launch-playbook.md), [M5/625](https://github.com/11895079/zerospoils/blob/main/planning/milestones/M5/625-launch-metrics-first-48h-monitoring-dashboard.md), plus latest dated owner decisions. Historical dates or thresholds are **not assumed** to be the active launch approval.

## Work breakdown, priorities and links

| Work item | Deliverable | Stage | Priority | Status | GitHub | Dependencies |
| --- | --- | --- | --- | --- | --- | --- |
| [WI-0007](../workitems/WI-0007-live-source-lineage-kpi-contracts.md) | Verify live source lineage, KPI definitions and mock isolation | M4 | P0 | `todo` | [#10](https://github.com/11895079/zerospoils-management-ui/issues/10) | WI-0002 |
| [WI-0008](../workitems/WI-0008-privacy-safe-read-api-and-freshness.md) | Enforce privacy-safe read API, source freshness and access boundaries | M4 | P0 | `todo` | [#11](https://github.com/11895079/zerospoils-management-ui/issues/11) | WI-0007 |
| [WI-0009](../workitems/WI-0009-beta-control-room-and-wave-gates.md) | Build beta wave command center and GO/HOLD/HALT scorecard | M4 | P0 | `todo` | [#12](https://github.com/11895079/zerospoils-management-ui/issues/12) | WI-0007, WI-0008 |
| [WI-0010](../workitems/WI-0010-beta-invitations-installation-funnel.md) | Track invitation, distribution and installation funnel by cohort | M4 | P1 | `todo` | [#13](https://github.com/11895079/zerospoils-management-ui/issues/13) | WI-0007, WI-0009 |
| [WI-0011](../workitems/WI-0011-product-activation-feature-adoption.md) | Report activation, reminders, inventory, shopping, receipts and backup journeys | M4 | P1 | `todo` | [#14](https://github.com/11895079/zerospoils-management-ui/issues/14) | WI-0007, WI-0009 |
| [WI-0012](../workitems/WI-0012-feedback-support-incident-desk.md) | Create feedback, support, incidents and severity/response desk | M4 | P0 | `todo` | [#15](https://github.com/11895079/zerospoils-management-ui/issues/15) | WI-0007, WI-0008 |
| [WI-0013](../workitems/WI-0013-release-health-build-ledger-go-no-go.md) | Build release health, crash/data-loss risk, build ledger and gates | M4 | P0 | `todo` | [#16](https://github.com/11895079/zerospoils-management-ui/issues/16) | WI-0009, WI-0012 |
| [WI-0014](../workitems/WI-0014-daily-weekly-owner-decision-reports.md) | Produce owner daily/weekly beta reports and evidence-backed decisions | M4 | P0 | `todo` | [#17](https://github.com/11895079/zerospoils-management-ui/issues/17) | WI-0009, WI-0012, WI-0013 |
| [WI-0015](../workitems/WI-0015-live-worker-monitoring-in-management-ui.md) | Integrate existing live-worker monitoring into launch operations | M4 | P1 | `todo` | [#8](https://github.com/11895079/zerospoils-management-ui/issues/8) | WI-0008 |
| [WI-0016](../workitems/WI-0016-maf-shadow-review-evaluation-view.md) | Visualize optional MAF shadow-review evaluations and QA comparison | M4 | P2 | `todo` | [#18](https://github.com/11895079/zerospoils-management-ui/issues/18) | WI-0008, WI-0009 |
| [WI-0017](../workitems/WI-0017-public-launch-staged-rollout-first-48h.md) | Run staged public-launch and first-48h operations cockpit | M5 | P1 | `todo` | [#19](https://github.com/11895079/zerospoils-management-ui/issues/19) | WI-0013, WI-0014 |
| [WI-0018](../workitems/WI-0018-retention-food-waste-value-and-learning.md) | Analyze real retention, food-waste outcomes and feature value by cohort | M5 | P1 | `todo` | [#20](https://github.com/11895079/zerospoils-management-ui/issues/20) | WI-0011 |
| [WI-0019](../workitems/WI-0019-growth-referral-pro-monetization-forecast.md) | Report consented acquisition, referral and Pro monetization when available | M5 | P2 | `todo` | [#21](https://github.com/11895079/zerospoils-management-ui/issues/21) | WI-0010, WI-0018 |

**Critical beta path:** 0007 → 0008 → 0009; in parallel after 0008, 0012; then 0013 → 0014. WI-0010 and 0011 give campaign and behavior insights as sources permit; WI-0015/#8 adds worker monitoring without blocking beta safety, and WI-0016 is experimental and never a beta gate. M5 requires the M4 source/quality and owner decision foundations.

## Feature and operational reporting coverage

| Product / operations domain | Capabilities and planned areas | Reporting items | Source integrity rule |
| --- | --- | --- | --- |
| Launch distribution | Loops waitlist, beta invitations, /beta landing page, TestFlight, Firebase App Distribution; App/Play later | WI-0010, WI-0017 | Real source-specific counts; no inferred email-to-install identity |
| First-use and education | First run, onboarding goals/household, tour, tip deck, demo content, update notices | WI-0009, WI-0011, WI-0018 | Onboarding, first item and time-to-value; reflect uninstrumented steps |
| Inventory and expiry | Item add/edit, fridge/pantry/freezer/other, best-before, consumption, discard, expiration reminders | WI-0011, WI-0018 | Dated items, reminders, outcomes; no savings claim without baseline |
| Shopping and trips | Shopping list, purchase/use insights, store/date receipt linking, optional deals nudge | WI-0011, WI-0018 | Use action events only when released and exported |
| Receipt intelligence | Single/batch receipt import, camera/OCR, parsed lines, review, image/file import | WI-0011, WI-0018 | Capture-to-review completion and failures; no receipt-content upload |
| Backup and resilience | Google Drive and iCloud backup (where implemented), restore, device handover, offline-first | WI-0011, WI-0013 | Coverage, restore failures, confirmed loss; planned paths not assumed working |
| Engagement and value | Notifications, streak/badges, share/referral, food waste baseline, surveys/consented quotes | WI-0011, WI-0018, WI-0019 | D1/D7/W4, actions and validated outcomes with consent |
| Beta voice and support | In-app feedback, email, TestFlight/Firebase feedback, GitHub beta issues | WI-0012, WI-0014 | Triage backlog, severity, response latency, incidents |
| Release / safety / privacy | Crashlytics, builds, Remote Config, min version, telemetry freshness, consent, account deletion, store privacy | WI-0008, WI-0013, WI-0017 | Human gates, verified evidence, stale/error labels |
| Future / Pro / expansion | Household sync, paid subscription/entitlements, advanced analytics, recipes, food-quality lenses, donations, deals, geofencing, IoT | WI-0018, WI-0019 | Coverage flags; no adoption/revenue for a deferred feature |
| Engineering automation | GitHub queue, local worker heartbeat, provider budgets/leases, preflight/reviewer cycles | WI-0015, WI-0014 | Existing #8, M6/1107; not a new worker |
| Agentic review experiment | Optional MAF shadow cross-review quality/cost, owner adoption gate | WI-0016 | ZeroSpoils #1340 remains implementation owner |

**Every feature tile** must show: `feature_status` (released/in beta/flagged-off/planned), `instrumentation_status` (observed/partial/none), source and metric definition version, event timestamp/data freshness, platform/build/cohort, eligible denominator, known opt-out/offline limitation and uncertainty. A zero is an **observed zero only when data is complete**; absent telemetry must be unknown.

## KPI contract and data boundaries

**Beta leading/safety measures:** invitations sent/delivered/clicked (Loops); invite acceptance/install source by platform (TestFlight/Firebase); first open/onboarding completion/first item/5 dated items; reminder schedule/open, shopping/receipt/backup and support actions **only if instrumented**; D1/D7 mature-cohort return; crash-free users with sample size (Crashlytics); confirmed data loss; P0/P1 backlog, response SLA, kill switch/version drill; ingestion lag and schema reject rate (actual counts). Support the beta plan's **current owner-approved** gate thresholds; do not silently translate an older gate into the current one.

**Full-launch and durable measures:** actual App Store/Play rollout and adoption, crash-free and performance by build, public feedback/store reviews, W4 retention and weekly meaningful action, cohort value/outcomes, privacy/consent and account deletion operational status, partner/paid features **only where a genuine source exists**. Report manual console evidence when an API/terms/approval gap blocks automation.

**Sources and authority:** Firestore telemetry export and feedback, DuckDB ETL, local KPI script, Crashlytics, Loops, TestFlight/Firebase App Distribution, App Store Connect/Play Console, Remote Config audit, PostHog only when separately consented and masked, GitHub PR/CI/runner state, local worker status/event JSONL and optional MAF #1340. Link to original artifacts; keep raw tester emails, purchase records, inventory contents, prompts and traces outside aggregated UI where not permitted.

**Consent and truthfulness:** No unapproved cross-service identity joining, cross-client memory, raw tester PII export, replay exfiltration, demo production tokens, fabricated savings or prices, or estimates disguised as actuals. Production data-mode defaults to verified real sources; absent credentials/ingestion report `unknown` or `unavailable`. Metrics must preserve source window, denominator, timezone, delay and version.

## Release gates, owner decision and fallback

- **Gate Beta-A (P0):** 0007/0008/0009/0012/0013/0014 verify source-backed safety/decision evidence. The owner decides **GO/HOLD/HALT** with a dated source snapshot; `scripts/launch_metrics.py` and direct consoles remain the safe fallback if the web UI is unavailable.
- **Gate Beta-B (learning):** 0010/0011 expose actual funnel and feature-value gaps; poor instrumentation blocks **claims**, not the required safety response.
- **Gate Public-C:** 0017 validates staged distribution, privacy/device release evidence and first-48h control room under the existing release runbooks. No store submission or rollout occurs automatically.
- **Gate Learning-D:** 0018 evaluates measured waste reduction and retention, and 0019 activates revenue/growth metrics **only** after actual sources/entitlements and separate commercial approval.

## Acceptance of the epic

- [ ] All P0 live-data, security and beta decision views link to verified real evidence; no synthetic default and no ambiguous missing-data state.
- [ ] A real rehearsal of both platform release channels and a confirmed P0 incident yields an explainable HOLD/HALT; human owner decisions are logged separately.
- [ ] D1/D7, onboarding/first item/reminder, backup/receipt, feedback and crash risk measures have tested denominators and cohort windows or explicit `not measured` states.
- [ ] The UI reuses existing worker monitoring #8 and has a nonblocking optional MAF evaluation page, without reimplementing worker/MAF.
- [ ] Public launch control room produces evidence-backed first 48h and week-one reports; growth and savings claims remain gated on actual sources.
- [ ] RBAC, redaction, per-source privacy, schema evolution, fixtures and source outages pass automated and manual tests; independent owner approval is retained.

## Implementation rule

Treat this as a plan, not a blanket dispatch. Each child workitem requires separately scoped authorization, tests written first, independent review and an owner-controlled merge. Do not change the live app or invite users under an analytics epic alone.
