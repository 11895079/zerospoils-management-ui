# Progress Tracking (Deprecated)

This root-level progress tracker is deprecated.

Progress is now maintained within each milestone README:
- M1: [planning/milestones/M1/README.md](planning/milestones/M1/README.md)
- M2: [planning/milestones/M2/README.md](planning/milestones/M2/README.md)

---

Please update the relevant milestone README with status tables, PR links, and dates.


## Implementation Workflow

### 1. Create Feature Branch
```bash
git checkout main
git pull origin main
git checkout -b feature/descriptive-name
```

### 2. Implement Issue
- Use acceptance criteria as your spec
- Add code, tests, docs per Definition of Done
- Commit with conventional commits

### 3. Create PR Against Main
```bash
git push origin feature/descriptive-name
gh pr create --base main --fill
```

### 4. Code Review
- Address feedback
- Get approval

### 5. Merge & Update Progress
```bash
gh pr merge --squash  # Squash merge for clean history
```
- Update the milestone README
- Close feature branch

---

## Quick Links

- **Planning:** [planning/README.md](planning/README.md)
- **M1 Details:** [planning/milestones/M1/README.md](planning/milestones/M1/README.md)
- **Contributing Guide:** [CONTRIBUTING.md](CONTRIBUTING.md)

---

## Notes
- Completed issues are archived but remain in git history
- PRs link to planning issues for traceability
- Each PR = one issue (focused changes)