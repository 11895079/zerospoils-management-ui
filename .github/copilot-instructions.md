# ZeroSpoils Monorepo — AI Coding Agent Instructions

## Project Context
This is a **monorepo** for ZeroSpoils, a Flutter mobile app for household food waste reduction. The repository contains both planning artifacts (issue definitions, documentation) and the Flutter application implementation.

**Repository Type**: Monorepo (Planning + Flutter App Implementation)  
**Primary Languages**: Dart/Flutter (app), Markdown (planning docs), Bash (automation scripts), Python (doc utilities)  
**Current State**: Planning phase (M1) — app folder will be created during milestone M1  
**Structure**: 
- `planning/` — Backlog, milestones, documentation, scripts (~60 issue files)
- `app/` — Flutter application code (to be created in M1, see issue 090)  
**Purpose**: Unified repository for both project planning and Flutter app development

## Repository Architecture

### Monorepo Structure
```
.
├── planning/          # Backlog, milestones, documentation
│   ├── issues/        # Issue markdown files (numbered 000-590)
│   ├── milestones/    # Issues grouped by M1-M7 delivery phases
│   │   └── M1/        # Foundations: repo scaffolding, CI, data model, UX, Flutter skeleton
│   ├── docs/          # Architecture, design, data model, telemetry
│   ├── scripts/       # Automation: label/milestone creation, doc conversion
│   ├── AGENTS.md      # AI coding agent workflow guide
│   └── requirements.txt
│
├── app/               # Flutter application (to be created in M1)
│   ├── lib/           # Dart source code
│   ├── test/          # Unit & widget tests
│   ├── pubspec.yaml   # Flutter dependencies
│   └── ...
│
└── README.md          # This file
```

### Current State vs. Target State
**Current (Planning Phase)**: Only `planning/` folder exists with issue definitions and documentation.  
**Target (M1+)**: Both `planning/` and `app/` folders coexist. Development workflow:
1. Select issue from `planning/milestones/MX/`
2. Implement in `app/` folder on feature branch
3. Submit PR linking to planning issue
4. Update issue status in planning when merged

See milestone M1 issue 090 (`planning/milestones/M1/090-flutter-app-skeleton-routing-theming-di.md`) for app initialization.

### Issue File Conventions (Planning Folder)
- **Naming:** `NNN-brief-slug.md` (10-step increments: 000, 010, 020..590)
- **Location:** `planning/issues/` (standalone) or `planning/milestones/MX/` (grouped by milestone)
- **Template structure:** Context → Goal → Expected behavior → Acceptance criteria (DoD checklist) → Out of scope → Implementation notes → Test plan (Automated + Manual) → Dependencies
- **DoD checklist includes:** Tests, telemetry, offline-first verification, accessibility basics
- **Test plans:** Every issue has concrete automated tests (scripts, schema validation, widget tests) + manual smoke tests
- **Usage:** These issues serve as specifications for implementation in the `app/` folder

### Milestone Organization
- **M1 (Foundations):** Repo setup, CI, data model, UX wireframes, Flutter skeleton, observability
- **M2 (Early Build):** iOS/Android build pipelines, recipe suggestions POC
- **M3 (MVP Features):** Core inventory, shopping list, notifications, basic telemetry
- **M4 (Polish & Launch):** UX refinements, accessibility audit, performance optimizations
- **M5 (Advanced):** Full recipe feature with ML/data pipeline

## Key Workflows

### Development Workflow (Planning → Implementation)
This monorepo supports a workflow where planning drives implementation:

0. **Create Todo Tasks for the Work Item**
  - Immediately break the selected work item into concrete todo tasks using the work item details.
  - Track progress by updating task status as work proceeds.
  - Do not start implementation until the todo list is created.

