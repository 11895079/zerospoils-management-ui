## Context
Android beta distribution can run through Firebase App Distribution, but the roadmap does not yet define how tester feedback, screenshots, and build metadata should be retrieved and turned into actionable triage artifacts. Firebase App Distribution supports tester feedback workflows that can reduce manual console copying and preserve context from real-device reports.

## Goal
Define and implement a repeatable workflow for collecting Firebase App Distribution tester feedback, normalizing it into actionable triage records, and linking it to ZeroSpoils beta-release operations.

## Expected behavior
- Testers on Firebase App Distribution can submit feedback with screenshots from installed beta builds
- The team has a documented path to retrieve tester feedback using supported Firebase workflows, APIs, or exports
- Retrieved feedback is normalized into a lightweight triage format that includes app version, platform, build identifier, tester message, screenshot reference, and triage state
- Android beta instructions tell testers how to submit useful feedback during closed testing
- Feedback review does not depend on ad hoc console scraping or copy/paste from multiple places

## Acceptance criteria (Definition of Done)
- [ ] Document the Firebase App Distribution tester-feedback workflow in `docs/beta-android-feedback.md`, including supported Firebase capabilities and any API limitations
- [ ] Decide and document the retrieval path for tester feedback: official API, console export, email relay, or a scripted fallback if direct API coverage is limited
- [ ] Define a normalized feedback schema covering `platform`, `build_version`, `build_number`, `release_channel`, `message`, `screenshot_reference`, `submitted_at`, and `triage_status`
- [ ] Provide a lightweight script or operational runbook to fetch or export feedback and transform it into the normalized schema
- [ ] Document how normalized feedback maps into GitHub issues, milestone tracking, or another triage surface used by the team
- [ ] Tester instructions for Firebase-distributed builds include feedback-submission guidance and what details to include
- [ ] Security and privacy guidance covers access control, retention, and removal of unnecessary personal identifiers
- [ ] Unit or script-level tests added where transformation logic exists
- [ ] Operational logging or telemetry added only where needed to confirm retrieval or transformation success
- [ ] Offline-first behavior verified where applicable for the in-app side of the feedback path

## Out of scope
- Replacing the in-app feedback entry point defined in M4/280 and M4/285
- iOS TestFlight feedback automation
- Full CRM or helpdesk integration
- Public-launch support tooling

## Implementation notes
- Treat this as an operations and tooling issue first; product UX changes should stay minimal
- If Firebase does not expose the exact API surface needed, document the gap explicitly and use the least-fragile supported fallback instead of inventing an unsupported integration
- Keep the normalized schema simple enough to map into GitHub issues or a spreadsheet without additional backend work
- Prefer idempotent retrieval so repeated runs do not duplicate the same tester submission in triage output
- Reuse build identifiers defined in the Android beta process so feedback ties back to a specific release candidate cleanly

## Test plan
**Automated:**
- Script test: sample Firebase feedback payload or export row converts into the normalized feedback schema correctly
- Script test: duplicate feedback records do not produce duplicate normalized entries on re-run

**Manual:**
1. Distribute an Android beta build through Firebase App Distribution and verify tester instructions mention how to submit feedback
2. Submit test feedback with a screenshot from a tester device and confirm it appears in the chosen retrieval path
3. Run the documented retrieval or export workflow and verify the normalized output includes message, build metadata, and screenshot reference
4. Convert one feedback item into a GitHub issue or triage artifact and verify the mapping is documented and repeatable
5. Review the workflow for privacy exposure and verify no unnecessary tester identifiers are retained in the triage output

## Dependencies
- M4/270 Android beta distribution setup
- M4/280 in-app feedback entry point
- M4/285 settings feedback entry
- M4/370 closed-testing backend security hardening where Firebase permissions or configuration are involved
