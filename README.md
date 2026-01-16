# ZeroSpoils Monorepo

Flutter mobile app for household food waste reduction.

## Folder Structure

\\\
.
├── planning/          # Backlog, milestones, documentation
│   ├── issues/        # Issue markdown files (numbered 000-590)
│   ├── milestones/    # Issues grouped by M1-M7 delivery phases
│   ├── docs/          # Architecture, design, data model, telemetry
│   ├── scripts/       # Automation: label/milestone creation
│   ├── AGENTS.md      # AI coding agent workflow guide
│   └── requirements.txt
│
├── app/               # Flutter application (main branch + feature branches)
│   ├── lib/           # Dart source code
│   ├── test/          # Unit & widget tests
│   ├── pubspec.yaml   # Flutter dependencies
│   └── ...
│
└── README.md          # This file
\\\

## Quick Start

### 1. Planning & Backlog
All backlog grooming, issue definitions, and documentation live in \planning/\. See [planning/README.md](planning/README.md) for:
- Bulk issue creation workflow
- Milestone structure (M1-M7)
- Label/milestone setup scripts

### 2. App Implementation
Implementation happens in \pp/\ folder. Create feature branches off \main\:
\\\ash
git checkout -b feature/item-inventory
# ... implement using planning/issues/* as your spec
# ... commit with small, focused PRs
\\\

## Workflow for Implementation

1. **Select Issue** from \planning/milestones/M1/\ (or relevant milestone)
2. **Read Issue** – acceptance criteria + test plan are your spec
3. **Create Feature Branch**: \git checkout -b feature/xxx\
4. **Implement in \pp/\** – code + tests + telemetry per DoD
5. **Submit PR** linking back to planning issue
6. **Update Issue** status in planning/ when merged

## CI/CD Strategy

- **Planning changes**: Lint markdown, validate issue structure
- **App changes**: Run tests on \pp/\ path only (don't re-test planning docs)
- **Feature branches**: Small PRs implementing one issue at a time

## References
- [planning/AGENTS.md](planning/AGENTS.md) – AI coding agent instructions
- [planning/README.md](planning/README.md) – Backlog details
- [planning/milestones/M1/README.md](planning/milestones/M1/README.md) – First milestone guide