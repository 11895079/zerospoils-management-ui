# AI Agent Development Guide

## Purpose

This document defines the workflow for AI coding agents working with ZeroSpoils issues. It ensures consistency across development sessions and enables reliable progress tracking.

## Repository Role

This repo contains **backlog planning only** (not the Flutter app code). Issues are designed as self-contained prompts for AI agents to implement in the actual application repository.

## Prerequisites

### Required Tools
- **GitHub CLI:** `gh` command for issue creation/updates
- **Git:** For version control in both repos
- **Flutter SDK:** For implementing mobile app features
- **VS Code + GitHub Copilot:** Recommended IDE setup

### Repository Setup
1. **This repo (zerospoils_github_issues_pack):** Backlog planning
2. **App repo (zerospoils-app):** Flutter application code (separate repository)

### Access Requirements
- Write access to both repositories
- GitHub authentication configured (`gh auth login`)

### GitHub CLI API Best Practices
**CRITICAL: Always use `gh api` for PR/issue updates, NOT `gh pr edit` or `gh issue edit`.**

The high-level CLI commands (`gh pr edit`, `gh issue edit`) have argument parsing issues with multi-line text, especially in PowerShell/Windows environments. This causes "accepts at most 1 arg(s), received N" errors.

**Correct Pattern:**
```bash
# Write description to file
echo "Multi-line\nPR description" > pr_body.txt

# Update using API
gh api -X PATCH "repos/:owner/:repo/pulls/36" -F body=@pr_body.txt
gh api -X PATCH "repos/:owner/:repo/issues/123" -F body=@issue_body.txt
```

**Why this works:**
- `-F body=@file` reads from file, avoiding shell escaping issues
- `:owner` and `:repo` auto-resolve to current repository context
- Works consistently across PowerShell, bash, zsh

**Verification:**
```bash
gh api "repos/:owner/:repo/pulls/36" --jq .body  # Check PR body
gh api "repos/:owner/:repo/issues/123" --jq .body  # Check issue body
```

## Development Workflow

### Phase 1: Issue Selection
1. Review milestone README to understand current phase (M1, M2, M3, etc.)
2. Check issue dependencies before starting work
3. Verify prerequisites are complete (referenced issues, documentation)

### Phase 2: Issue Grooming (REQUIRED BEFORE IMPLEMENTATION)
**⚠️ ALWAYS groom the issue file before starting implementation:**

1. **Check for empty or incomplete sections:**
   - Empty test plans ("Steps: 1. 2." or "Scenarios: -")
   - Generic DoD items not applicable to the task (e.g., "accessibility" for CI/CD)
   - Missing implementation details or ambiguous acceptance criteria
   - Lack of concrete examples in test plans

2. **Add concrete details:**
   - Write specific automated test cases (not "add tests")
   - Write step-by-step manual test scenarios with expected outcomes
   - Add implementation notes with technical decisions (frameworks, patterns, trade-offs)
   - Define clear out-of-scope boundaries

3. **Commit grooming changes:**
   ```bash
   git add planning/milestones/MX/NNN-issue.md
   git commit -m "docs(MX/NNN): Groom issue with concrete test plan and implementation details"
   git push
   ```

**Example transformation:**
```markdown
# BAD (empty stub)
## Test plan
- Steps:
  1.
  2.

# GOOD (concrete)
## Test plan
**Automated:**
- Unit test: saveItem persists and retrieves
- Widget test: form validates required fields

**Manual:**
1. Add item via UI → close app → reopen → verify present
2. Submit empty form → verify validation error shown
```

### Phase 3: Implementation (in App Repo)
1. **Copy groomed issue content** from this repo as the agent prompt
2. **Navigate to app repo** (not this planning repo)
3. **Use issue acceptance criteria as direct prompt:**
   ```bash
   # In app repo
   gh issue view <number> --json body -q .body | copilot implement
   ```
4. **Follow issue structure:**
   - Context → Goal → Expected behavior → Acceptance criteria (DoD)
   - Implementation notes → Test plan → Dependencies
5. **Implement according to test plan:**
   - Write automated tests first (widget/unit/integration)
   - Add or update a failing test before writing code; verify it fails to prove coverage, then implement until it passes
   - Implement feature
   - Run manual test scenarios
   - Verify DoD checklist items

### Phase 4: Update This Repo (Status Tracking)
After completing implementation in app repo, update this planning repo:

1. **Mark issue complete** by updating the issue file:
   ```markdown
   ## Status
   ✅ **COMPLETE** — Implemented in [PR #123](link) on YYYY-MM-DD
   
   **Verification:**
   - [ ] All DoD items completed
   - [ ] Tests passing in CI
   - [ ] Manual test scenarios verified
   - [ ] Telemetry events validated
   ```

2. **Update dependent issues:**
   - Find issues listing this as a dependency
   - Update their status notes or remove blocker comments

3. **Update milestone README:**
   - If last issue in milestone, update README status to "✅ Complete"
   - Document any deviations from plan

4. **Commit changes:**
   ```bash
   # In this planning repo
   git add milestones/MX/NNN-issue-name.md
   git commit -m "Mark issue NNN complete: [brief description]"
   git push
   ```