1. **Select Issue** from `planning/milestones/MX/` (start with M1)
2. **Groom Issue** ⚠️ **REQUIRED BEFORE IMPLEMENTATION**
   - Check for empty test plans, generic DoD items, missing implementation notes
   - Add concrete automated tests (not "add tests") + step-by-step manual scenarios
   - Add implementation notes with technical decisions, patterns, trade-offs
   - Define clear out-of-scope boundaries
   - Commit grooming changes before starting feature branch
3. **Read Issue** — acceptance criteria + test plan are your implementation spec
4. **Create Feature Branch**: `git checkout -b feature/descriptive-name`
5. **Implement in `app/`** — code + tests + telemetry per Definition of Done
6. **Submit PR** linking back to planning issue (e.g., "Closes planning/milestones/M1/090-*")
7. **After PR merges, update this planning repo** ⚠️ **CRITICAL STEP**

### ⚠️ CRITICAL: Keep Planning & Code in Sync

**After implementation is complete and merged to app repo main branch:**

1. **Update the issue file acceptance criteria** to reflect actual implementation:
   - Mark items `[x]` if code is complete and tested
   - Leave incomplete items as `[ ]`
   - Do NOT modify issue descriptions (they are the authoritative spec)
   - Add implementation notes if details changed (e.g., "Used Riverpod instead of GetIt")

2. **Update the milestone README** with current progress:
   - Add or update issue status table showing completion % (see `planning/milestones/M1/README.md` for example format)
   - Include test results (e.g., "19/19 tests passing")
   - List any pending work or deferred items
   - Update "Last Updated" timestamp

3. **Update the root README.md** with project hours:
   - Bump cumulative hours estimate (see "Project Status & Hours Tracking" section in root README)
   - Update "Last Updated" timestamp
   - Add brief summary of what was completed

**Why this is critical:**
- Planning files are the ground truth for all stakeholders
- Stale documentation leads to rework and duplicate effort
- Acceptance criteria updates enable traceability: spec → PR → test results

### Adding/Editing Issues (Planning Work)
1. Use the standard template (see any `milestones/M1/*.md` for reference)
2. Include concrete test plans (never leave empty stubs)
3. Add to appropriate milestone folder OR `issues/` if unassigned
4. Update `issues.csv` for bulk creation (format: title, file path, labels, milestone)

### Renaming Issues
- Always use 10-step increments to allow insertions between issues
- Pattern: `000-repo-scaffolding.md`, `010-mvp-scope.md`, `020-flutter-ci.md`

### Bulk Issue Creation
```bash
# From repo root after `gh auth login`
while IFS=, read -r title file labels milestone; do
  if [ "$title" = "title" ]; then continue; fi
  args=(--title "$title" --body-file "$file" --label "$labels")
  if [ -n "$milestone" ]; then args+=(--milestone "$milestone"); fi
  gh issue create "${args[@]}"
done < issues.csv
```

### Label/Milestone Setup
```bash
bash scripts/create_milestones.sh  # Creates M1, M2, M3, M4, M5, M6, M7
bash scripts/create_labels.sh      # Creates epic, mvp, pro, mobile, security, priority:P0-P2, size:S/M/L, etc.
```

## Project-Specific Patterns

### Definition of Done (Every Issue)
- Unit/widget/integration tests added or updated
- Telemetry instrumentation (event names + properties documented)
- Offline-first behavior verified where applicable
- Accessibility basics: labels, contrast, tap targets ≥44pt

### Test Plan Format
```markdown
## Test plan
**Automated:**
- [Specific test type]: [what it validates]
- Example: Widget test verifies app launches and renders home screen

**Manual:**
1. [Concrete step with expected result]
2. [Another step]
```

### Privacy-First Defaults
- No PII in telemetry by default (see `040-define-telemetry-taxonomy-baseline-events.md`)
- Opt-in/opt-out strategy required for all data collection
- OCR/receipt features gated behind explicit consent (Pro tier)

### Mobile Architecture Decisions (from planning issues)
These decisions are documented in planning issues and will be implemented in the `app/` folder:

