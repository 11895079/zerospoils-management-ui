# WI-0008: Enforce privacy-safe read API, source freshness and access boundaries

## Metadata

- Status: `todo`
- Milestone: `M4`
- Epic: [EPIC-0001](../epics/EPIC-0001-beta-to-public-launch-operations.md)
- Owner: `unassigned`
- Priority: `P0`
- Size: `M` (estimate; refine after source spike)
- Dependencies: `WI-0007`
- Linked Issue: [#11](https://github.com/11895079/zerospoils-management-ui/issues/11)

## Context

Beta owner reports combine multiple services that may contain emails, device identifiers, user events and restricted material. The management UI has admin/analyst/support scaffolding but demo credentials are not production authentication.

## Goal / user outcome

As a ZeroSpoils launch operator, I can enforce privacy-safe read API, source freshness and access boundaries with traceable source evidence and no invented or sensitive reporting.

## Scope and source boundaries

- Classify per-source identity/PII, consent, purpose, role and retention; aggregate per permissible cohort and suppress tiny or re-identifiable slices.
- Enforce RBAC server-side on source adapters; implement a separate read-only role for cockpit use and deny unknown/expired tokens and forbidden cross-project resources.
- Provide source/last-refresh/status/error provenance in all UI cards and exports; clear stale/partial/no-data states and no data exfiltration via logs, URLs or telemetry.
- Require configured production secrets, no README fixture tokens accepted outside local development; protect event and MAF evaluation fields from disclosure.
- Document manual-only consoles (Crashlytics, Loops, TestFlight, PostHog) that cannot be safely automated; deep-link without scraping privileged data.

## Acceptance criteria

- [ ] Classify per-source identity/PII, consent, purpose, role and retention; aggregate per permissible cohort and suppress tiny or re-identifiable slices.
- [ ] Enforce RBAC server-side on source adapters; implement a separate read-only role for cockpit use and deny unknown/expired tokens and forbidden cross-project resources.
- [ ] Provide source/last-refresh/status/error provenance in all UI cards and exports; clear stale/partial/no-data states and no data exfiltration via logs, URLs or telemetry.
- [ ] Require configured production secrets, no README fixture tokens accepted outside local development; protect event and MAF evaluation fields from disclosure.
- [ ] Document manual-only consoles (Crashlytics, Loops, TestFlight, PostHog) that cannot be safely automated; deep-link without scraping privileged data.

## Out of scope

No new universal IAM, storing raw replay/prompt/secret data, production password shortcuts or cross-user identity stitching without consent.

## Test plan

**Automated (test-first):**
- `test_default_demo_credentials_denied_in_deployed_mode`
- `test_readonly_role_cannot_mutate_remote_config`
- `test_small_cohort_and_sensitive_identifiers_redacted`
- `test_source_error_and_stale_not_reported_healthy`

**Manual:**
1. Sign in as an authorized analyst and a restricted support user and request a small-cohort report with a synthetic tester identifier. Expected: only approved aggregate data is shown, restricted users see denial and no sensitive ID appears in logs or exports.

## Definition of done

- [ ] Positive, negative, source-freshness and consent cases tested; failing tests precede implementation.
- [ ] Dashboard and API agree on the versioned metric definitions; no mock data is passed as live.
- [ ] Owner reviews read permissions, source lineage and evidence links for representative beta fixtures.
- [ ] Docs and on-call/runbook links updated; implementation PR reviewed and merged by owner.
