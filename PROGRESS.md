# ZeroSpoils Implementation Progress Tracker

## M1 — Foundations

### Status: In Progress (1/10 completed)

| Issue | Title | Status | PR | Completed |
|-------|-------|--------|----|----|
| [M1/000](planning/milestones/M1/000-create-repo-scaffolding-branch-protections-codeowners.md) | Repo scaffolding, branch protection, CODEOWNERS | ✅ DONE | [#1](https://github.com/bakintunde/zerospoils/pull/1) | Jan 16, 2026 |
| [M1/010](planning/milestones/M1/010-define-mvp-scope-as-an-executable-spec-docs-mvp-md.md) | Define MVP scope (docs/mvp.md) | ⏳ TODO | — | — |
| [M1/020](planning/milestones/M1/020-set-up-flutter-ci-lint-format-tests-on-pr.md) | Flutter CI/CD (lint, format, tests) | ⏳ TODO | — | — |
| [M1/040](planning/milestones/M1/040-define-telemetry-taxonomy-baseline-events.md) | Telemetry taxonomy (docs/telemetry.md) | ⏳ TODO | — | — |
| [M1/050](planning/milestones/M1/050-wireframes-for-core-mvp-screens.md) | Wireframes for core screens | ⏳ TODO | — | — |
| [M1/060](planning/milestones/M1/060-clickable-prototype-walkthrough-capture-feedback-5-users.md) | Clickable prototype & user feedback | ⏳ TODO | — | — |
| [M1/070](planning/milestones/M1/070-define-notification-ux-defaults.md) | Notification UX defaults | ⏳ TODO | — | — |
| [M1/080](planning/milestones/M1/080-define-v1-data-model-item-category-location-events.md) | Data model (docs/data-model.md) | ⏳ TODO | — | — |
| [M1/090](planning/milestones/M1/090-flutter-app-skeleton-routing-theming-di.md) | Flutter app skeleton (routing, DI, theming) | ⏳ TODO | — | — |
| [M1/390](planning/milestones/M1/390-ops-observability-baseline-crashes-key-events-alerts.md) | Observability baseline (crash reporting) | ⏳ TODO | — | — |

**Legend:**
- ✅ DONE – Completed and merged to main
- ⏳ TODO – Not started
- 🚧 IN PROGRESS – Feature branch created, work ongoing
- ❌ BLOCKED – Waiting on dependency

---

## Implementation Workflow (Starting Now)

All future work will follow this pattern:

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
- Update this tracker
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