- **Framework:** Flutter (iOS/Android) — cross-platform mobile development
- **Layering:** domain/data/ui separation (clean architecture pattern)
- **State management:** Repository pattern + TBD state solution (Provider/Riverpod/Bloc); to be selected and documented in M1 issue 090
- **Data flow:** Local DB → Repository → UI; offline-first with eventual sync for Pro tier
- **Local storage:** Hive or sqflite (offline-first requirement for MVP)
- **Feature flags:** Gating Pro/subscription features at runtime (see planning issue 130)
- **CI:** GitHub Actions (lint, format, tests on PR; iOS builds require macOS runners) — see M1 issue 020
- **Observability:** Crash reporting + key event alerts (post-launch, see planning issue 390)
- **Telemetry:** Event-driven instrumentation with standard properties (platform, app_version, category, location) — see M1 issue 040

All implementation will happen in `app/` folder following the specifications in planning issues.

## Scripts & Utilities (Planning Folder)

### `planning/scripts/doc_convert.py`
Converts Word documents to Markdown using mammoth + html2text. Extracts images to separate folder.
```bash
cd planning
python scripts/doc_convert.py input.docx output.md
```

### Python Environment Setup
```bash
cd planning
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\activate    # Windows
pip install -r requirements.txt
```

### GitHub CLI API Best Practices
**ALWAYS use `gh api` for PR/issue updates instead of `gh pr edit` or `gh issue edit`.**

Reason: The `gh pr edit` and `gh issue edit` commands have argument parsing issues with multi-line text in PowerShell/Windows environments, causing "accepts at most 1 arg(s)" errors.

**Correct approach:**
```bash
# Update PR description (file-based)
gh api -X PATCH "repos/:owner/:repo/pulls/<NUMBER>" -F body=@description.txt

# Update issue body (file-based)
gh api -X PATCH "repos/:owner/:repo/issues/<NUMBER>" -F body=@description.txt

# Update PR title (inline)
gh api -X PATCH "repos/:owner/:repo/pulls/<NUMBER>" -F title="New title"
```

**Why file-based?** Multi-line descriptions require proper escaping which varies by shell. Using `-F body=@file.txt` avoids all escaping issues.

**Workflow:**
1. Create temp file with description content (Markdown format)
2. Use `gh api -X PATCH` with `-F body=@file.txt`
3. Verify with `gh pr view <NUMBER> --json body` or `gh issue view <NUMBER> --json body`

## Executive Briefings (Data-Driven Reports)

When generating executive briefings under `docs/executive-briefings/`, follow these rules so the reports are accurate, defensible, and stakeholder-ready.

### Commit Attribution (Human vs Copilot Agent)
- **Human commits**: authors that do not include bot identifiers (e.g., `copilot`, `swe-agent[bot]`, `github-actions[bot]`).
- **Copilot agent commits**: authors containing `copilot` or `swe-agent[bot]` (case-insensitive).
- Report the split explicitly (counts + percent). Treat bot commits as *assisted* work, not manual effort.

### Effort Score Definition
Effort score is a **0–100 index** derived from objective signals (commit volume, net lines changed, test coverage, and change density). Interpret it as:
- **0–39**: Low (light activity or narrow scope)
- **40–69**: Moderate (steady progress)
- **70–84**: Strong (high delivery pace + breadth)
- **85–100**: Exceptional (sustained, high-impact delivery)

### Time Investment (Must Include Specific Values)
Always include **explicit time values** in the report:
- **Calendar span**: total days and total hours in the reporting range (e.g., “14 days / 336 hours”).
- **Active development days**: count of unique days with commits.
- **Average commits per active day**.
Do **not** infer “human hours worked” unless a declared hours-per-day assumption is provided by the user.

### “Production-Ready” Clarification
When stating “production-ready,” explicitly clarify:
- **Meaning**: code quality, architecture, test coverage, CI/lint, and build stability are release-grade.
- **Not implied**: product launch readiness, go-to-market readiness, or operational readiness.
Use language like: “production-ready code quality, not a declaration to launch today.”

