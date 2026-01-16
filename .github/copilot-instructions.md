# ZeroSpoils Issue Pack — AI Coding Agent Instructions

## Project Context
This is a **backlog planning repository** for ZeroSpoils, a Flutter mobile app for household food waste reduction. This repo contains structured issue markdown files designed for bulk creation in GitHub, not the actual application code.

## Repository Architecture

### Structure
```
issues/          - Standalone issue bodies (numbered 000-590, 10-step increments)
milestones/      - Issues grouped by delivery milestone (M1, M2,...,M5,...)
  M1/            - Foundations: repo scaffolding, CI, data model, UX, Flutter skeleton
  M2/            - Build pipelines and early feature POCs
  M5/            - Advanced features (recipe suggestions)
scripts/         - Automation: label/milestone creation, doc conversion utilities
requirements.txt - Python deps for doc_convert.py (mammoth, html2text)
issues.csv       - Bulk issue creation manifest for `gh issue create`
```

### Issue File Conventions
- **Naming:** `NNN-brief-slug.md` (10-step increments: 000, 010, 020..590)
- **Template structure:** Context → Goal → Expected behavior → Acceptance criteria (DoD checklist) → Out of scope → Implementation notes → Test plan (Automated + Manual) → Dependencies
- **DoD checklist includes:** Tests, telemetry, offline-first verification, accessibility basics
- **Test plans:** Every issue has concrete automated tests (scripts, schema validation, widget tests) + manual smoke tests

### Milestone Organization
- **M1 (Foundations):** Repo setup, CI, data model, UX wireframes, Flutter skeleton, observability
- **M2 (Early Build):** iOS/Android build pipelines, recipe suggestions POC
- **M3 (MVP Features):** Core inventory, shopping list, notifications, basic telemetry
- **M4 (Polish & Launch):** UX refinements, accessibility audit, performance optimizations
- **M5 (Advanced):** Full recipe feature with ML/data pipeline

## Key Workflows

### Adding/Editing Issues
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

### Mobile Architecture Decisions (from issue bodies)
- **Framework:** Flutter (iOS/Android)
- **Layering:** domain/data/ui separation (mentioned in implementation notes across MVP issues)
- **State management:** Repository pattern + TBD state solution (Provider/Riverpod/Bloc); document in `090-flutter-app-skeleton` when selected
- **Data flow:** Local DB → Repository → UI; offline-first with eventual sync for Pro tier
- **Local storage:** Hive or sqflite (offline-first requirement)
- **Feature flags:** Gating Pro/subscription features at runtime (see `130-feature-flags-framework`)
- **CI:** GitHub Actions (lint, format, tests on PR; iOS builds require macOS runners)
- **Observability:** Crash reporting + key event alerts (post-launch, see `390-ops-observability`)
- **Telemetry:** Event-driven instrumentation with standard properties (platform, app_version, category, location)

## Scripts & Utilities

### `scripts/doc_convert.py`
Converts Word documents to Markdown using mammoth + html2text. Extracts images to separate folder.
```bash
python scripts/doc_convert.py input.docx output.md
```

### Python Environment Setup
```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

## When Working in This Codebase

### DO
- Consolidate overlapping issues (example: merged 050 wireframes + 055 UX foundations)
- Add concrete, automatable test plans to every new issue
- Keep milestone READMEs concise (80-120 words: objective, scope, acceptance, issue reference)
- Use 10-step numbering for easy reordering

### DON'T
- Leave empty test plan stubs (every issue needs at least one automated + one manual test). Leave it up to the developer to determine if the automated test will be eventually implemented
- Create high-fidelity designs in M1 (wireframes only, defer polish to launch milestone)
- Mix issue planning with actual Flutter code (this repo is planning only)

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
- **GitHub CLI:** Required for bulk issue creation and milestone/label setup
- **GitHub Issues:** Target platform; all markdown files designed for `gh issue create --body-file`
- **VS Code + Copilot/Codex:** Issue bodies serve as direct prompts (see README: "Use the issue acceptance criteria as the direct prompt")

## Context for AI Agents
This backlog was structured to enable AI-assisted development of the ZeroSpoils Flutter app. Each issue is a self-contained work unit with:
- Clear context and goal
- Specific acceptance criteria (checkboxes)
- Concrete test plans (automated + manual)
- Implementation notes and dependencies

When generating new issues or editing existing ones, maintain this structure and ensure test plans are actionable (not generic "write tests" advice).
