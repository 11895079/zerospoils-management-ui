# ZeroSpoils Dependency Map

Last Updated: April 18, 2026

This document tracks dependency order across milestones using the status files in `planning/milestones/`.

## Status Snapshot

| Milestone | Progress | Source |
|---|---:|---|
| M1 Foundations | 10/10 complete | `planning/milestones/M1/README.md` |
| M2 Offline MVP | 13/17 complete | `planning/milestones/M2/README.md` |
| M3 MVP Quality and Shopping | 14/22 complete | `planning/milestones/M3/README.md` |
| M4 Beta Testing | 0/10 complete (work in progress) | `planning/milestones/M4/README.md` |

## Dependency Order

### Foundation Chain (complete)
1. M1/090 Flutter app skeleton
2. M2 core offline features (storage, add item, inventory, item detail)
3. M3 quality and expansion features (telemetry, shopping, OCR improvements)
4. M4 beta distribution and launch hardening

### Current Blockers and Gating Items
1. M2/030 Build pipelines (Android first pass) gates consistent beta build delivery.
2. M2/190 Batch receipt capture MVP is still partial and blocks downstream receipt experience consistency.
3. M3/198 Shopping batch receipt capture, M3/201 Receipt line-item AR overlay, and M3/202 Fresh produce packaged item recognition are not started and block full receipt-assisted shopping workflows.
4. M3/206 Downloadable reference-data packs is not started and blocks production-safe remote updates for barcode and catalog data.
5. M3/350 Zesto Phase 1 depends on badge hooks being fully connected to UX progression.
6. M3/361 Firebase App Distribution tester API flow is not started and blocks streamlined closed-testing feedback loops.

## Recommended Critical Path (Now)

1. Close M2 infra and partials:
   - M2/030
   - M2/155 follow-up telemetry and accessibility
   - M2/190 remaining entry-point/permission gaps
2. Close highest-impact M3 gaps:
   - M3/198, M3/201, M3/202
   - M3/206
   - M3/350
   - M3/361
3. Re-baseline M4 issue status after open PRs and security hardening tasks are merged.

## Notes

- This map is intentionally lightweight. The issue files and milestone READMEs remain the source of truth.
- When issue status changes, update milestone README first, then refresh this file.