### Milestone Progress (Never Empty)
- Use **status files in `planning/milestones/`** (e.g., milestone `README.md` and issue status tables) as the source of truth.
- If progress appears empty or stale, **review actual code vs. milestone acceptance criteria** and **attempt to update milestone status first**, then generate the report.
- Do not report milestone progress without reconciling status.

### MVP Overview (Required in Executive Briefings)
- Include an **MVP overview** summarizing milestones **M1–M3**.
- Provide **completed items per milestone** in the summary (e.g., `M1: Foundations — 10/10 complete (100%)`).
- Use milestone themes from milestone README headers/objectives when available.

### Lines of Code by Category — Definitions
Clarify the meaning of each metric:
- **Production Code**: total lines across `app/lib/**/*.dart`.
- **Net Addition**: cumulative insertions minus deletions from git history in the reporting range.
- **Refactoring Effort**: count of commits labeled `refactor` (quality improvements, not feature expansion).
Include a short definition block in the report whenever this section appears.

### Executive Briefing Format & Generation

**CRITICAL: Always generate BOTH markdown and PDF versions**

Every executive report must be generated in both formats simultaneously using the `--pdf` flag:

```bash
# Cumulative report (all time)
python scripts/generate_executive_report.py --pdf

# Date range report
python scripts/generate_executive_report.py --from 2026-01-15 --to 2026-02-14 --pdf

# Last 7 days
python scripts/generate_executive_report.py --latest --pdf

# Windows batch wrapper
scripts\generate_executive_report.bat --pdf
```

**Generated Files:**
- **Markdown**: `executive-report-<period>-YYYYMMDD-HHMMSS.md` (editable, version control friendly)
- **PDF**: `executive-report-<period>-YYYYMMDD-HHMMSS.pdf` (print-ready, shareable)

Both files are saved to `docs/executive-briefings/` with matching timestamps.

### Executive Briefing Filename Convention

Filenames follow this format (generated automatically):

`executive-report-<period>-YYYYMMDD-HHMMSS.{md|pdf}`

Examples:
- `executive-report-cumulative-20260215-163557.md` + `.pdf`
- `executive-report-20260201-to-20260215-20260215-163557.md` + `.pdf`

## When Working in This Codebase

### DO
- Consolidate overlapping issues (example: merged 050 wireframes + 055 UX foundations)
- Add concrete, automatable test plans to every new issue
- **MANDATORY TDD:** For every new feature, bugfix, or refactor, always write or update a failing test (unit/widget/integration) before implementing code. Verify the test fails, then implement code until it passes. This applies to all future work items.
- When addressing pull request review comments, gather all unresolved feedback first, implement the minimal verified fixes, and resolve a GitHub review thread/comment only after the fix is verified and pushed to the PR branch. If no code change is needed, leave a clear rationale before resolving.
- Use this resolve gate for every thread: (1) addressed by code change or explicit rationale, (2) relevant checks completed for the touched scope, and (3) commit containing the fix is pushed to the PR branch.
- Keep milestone READMEs concise (80-120 words: objective, scope, acceptance, issue reference)
- Use 10-step numbering for easy reordering of planning issues
- **When implementing features**: Create code in `app/` folder, link PRs to planning issues
- **When modifying app code**: Follow Flutter/Dart best practices, maintain test coverage ≥80%
- **When generating executive reports**: Always use the `--pdf` flag to generate both markdown + PDF versions together (e.g., `python scripts/generate_executive_report.py --pdf`)

