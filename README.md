# ZeroSpoils GitHub Issues Pack

This issue pack is meant only for initial planning and setup on GitHub

This folder contains a Codex/Copilot-friendly backlog:
- `issues/`   : Markdown issue bodies
- `issues.csv`: Bulk creation manifest for `gh issue create`
- `scripts/`  : Helper scripts (milestones, labels)

## Recommended setup (once per repo)
1) Install GitHub CLI.
2) Authenticate:
   ```bash
   gh auth login
   ```
3) Create milestones and labels (optional but recommended):
   ```bash
   bash scripts/create_milestones.sh
   bash scripts/create_labels.sh
   ```

## Bulk-create issues
Run from the repo root:

```bash
while IFS=, read -r title file labels milestone; do
  if [ "$title" = "title" ]; then continue; fi

  args=(--title "$title" --body-file "$file" --label "$labels")
  if [ -n "$milestone" ]; then args+=(--milestone "$milestone"); fi

  gh issue create "${args[@]}"
done < issues.csv
```

## Notes for Codex/Copilot in VS Code
- Work one issue at a time.
- Keep PRs small: implement + tests + telemetry + docs.
- Use the issue acceptance criteria as the direct prompt for Codex/Copilot.
