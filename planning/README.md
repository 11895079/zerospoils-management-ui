# Planning & Backlog

This folder contains all issue definitions, milestones, and supporting documentation for ZeroSpoils development.

## Structure

- `issues/` – Standalone and backlog issue files that are not the active milestone source of truth
- `milestones/` – Issues organized by delivery milestone (M1-M7); milestone folders and milestone READMEs are the authoritative planning view for active work
- `docs/` – Architecture, design, and requirements documentation
- `scripts/` – Automation helpers (label creation, milestone setup)
- `AGENTS.md` – Instructions for AI coding agents
- `requirements.txt` – Python dependencies for doc conversion utilities

## Quick Links

- **M1 (Foundations)** – Repo setup, CI, Flutter skeleton, foundational docs
- **M2 (Build & Early Features)** – iOS/Android pipelines, recipe POC
- **M3 (MVP)** – Core features: inventory, shopping list, notifications
- **M4 (Polish & Launch)** – UX refinement, accessibility, performance
- **M5+ (Advanced)** – Pro features, ML pipeline, sync

See [milestones/](milestones/) for detailed README files for each milestone.

## Numbering Note

Issue numbers are maintained in 10-step increments within the planning system, but the current repository contains both standalone backlog files and milestone-scoped files. When a discrepancy exists, prefer the milestone copy and the milestone README status table.

## Issue Format

All issues follow a standard template:
```markdown
# Title

## Goal
What we're building and why.

## Expected Behavior
Concrete description of functionality.

## Acceptance Criteria
Checkbox list (Definition of Done).

## Out of Scope
What's explicitly NOT included.

## Implementation Notes
Technical guidance and decisions.

## Test Plan
Automated tests + manual verification steps.

## Dependencies
Links to blocking issues or prerequisites.
```

## Bulk Issue Creation

Once you're ready to create all issues in GitHub:

1. Install GitHub CLI: https://cli.github.com/
2. Authenticate: `gh auth login`
3. Create milestones/labels (optional):
   ```bash
   bash scripts/create_milestones.sh
   bash scripts/create_labels.sh
   ```
4. Bulk create issues from `issues.csv` (if available) or manually point to issue files

## Using Issues for Implementation

1. Open issue file (e.g., `milestones/M1/000-*.md`)
2. Read **Goal**, **Acceptance Criteria**, and **Test Plan**
3. Use these as your implementation spec in the `app/` folder
4. Create feature branch: `git checkout -b feature/descriptive-name`
5. Implement code + tests in `app/`
6. Submit PR linking to this issue
7. Mark issue complete when PR merges

## Notes for AI Agents

- Each issue is designed to be a self-contained work unit
- Acceptance criteria = your implementation checklist
- Test plans are concrete and automatable (not generic advice)
- Definition of Done includes: tests, telemetry, offline-first checks, accessibility basics
- Keep PRs small: one issue per branch, focused changes

## Editing & Maintenance

When adding/editing issues:
- Follow 10-step numbering (000, 010, 020...) to allow future insertions
- Include concrete test plans (never leave stubs)
- Ensure dependencies are documented
- Update milestone README when moving issues between milestones

See [AGENTS.md](AGENTS.md) for detailed AI agent workflow.