### DON'T
- Leave empty test plan stubs (every issue needs at least one automated + one manual test). Leave it up to the developer to determine if the automated test will be eventually implemented
- Create high-fidelity designs in M1 (wireframes only, defer polish to launch milestone)
- Mix issue planning with actual Flutter code (planning in `planning/`, implementation in `app/`)
- Commit Flutter app code to `planning/` folder or vice versa
- **NEVER bypass commit verification using `--no-verify`** — Pre-commit hooks enforce code quality (formatting, linting, analysis). If hooks fail, fix the underlying issues. Only a human can override verification if needed.
- **Search for text strings in widget tests** — Tests that rely on finding UI text are brittle and break when copy changes. Instead, verify behavior through:
  - **Object inspection**: Check state/model changes (`expect(item.quantity, 2)`)
  - **Widget properties**: Verify widget presence and state (`expect(find.byType(QuantityToggle), findsOneWidget)`)
  - **Actions**: Tap buttons by icon/type (`find.byIcon(Icons.add_circle_outline)`) and verify resulting state changes
  - **Accessibility**: Use semantic finds like `find.byType(IconButton)` or `find.byWidgetPredicate()` for widget-based selection
  - Example: Instead of `find.text('Confirm')`, use `find.byIcon(Icons.check_circle)` and verify the quantity value changed

## Common AI Agent Workflows

These are repetitive tasks AI agents frequently perform in this repo:

### Gap Analysis
"Compare requirements doc X to existing issues, identify missing coverage, create new issue files with proper numbering and test plans"

### Milestone Reorganization
"Move issues matching criteria Y into milestone folder Z, update cross-references, regenerate milestone README"

### Bulk Renumbering
"Renumber issue files to maintain 10-step increments after insertions (e.g., inserting between 020 and 030 creates 025)"

### Test Plan Backfill
"Add concrete automated + manual test plans to all issues missing them; ensure at least one automated validation per issue"

### Cross-Reference Validation
"Find all issues referencing deprecated issue numbers and update links; verify all milestone READMEs reference correct issue ranges"

### Issue Consolidation
"Identify overlapping issues (e.g., 050 + 055 both creating wireframes), merge into single coherent issue, delete duplicate"

## Good vs. Bad Issue Examples

### ❌ BAD: Empty Test Plan
```markdown
## Test plan
- Steps:
  1.
  2.
- Scenarios:
  - 
```
**Problems:** No guidance for implementer; not actionable; violates repo conventions

### ✅ GOOD: Concrete Test Plan
```markdown
## Test plan
**Automated:**
- Widget test: verify app launches and renders home screen
- Widget test: navigate between all tabs, assert each screen renders
- Unit test: verify DI container resolves all registered services
- Integration test: deep link handling (simulate opening app with link)

**Manual:**
1. `flutter run` on iOS simulator (verify compile and launch)
2. `flutter run` on Android emulator (verify compile and launch)
3. Navigate between all tabs and verify smooth transitions
4. Verify theme tokens applied (spacing, colors, typography)
5. Test on physical device for performance baseline
```
**Why it's good:** Specific test types, concrete steps, clear pass/fail criteria, covers automated + manual validation

## Integration Points
- **GitHub CLI:** Required for bulk issue creation and milestone/label setup in `planning/`
- **GitHub Issues:** Planning issues designed for `gh issue create --body-file`
- **Flutter SDK:** Required for `app/` development (after M1 issue 090)
- **VS Code + Copilot/Codex:** Issue bodies serve as direct prompts for implementation
- **Monorepo Structure:** Planning in `planning/`, implementation in `app/`

## Context for AI Agents
This monorepo supports AI-assisted development of the ZeroSpoils Flutter app:

**Planning Phase (Current):**
- Structured issues in `planning/` folder serve as implementation specifications
- Each issue is a self-contained work unit with clear context, acceptance criteria, and test plans

**Implementation Phase (After M1):**
- Issues from `planning/milestones/` guide feature development in `app/` folder
- Use issue acceptance criteria as direct prompts for code generation
- Link PRs back to planning issues for traceability

When generating new issues or editing existing ones, maintain this structure and ensure test plans are actionable (not generic "write tests" advice). When implementing features, create code in `app/` folder following the specifications in planning issues.

## Build, Test & Validation Commands