### Phase 4: Cross-Reference (Optional)
Link planning issue to app repo PR/commit:
```bash
# In app repo PR description
Implements: zerospoils/zerospoils_github_issues_pack#NNN
```

## Consistency Rules

### Issue Status Format
Add status section at the END of each issue file:

```markdown
---

## Status
🚧 **IN PROGRESS** — Started YYYY-MM-DD by @developer

or

✅ **COMPLETE** — Implemented in app repo [PR #123](link) on YYYY-MM-DD
```

### Agent Behavior Standards

1. **Always read full issue** before implementation (not just summary)
2. **Follow test plan exactly** (don't skip automated tests)
3. **Update planning repo AFTER implementation merges** (not during implementation) ⚠️ **CRITICAL**
4. **Preserve issue structure** (never delete acceptance criteria or test plans)
5. **Document deviations:** If implementation differs from issue, add notes to issue file

### ⚠️ CRITICAL: Keep Planning & Code in Sync

**After completing implementation in app repo:**

1. **Update issue file acceptance criteria** to reflect actual implementation:
   - Mark items `[x]` if code is complete and tested
   - Leave incomplete items as `[ ]`
   - Do NOT modify issue descriptions (they are the authoritative specification)
   - Add implementation notes if details changed (e.g., "Used Riverpod instead of GetIt")

2. **Update milestone README** with current progress:
   - Add issue status table showing completion % (see `planning/milestones/M1/README.md` for example)
   - Include test results (e.g., "19/19 tests passing")
   - List any pending work or deferred items
   - Update "Last Updated" timestamp

3. **Update root README.md** project hours:
   - Bump cumulative hours estimate after each major feature/milestone
   - Include "Last Updated" timestamp (e.g., "January 23, 2026")
   - Add brief notes on what was completed and remaining work

**Why this matters:**
- Planning files are the ground truth for stakeholders and future developers
- Stale documentation leads to rework and confusion
- Acceptance criteria updates allow traceability between spec and implementation

### Test Plan Execution

Every issue has concrete test plans. Agents must:
- **Automated tests:** Implement all listed tests (widget/unit/integration)
- **Manual tests:** Follow step-by-step scenarios and verify expected results
- **Never skip tests:** If test is infeasible, document why in issue status update

### Telemetry Requirements

If issue mentions telemetry:
- Implement event logging as specified
- Document event names and properties in code comments
- Add telemetry verification to test plan results

## Issue File Updates

### When to Update
- ✅ Issue complete (merged to main in app repo)
- ⚠️ Issue blocked (dependency not met, clarification needed)
- 🔄 Issue scope changed (implementation revealed new requirements)
- ❌ Issue cancelled (no longer needed, superseded by another issue)

### How to Update

**Option 1: Add status section (recommended)**
```markdown
---

## Status
✅ **COMPLETE** — [PR #123](app-repo-pr-link) on 2026-01-15

**Implementation notes:**
- Used Provider for state management (not Bloc)
- Added 3 widget tests, 5 unit tests
- Telemetry events: item_added, item_edited, item_deleted

**Deviations:**
- Skipped encryption-at-rest (deferred to issue 245)
```

**Option 2: Checkbox completion**
For simple completions, just check all DoD items:
```markdown
## Acceptance criteria (Definition of Done)
- [x] UI implemented and integrated into navigation
- [x] State management implemented with repository layer
- [x] Unit/widget/integration tests added or updated
...
```

### Milestone README Updates

When all issues in milestone complete:
```markdown
# Milestone M2 - Offline MVP (No Backend)

**Status:** ✅ **COMPLETE** (2026-01-20)

**Objective:** Deliver the first user-facing MVP...

**Actual outcomes:**
- All 10 core issues implemented
```

- ❌ Issue cancelled (no longer needed, superseded by another issue)

### How to Update

**Option 1: Add status section (recommended)**
```markdown
---

## Status
✅ **COMPLETE** — [PR #123](app-repo-pr-link) on 2026-01-15

**Implementation notes:**
- Used Provider for state management (not Bloc)
- Added 3 widget tests, 5 unit tests
- Telemetry events: item_added, item_edited, item_deleted

**Deviations:**
- Skipped encryption-at-rest (deferred to issue 245)
```

**Option 2: Checkbox completion**
For simple completions, just check all DoD items:
```markdown
## Acceptance criteria (Definition of Done)
- [x] UI implemented and integrated into navigation
- [x] State management implemented with repository layer
- [x] Unit/widget/integration tests added or updated
...
```

### Milestone README Updates

When all issues in milestone complete:
```markdown
# Milestone M2 - Offline MVP (No Backend)

**Status:** ✅ **COMPLETE** (2026-01-20)

**Objective:** Deliver the first user-facing MVP...

**Actual outcomes:**
- All 10 core issues implemented
- 47 widget tests, 83 unit tests passing
- iOS/Android builds successful
- TestFlight internal distribution live

**Deviations from plan:**
- Skipped optional OCR feature (issue 142) - deferred to M6
```

## Agent-Specific Guidelines

### For Sequential Work (Single Agent, Multiple Sessions)
1. **Always check git status** in both repos before starting
2. **Read milestone README** to understand current context
3. **Check issue status sections** before selecting next work item
4. **Update previous session's work** before starting new issue

### For Parallel Work (Multiple Agents/Developers)
1. **Claim issue before starting:** Add status section with "🚧 IN PROGRESS — @username"
2. **Coordinate dependencies:** Don't start dependent issue until blocker is merged
3. **Sync planning repo frequently:** Pull latest before updating issue status

### For Issue Creation (Agent Authoring New Issues)
1. **Follow template exactly** (see any `milestones/M1/*.md` for reference)
2. **Use 10-step numbering** (000, 010, 020...590) to allow insertions
3. **Write concrete test plans** (never leave empty stubs like "1. 2.")
4. **Add to milestone folder** or `issues/` if unassigned
5. **Update `issues.csv`** if planning bulk GitHub issue creation

## Integration with copilot-instructions.md

- **copilot-instructions.md:** Structural rules for this planning repo (issue format, naming, organization)
- **AGENTS.md (this file):** Workflow for implementing issues in app repo and tracking status

Both files work together:
- Use copilot-instructions.md when **working in this planning repo** (creating/editing issues)
- Use AGENTS.md when **implementing issues in app repo** and updating completion status

## Common Agent Tasks

### Task 1: Implement Next Issue
```bash
# 1. In planning repo - identify next issue
cd zerospoils_github_issues_pack
cat milestones/M2/140-mvp-add-item-screen-manual-entry.md

# 2. Switch to app repo
cd ../zerospoils-app

# 3. Use issue as prompt (copy acceptance criteria)
# 4. Implement feature with tests
# 5. Create PR, get review, merge

# 6. Back to planning repo - mark complete
cd ../zerospoils_github_issues_pack
# Add status section to issue file
git add milestones/M2/140-mvp-add-item-screen-manual-entry.md
git commit -m "Mark issue 140 complete: Add item screen"
git push
```

### Task 2: Review Milestone Progress
```bash
# In planning repo
cd zerospoils_github_issues_pack/milestones/M2

# Check status of each issue
grep -r "## Status" .
# or
find . -name "*.md" -exec grep -l "✅ COMPLETE" {} \;

# Count incomplete vs complete
ls -1 *.md | wc -l  # total issues
grep -l "✅ COMPLETE" *.md | wc -l  # complete issues
```

### Task 3: Update Blocked Issue
```markdown
---

## Status
⚠️ **BLOCKED** — Waiting for issue 100 (local storage) to merge

**Blocker details:**
- Requires repository pattern from issue 100
- Cannot implement state management without data layer
- ETA: Unblocked after 2026-01-18 (issue 100 PR #87 in review)
```

### Task 4: Document Scope Change
```markdown
---

## Status
🔄 **SCOPE CHANGED** — Implementation revealed additional requirements

**Changes:**
- Added error boundary for offline mode (not in original DoD)
- Split into 2 PRs: UI (#123) + repository integration (#124)
- Added 5 additional widget tests for error states

**Original issue still valid:** Core acceptance criteria met.
```

## Best Practices

### DO
- ✅ Mark issues complete immediately after merge (don't batch updates)
- ✅ Add status section to every issue you work on
- ✅ Document deviations from plan (helps future agents understand context)
- ✅ Update milestone README when last issue completes
- ✅ Link app repo PRs back to planning issues

### DON'T
- ❌ Update issue status before PR is merged (wait until in main branch)
- ❌ Delete acceptance criteria or test plans (even if implementation differs)
- ❌ Work on dependent issues before blockers are complete
- ❌ Skip test plan execution (every issue requires automated + manual tests)
- ❌ Create high-fidelity designs in early milestones (wireframes only until launch)

## Troubleshooting

### "Issue acceptance criteria unclear"
1. Check implementation notes section
2. Review referenced documentation (docs/mvp.md, docs/data-model.md, etc.)
3. Look at similar completed issues for patterns
4. If still unclear, add clarification request to issue status

### "Test plan has empty stubs"
1. **Don't skip tests** — infer reasonable test cases from acceptance criteria
2. Add concrete tests to issue file (update planning repo)
3. Document what you added in commit message

### "Dependency not met"
1. Check blocker issue status section
2. If blocker is complete but not marked, verify in app repo
3. If blocker incomplete, mark current issue as blocked (see Task 3 above)

### "Implementation differs significantly from issue"
1. Document changes in issue status section (see Task 4 above)
2. Consider creating follow-up issue if scope expanded significantly
3. Update any dependent issues that may be affected

## Versioning This Guide

When updating AGENTS.md:
- Add changelog entry at bottom of file
- Increment version number
- Notify team if workflow changes significantly

---

## Changelog

### v1.0 (2026-01-12)
- Initial version
- Defined 4-phase workflow (selection → implementation → status update → cross-reference)
- Established status format conventions
- Added agent-specific guidelines for sequential/parallel work
- Documented common tasks and troubleshooting

---

**Questions?** See `.github/copilot-instructions.md` for repo structure details or open discussion in planning repo issues.
