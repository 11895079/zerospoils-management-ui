## Context
We need a safe way to gate upcoming Pro/IoT/back-end features and control rollout of potentially high-cost capabilities (e.g., OCR, cloud export) without scattering `if` checks throughout the app.

## Goal
Implement a lightweight, testable feature-flag layer with:
- Code defaults (source of truth)
- Local overrides for dev/testing
- A clean path to optional remote overrides later (without locking into a vendor)

## Expected behavior
- Flags are evaluated via a single `FeatureFlags` service (no ad-hoc checks).
- Defaults are deterministic and versioned in code.
- Debug builds can override flags and persist overrides across restarts.
- Release builds do not expose a flag UI.

## Acceptance criteria (Definition of Done)
- [ ] Define a typed flag registry (enum/sealed keys) with defaults in one file (e.g., `FeatureFlagKey` + default map).
- [ ] Include initial flags: `cloud_sync`, `cloud_analytics_export`, `receipt_ocr`, `batch_photo_capture`, `household_sync`, `iot_hooks`, `expiry_date_ocr`.
- [ ] Implement `FeatureFlags` resolution precedence: `local_override > remote_override (optional) > default`.
- [ ] Implement local override persistence and a “reset all overrides” action.
- [ ] Add a Developer Settings screen (debug/internal builds only) that lists all flags and allows toggling overrides.
- [ ] Use at least 2 flags in real navigation/UX (example: hide “Cloud analytics export” toggle unless `cloud_analytics_export` is enabled; hide OCR entry method unless `expiry_date_ocr` is enabled).
- [ ] Create `docs/flags.md` listing: key, description, default, target milestone, and cost-impact notes.

## Out of scope
- Percentage rollouts / A/B experiments.
- Remote targeting / per-user flags.

## Implementation notes
- Keep checks centralized (inject `FeatureFlags` via DI).
- Avoid vendor-specific Remote Config SDKs; if remote overrides are added later, consume a generic JSON document behind an adapter.

## Test plan
**Automated:**
- Unit tests: precedence rules, default values, override persistence, reset behavior.
- Widget test: Developer Settings renders all flags; toggling a flag updates UI state; reset restores defaults.

**Manual:**
1. Debug build: open Developer Settings and toggle `expiry_date_ocr`; verify the OCR entry option appears/disappears.
2. Restart app; verify overrides persist.
3. Reset overrides; verify defaults restored.

## Dependencies
- None