### Planning Folder (Current)
**No build required** for planning artifacts. All files are plain text (Markdown, Bash, Python).

#### Python Environment Setup (for doc_convert.py utility)
```bash
# Only needed if running document conversion utilities
cd planning
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS
# .venv\Scripts\activate    # Windows
pip install -r requirements.txt
```

#### Validation Steps for Planning Changes
**Always run these before committing planning changes:**

1. **Check Markdown syntax** (no linter configured, manual review):
```bash
# Manually verify all .md files render correctly
# Check for broken links, proper formatting, code blocks
```

2. **Verify Script Syntax**:
```bash
# Test bash scripts for syntax errors
bash -n planning/scripts/create_labels.sh
bash -n planning/scripts/create_milestones.sh
bash -n planning/scripts/create_labels_addon.sh
```

3. **Python Script Validation** (if modified):
```bash
cd planning
python3 -m py_compile scripts/doc_convert.py
python3 -m py_compile scripts/test_generate_docx.py
```

4. **Test Label/Milestone Scripts** (dry-run, requires `gh` CLI):
```bash
# Verify GitHub CLI is authenticated first
gh auth status

# Scripts will fail gracefully if already exist
# Review output to ensure no errors
bash planning/scripts/create_milestones.sh
bash planning/scripts/create_labels.sh
```

5. **Issue File Structure Check** (manual):
- Verify new/modified issue files follow template structure
- Confirm test plans are concrete (not empty stubs)
- Check DoD checklist is complete
- Validate 10-step numbering (000, 010, 020...)

### App Folder (After M1 Issue 090)
Once the Flutter app is created in `app/` folder:

#### Setup Flutter Environment
```bash
# Verify Flutter installation
flutter doctor

# Get dependencies
cd app
flutter pub get
```

#### Build & Test Commands
```bash
# Run all tests
cd app
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test suites
flutter test test/unit/        # Unit tests only
flutter test test/widget/      # Widget tests only

# Lint and format check
flutter analyze
dart format --set-exit-if-changed .

# Build for platforms
flutter build ios --debug      # iOS debug build
flutter build apk --debug      # Android debug build
flutter build ios --release    # iOS release build (requires signing)
flutter build apk --release    # Android release build
```

#### Development Workflow
```bash
# Run on simulator/emulator
flutter run                    # Run on connected device
flutter run -d ios             # Run on iOS simulator
flutter run -d android         # Run on Android emulator

# Hot reload during development
# Press 'r' in terminal for hot reload
# Press 'R' for hot restart
```

See `planning/milestones/M1/020-set-up-flutter-ci-lint-format-tests-on-pr.md` for CI pipeline details.

### CI/CD Status
**Current State (Planning Phase):**
- No CI/CD pipelines configured yet
- All validation is manual for planning artifacts

**Target State (After M1 Issue 020):**
GitHub Actions workflows will be added for:
- **Planning changes**: Markdown linting, issue structure validation
- **App changes**: 
  - `flutter analyze` (linting)
  - `dart format --set-exit-if-changed` (formatting)
  - `flutter test` (all tests on PR)
  - iOS/Android build validation
  - Automated test runs on PR
  - Build artifacts generation

See `planning/milestones/M1/020-set-up-flutter-ci-lint-format-tests-on-pr.md` for implementation details.

### Key Validation Rules

**For Planning Changes:**
- **ALWAYS** check bash script syntax before committing (`bash -n <script>`)
- **ALWAYS** ensure Python scripts compile without errors (`python3 -m py_compile <script>`)
- **ALWAYS** verify issue files follow the standard template structure
- **NEVER** commit empty test plan stubs
- **NEVER** break 10-step numbering convention for issue files

**For App Changes (after M1):**
- **ALWAYS** run `flutter analyze` before committing code
- **ALWAYS** run `dart format .` to ensure consistent formatting
- **ALWAYS** run `flutter test` to verify tests pass
- **ALWAYS** ensure test coverage ≥80% for modified files
- **NEVER** commit with linting errors or warnings
- **NEVER** skip writing tests for new features
- **NEVER** commit secrets, API keys, or PII

