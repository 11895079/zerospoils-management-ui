# Copilot Instructions for zerospoils-management-ui

## Mandatory Pre-PR CI Validation

Before creating or updating any pull request, always run the local CI-equivalent checks from the repository root and confirm all commands succeed.

Required command sequence:

```bash
npm --prefix api run build
npm --prefix api run test:unit
npm --prefix worker run build
npm --prefix frontend run build
npm --prefix frontend run test -- --run
npm --prefix frontend run test:e2e -- --project=chromium
```

## PR Creation Gate

Do not open a PR until:

1. All required local CI commands pass with exit code 0.
2. No uncommitted changes remain from generated test artifacts.
3. The branch is pushed and ready for CI.

## If Any Check Fails

1. Stop PR creation.
2. Fix the failing issue first.
3. Re-run the full required command sequence.
4. Only create/update the PR after all checks pass.

## CI Failure Follow-up

If a PR CI run fails:

1. Reproduce the failing step locally using the same command.
2. Fix the issue.
3. Re-run the full local CI sequence.
4. Push only after full local validation is green.
