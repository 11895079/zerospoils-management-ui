# ZeroSpoils Monorepo

Flutter mobile app for household food waste reduction.

## Folder Structure

```
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
├── docs/              # Developer guides & walkthroughs
│   ├── flutter-basics.md       # Dart/Flutter fundamentals for beginners
│   ├── code-patterns.md        # Practical patterns & code examples
│   └── gradle-guide.md         # Android build system guide
│
├── ARCHITECTURE.md    # System architecture & design overview
├── PRE-COMMIT.md      # Git hooks & pre-commit checks
└── README.md          # This file
```

## Quick Start

### 1. Clone & Setup
```bash
git clone https://github.com/bakintunde/zerospoils.git
cd zerospoils

# Install Git hooks (format & lint checks)
bash scripts/setup-hooks.sh      # Linux/macOS
# OR
scripts\setup-hooks.bat           # Windows
```

### 2. Understanding the Codebase (New Developers)

**Start here if you're new to Flutter or this codebase:**

1. **[ARCHITECTURE.md](ARCHITECTURE.md)** (12 min read)
   - Overview of clean architecture
   - Key technologies (GoRouter, Riverpod, Hive)
   - How data flows through the app
   - Common patterns explained

2. **[docs/flutter-basics.md](docs/flutter-basics.md)** (8 min read)
   - Dart syntax fundamentals
   - Flutter widget concepts
   - State management basics
   - Hot reload & development tips

3. **[docs/code-patterns.md](docs/code-patterns.md)** (10 min read)
   - Practical patterns with code examples
   - Navigation, state management, UI components
   - Testing patterns
   - Error handling

4. **[docs/gradle-guide.md](docs/gradle-guide.md)** (5 min read)
   - Android build system explanation
   - Common build errors and fixes
   - When you encounter Gradle issues

**Total time: ~35 minutes to fully understand the codebase**

### 3. Planning & Backlog
All backlog grooming, issue definitions, and documentation live in `planning/`. See [planning/README.md](planning/README.md) for:
- Bulk issue creation workflow
- Milestone structure (M1-M7)
- Label/milestone setup scripts

### 4. App Implementation
Implementation happens in `app/` folder. Create feature branches off `main`:
```bash
git checkout -b feature/item-inventory
# ... implement using planning/issues/* as your spec
# ... commit with small, focused PRs
```

**Pre-commit checks:** Format and analyzer checks run automatically before each commit. See [PRE-COMMIT.md](PRE-COMMIT.md) for details.

## Workflow for Implementation

1. **Select Issue** from `planning/milestones/M1/` (or relevant milestone)
2. **Read Issue** – acceptance criteria + test plan are your spec
3. **Create Feature Branch**: `git checkout -b feature/xxx`
4. **Implement in `app/`** – code + tests + telemetry per DoD
5. **Submit PR** linking back to planning issue
6. **Update Issue** status in planning/ when merged

## Project Status & Hours Tracking

**Last Updated:** January 23, 2026

### Cumulative Human Hours Invested
| Phase | Hours | Status | Notes |
|-------|-------|--------|-------|
| Planning & Documentation | ~40h | ✅ Complete | Repo setup, design tokens, data model, telemetry schemas, UX docs |
| M1/090 Flutter Skeleton | ~20h | ✅ 95% Complete | App compiles, routing, DI, telemetry, tests pass; deep link integration test + CI pipeline pending |
| M2/100 Hive Storage | ~12h | ✅ Complete | Repository CRUD, Hive init, Riverpod providers wired |
| M2/140 Add Item Screen | ~8h | ✅ Complete | Form with prepared type toggle, price validation, date picker, accessibility |
| Testing & Polish | ~4h | ✅ Complete | Deprecated API fixes, widget tests (19/19 passing), accessibility improvements |
| **Total** | **~84h** | **75% to M2** | Core MVP loop (add → view → use) scaffold complete |

**Next Milestones:** M2/150 (Inventory List), M2/170 (Item Detail), M1 gaps (deep link test, CI pipeline)

## CI/CD Strategy

- **Planning changes**: Lint markdown, validate issue structure
- **App changes**: Run tests on `app/` path only (don't re-test planning docs)
- **Feature branches**: Small PRs implementing one issue at a time

## References
- [planning/AGENTS.md](planning/AGENTS.md) – AI coding agent instructions
- [planning/README.md](planning/README.md) – Backlog details
- [planning/milestones/M1/README.md](planning/milestones/M1/README.md) – First milestone guide
- [CONTRIBUTING.md](CONTRIBUTING.md) – Contribution workflow & PR checklist