## Working with Scripts

### Label Creation (`planning/scripts/create_labels.sh`)
**Purpose**: Creates standardized GitHub labels for issue categorization  
**Prerequisites**: `gh` CLI authenticated (`gh auth login`)  
**Usage**:
```bash
cd /path/to/zerospoils
bash planning/scripts/create_labels.sh
```
**Expected behavior**: Idempotent (safe to run multiple times, skips existing labels)

### Milestone Creation (`planning/scripts/create_milestones.sh`)
**Purpose**: Creates GitHub milestones M1-M7  
**Prerequisites**: `gh` CLI authenticated  
**Usage**:
```bash
bash planning/scripts/create_milestones.sh
```
**Expected behavior**: Creates milestones if they don't exist

### Document Conversion (`planning/scripts/doc_convert.py`)
**Purpose**: Converts Word documents to Markdown with image extraction  
**Prerequisites**: Python 3.x with `mammoth` and `html2text` installed  
**Usage**:
```bash
cd planning
python scripts/doc_convert.py input.docx output.md
```
**Common issues**: Requires Python virtual environment with dependencies installed

## Trust These Instructions
These instructions have been carefully crafted for this specific monorepo. **Trust them as accurate and complete.** Only search for additional information if:
- Instructions are incomplete for a specific task
- Instructions contradict observed behavior
- New functionality has been added that isn't documented here

For routine work (creating issues, running scripts, organizing files in `planning/`, or implementing features in `app/`), rely on these instructions without additional exploration.

**Key Points to Remember:**
- This is a **monorepo** with both planning (`planning/`) and implementation (`app/`) folders
- Planning issues drive implementation work
- `app/` folder will be created in M1 — see issue 090
- Always link implementation PRs back to planning issues for traceability

## Editing GitHub PR Descriptions (CLI + Web)

Use these authoritative patterns to edit PR titles/descriptions so reviews are easy and consistent.

### Web UI (fastest)
- Open the PR → click "Edit" next to the title.
- Update the title and description (Markdown supported).
- Click "Save".

### GitHub CLI (gh)
- Edit PR for the current branch:
  - Windows PowerShell (body from file):
    ```powershell
    gh pr edit --body-file PR_BODY.md
    ```
- Edit a specific PR by number (recommended):
  - Using a file:
    ```powershell
    gh pr edit 31 --body-file PR_BODY.md
    ```
  - Inline from file content:
    ```powershell
    gh pr edit 31 --body "$(Get-Content -Raw PR_BODY.md)"
    ```
  - Explicit repo:
    ```powershell
    gh pr edit 31 --body-file PR_BODY.md --repo OWNER/REPO
    ```
- Update the title:
  ```powershell
  gh pr edit 31 --title "[WIP] M1/050: Add wireframes for core MVP screens"
  ```
- Add labels for clarity:
  ```powershell
  gh pr edit 31 --add-label "needs-review"
  ```
- Convert draft to ready for review:
  ```powershell
  gh pr ready 31
  ```

### Troubleshooting
- If you see GraphQL errors mentioning Projects Classic:
  - Upgrade gh: `gh version upgrade`
  - Specify PR number and repo explicitly (see examples above).
  - As a fallback, post a comment with the updated body:
    ```powershell
    gh pr comment 31 --body-file PR_BODY.md --repo OWNER/REPO
    ```
- Ensure you have permissions on the repo and are authenticated: `gh auth status`.

### Best Practices for PR Bodies
- Start with a "Quick Review Index" linking to specs and key files.
- Include a suggested review flow and a checkbox checklist (UX, components, accessibility, telemetry).
- Keep links relative to the feature branch for preview (e.g., `blob/feature/...`).
- Mark as WIP/Draft when alignment is required prior to implementation.
