# Windows Store Closed Testing Plan

## Overview

This document captures the rollout plan for ZeroSpoils Windows desktop closed testing using an MSIX package distributed through Microsoft Store private audience or Store flighting.

**Distribution choice:** Microsoft Store private audience or Store flighting  
**Package format:** MSIX  
**Goal:** Invite-only Windows beta distribution with controlled install/update flow and backend-gated app access.

---

## 1. Delivery Model

### 1.1 Recommended path

- Publish the Windows desktop build as an **MSIX** package.
- Submit it to **Microsoft Store Partner Center**.
- Use either:
  - **Private audience** for restricted tester visibility, or
  - **Store flighting** for staged prerelease rollout to selected testers.

### 1.2 Why this path

- Signed Store distribution reduces install friction for testers.
- Store-managed updates simplify beta iteration.
- Private audience/flighting gives a real closed-test channel without public discovery.
- This is the closest Windows equivalent to a managed beta experience.

---

## 2. Packaging Requirements

### 2.1 MSIX packaging

- [ ] Confirm Windows release build succeeds from CI and locally.
- [ ] Produce an **MSIX** package instead of distributing a raw `.exe`.
- [ ] Define package identity:
  - Package name
  - Publisher/display name
  - Versioning scheme aligned to app release versions
- [ ] Verify icons, assets, and app metadata required by Store packaging.

### 2.2 Signing

- [ ] Use the Microsoft Store submission/signing flow for Store-distributed packages.
- [ ] Keep certificate/signing material out of the repo and in CI secrets if any pre-submission signing step is required.

### 2.3 Platform verification

- [ ] Verify install, launch, update, and uninstall on a clean Windows test machine.
- [ ] Verify first-run experience on a non-developer machine.
- [ ] Verify deep links / auth handoff still work under MSIX packaging if used.

---

## 3. Partner Center Setup

### 3.1 Store onboarding

- [ ] Create or confirm Microsoft Partner Center account access.
- [ ] Reserve the app listing name.
- [ ] Configure app identity, category, privacy URL, support URL, and store metadata.

### 3.2 Closed-testing setup

- [ ] Decide whether the first wave uses:
  - private audience only, or
  - a named Store flight.
- [ ] Create tester cohort(s):
  - internal team
  - trusted beta users
  - wider prerelease group
- [ ] Document who manages tester membership changes.

### 3.3 Release notes and cadence

- [ ] Standardize release note format for Windows beta builds.
- [ ] Define beta promotion cadence:
  - ad hoc hotfixes
  - weekly beta builds
  - milestone-based promotion

---

## 4. Access Control And Security

### 4.1 Distribution control

- [ ] Restrict discovery to the selected private audience / flight.
- [ ] Do not distribute raw unsigned binaries outside the Store for the same cohort.

### 4.2 App-level gating

- [ ] Require app sign-in for beta access if Windows testing includes non-public features.
- [ ] Add backend allowlist / entitlement gating for Windows testers.
- [ ] Make copied packages unusable for unauthorized users by checking identity/entitlement at runtime.

### 4.3 Minimum controls for beta

- [ ] Enforce tester allowlist or role/claim check.
- [ ] Add remote kill-switch coverage for beta-only functionality where appropriate.
- [ ] Log Windows app version and platform in telemetry for tester triage.

---

## 5. Operational Readiness

### 5.1 Support flow

- [ ] Define where testers report issues: GitHub, email, form, or Discord/Teams.
- [ ] Include tester instructions for:
  - install/update
  - sign-in
  - reporting bugs
  - attaching logs/screenshots

### 5.2 Monitoring

- [ ] Verify crash/error reporting works on Windows packaged builds.
- [ ] Add a Windows-specific smoke checklist for each beta drop.
- [ ] Track tester adoption, install success, and crash trends separately from mobile.

---

## 6. CI/CD Follow-Up For This Repo

These are the concrete implementation follow-ups that should be handled after this planning pass.

- [ ] Add Windows packaging workflow that outputs an MSIX-ready artifact.
- [ ] Add Store metadata/versioning guidance to the release process.
- [ ] Add Windows beta release checklist steps to CI/release docs.
- [ ] Add a documented procedure for promoting a build from internal testers to wider private audience / flight.

---

## 7. First Beta Checklist

- [ ] Windows build passes.
- [ ] MSIX package generated.
- [ ] Store listing draft completed.
- [ ] Private audience or flight created.
- [ ] Tester identities added.
- [ ] Sign-in / entitlement gating verified.
- [ ] Crash reporting verified on packaged build.
- [ ] Install and update tested on clean Windows device.
- [ ] Tester instructions prepared and shared.

---

## Recommendation

For ZeroSpoils, the best near-term closed-testing path is:

1. Build and package the Windows app as MSIX.
2. Publish through Microsoft Store Partner Center.
3. Start with a small private audience or internal flight.
4. Require sign-in and tester allowlist/entitlement checks.
5. Expand the tester group only after install/update/crash behavior is stable.

This gives controlled Windows beta distribution with lower tester friction than private installer sharing and stronger operational control than distributing standalone binaries.
