# zerospoils — Claude Code guidance

## Repository layout

| Path | Purpose |
|------|---------|
| `/Users/oba/code/zs` | **Main dev copy.** Active feature branches live here. Do not commit PR-review fixes here. |
| `/Users/oba/code/zs-pr` | **PR review workspace.** Always use this directory when addressing review comments, Copilot feedback, or any fix that targets an open PR branch. |

## PR review workflow

1. `git -C /Users/oba/code/zs-pr fetch origin`
2. `git -C /Users/oba/code/zs-pr checkout <pr-branch>`
3. Make changes, run tests, commit, push — all inside `zs-pr`.
4. After the PR merges: `git -C /Users/oba/code/zs-pr checkout pr-workspace` to reset to neutral.

Never use temporary `.claude/worktrees/` paths for PR work — use `zs-pr` so there is no setup/teardown overhead and the session CWD stays stable.

## Flutter project root

All `flutter`, `dart`, and `gh` commands run from `app/`.

## Testing — run locally before every push

```bash
flutter test                              # full suite
flutter test test/unit/                   # unit only
flutter test test/widget/                 # widget only
flutter analyze --no-fatal-infos
dart format --set-exit-if-changed .
```

Target: **≥ 80% coverage on files you touched**.

## TDD mandate

For every feature, bugfix, or refactor:
1. Write a **failing** test first (unit / widget / integration).
2. Verify it fails.
3. Implement until it passes.

No exceptions. This applies to all work items.

## Widget test anti-patterns

**Never** find widgets by text string — copy changes silently break those tests. Use:

```dart
// ✅ find by key, icon, type, or widget predicate
find.byKey(const Key('submit_button'))
find.byIcon(Icons.check_circle)
find.byType(QuantityToggle)
find.byWidgetPredicate((w) => w is Switch && w.value == false)

// ❌ brittle — breaks on any copy change
find.text('Confirm')
find.text('Submit')
```

Verify behaviour by inspecting widget properties and model state, not rendered strings.

## Review thread resolution gate

When addressing PR review comments:

1. **Gather all unresolved threads first** before writing any code.
2. Implement the minimal verified fix (or write an explicit rationale if no code change is needed).
3. **Do not resolve a thread until**: (a) the fix is committed, (b) relevant tests pass locally, and (c) the commit is pushed to the PR branch.
4. After pushing, resolve every addressed thread via GraphQL — REST `PATCH` does not resolve threads:

```bash
gh api graphql -f query='
  mutation($id: ID!) {
    resolveReviewThread(input: {threadId: $id}) {
      thread { id isResolved }
    }
  }' -f id=<THREAD_NODE_ID>
```

Get thread node IDs with:
```bash
gh api graphql -f query='{
  repository(owner: "11895079", name: "zerospoils") {
    pullRequest(number: <N>) {
      reviewThreads(first: 20) {
        nodes { id isResolved comments(first:1) { nodes { databaseId body } } }
      }
    }
  }
}'
```

## GitHub CLI — always use `gh api` for PR/issue body updates

`gh pr edit` and `gh issue edit` have argument-parsing bugs with multi-line text. Use:

```bash
# Update PR body (file-based, avoids all escaping issues)
gh api -X PATCH "repos/11895079/zerospoils/pulls/<N>" -F body=@description.txt

# Update PR title (inline is fine)
gh api -X PATCH "repos/11895079/zerospoils/pulls/<N>" -F title="New title"
```

## Hard rules — never do these

- **Never `--no-verify`** on commits. If a hook fails, fix the underlying issue.
- **Never commit secrets, API keys, or PII.**
- **Never push directly to `main`** — all changes go through PRs.
- **Never leave empty test plan stubs** in planning issues.
- **Never search for text strings in widget tests** (see widget test section above).

## CI cost optimisation (beta distribution)

For beta tags (`v*-b[0-9]*`), minimise Actions minutes:

1. Use the platform-specific workflow for the failing platform only:
   - `distribute-beta-android.yml` for Android
   - `distribute-beta-ios.yml` for iOS
2. **Retry only the failed platform.** Do not retrigger both when one fails.
3. Use "Rerun failed jobs" before creating a new tag.
4. Cancel stale in-progress runs for the same tag before retrying.
5. Recreate/push the same tag only as a last resort.
6. Build step timeout: 40 min. Job timeout: 60 min.

```bash
gh run list --workflow=distribute-beta-android.yml --limit 5
gh run list --workflow=distribute-beta-ios.yml --limit 5
gh run cancel <RUN_ID>
gh run rerun <RUN_ID>
```

## Commit style

Conventional Commits. Co-author line on every AI-assisted commit:
```
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## Full project instructions

The complete Copilot instructions (planning workflow, issue conventions, executive briefing format, architecture decisions) live at:
```
.github/copilot-instructions.md
```
Read that file when working on planning artifacts, executive reports, or anything not covered above.
