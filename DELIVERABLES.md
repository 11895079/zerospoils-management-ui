# ZeroSpoils Deliverables Index

Last Updated: April 18, 2026

This file replaces the old session snapshot from 2025. It now serves as a stable index of where current deliverables live.

## Primary Deliverable Areas

| Area | Path | What it contains |
|---|---|---|
| App implementation | `app/` | Flutter source, tests, platform projects |
| Planning and specs | `planning/` | Milestone issue specs, roadmap, implementation guidance |
| Developer docs | `docs/` | Release, architecture, UX, telemetry, platform guides |
| Telemetry contracts and tools | `telemetry/` | Event schemas, fixtures, validation tools, policies |
| Executive briefings | `docs/executive-briefings/` | Time-stamped executive reports (Markdown and PDF) |

## Current Milestone Status Sources

Use these files for up-to-date milestone completion and acceptance status:

1. `planning/milestones/M1/README.md`
2. `planning/milestones/M2/README.md`
3. `planning/milestones/M3/README.md`
4. `planning/milestones/M4/README.md`

## Validation and Quality Sources

1. CI and test definitions: `app/README.md`, `.github/workflows/`
2. Telemetry validation: `telemetry/README.md`, `telemetry/tools/`
3. Release process: `docs/release.md`, `docs/ANDROID_SIGNING_GUIDE.md`

## Maintenance Rule

When implementation status changes:

1. Update the relevant issue and milestone README in `planning/milestones/`.
2. Regenerate executive briefing artifacts if needed.
3. Keep this file as an index only (no long-lived status snapshots).
