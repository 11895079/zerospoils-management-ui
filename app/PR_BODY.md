## Summary
This PR implements the first batch of M2 MVP features, excluding audit log persistence. It covers:
- Local storage infrastructure and migrations (M2/100)
- Expiry bucketing logic and classifier (M2/110)
- Shopping list repository with Hive persistence (M2/101)
- Onboarding and notification permissions flow (M2/120)
- Telemetry instrumentation for key actions
- Test and CI reliability improvements

## Details
- Adds Hive-based repositories for inventory and shopping list
- Implements expiry bucketing and classifier utilities
- Integrates onboarding and permissions screens
- Refactors and fixes widget/unit tests for TDD compliance
- Excludes audit log (M2/102) pending further implementation

## Linked Issues
- Closes M2/100, M2/101, M2/110, M2/120

## Test Plan
- All tests pass (excluding audit log TDD stubs)
- Manual onboarding and permissions flow verified
