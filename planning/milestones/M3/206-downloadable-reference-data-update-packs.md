## Context
ZeroSpoils needs to evolve reference data such as barcode catalogs, categories, locations, and other app-managed lists without forcing users to reinstall the app. The packaged-item fast-add feature can ship initially with an empty or minimal local catalog, but the app needs a generic mechanism to download validated update packs later while preserving offline-first behavior and user overrides.

## Goal
Deliver a generic reference-data update-pack system that allows ZeroSpoils to fetch, validate, cache, and activate downloadable updates for barcode catalogs and other app-managed lists without requiring a full app reinstall.

## Expected behavior
- App ships with bundled defaults and can operate even if no downloadable packs are available
- App can fetch a remote manifest describing available reference-data packs and their versions
- Supported pack types include barcode catalog data, categories, locations, and other curated reference lists
- Downloaded packs are validated before activation using schema version checks, checksums, and compatibility rules
- Activation is atomic so a bad pack never corrupts the currently active reference data
- User-created data and learned mappings continue to override downloaded reference packs
- App can fall back to bundled defaults if a downloaded pack is invalid, incompatible, or removed
- Update behavior is generic and vendor-agnostic; Remote Config may point to a manifest URL but does not carry the data itself

## Acceptance criteria (Definition of Done)
- [ ] Define a generic update-pack manifest schema with pack type, region, version, checksum, minimum app version, and download URL
- [ ] Define supported reference-pack types for MVP follow-up: `barcode_catalog`, `categories`, `locations`, and generic `reference_list`
- [ ] Implement client-side precedence rules for reference data: `user-defined / learned local data -> downloaded pack -> bundled default`
- [ ] Implement pack validation covering checksum, schema version, minimum app version, and required fields before activation
- [ ] Implement atomic activation and rollback so a failed update leaves the previous active pack intact
- [ ] Implement local caching of downloaded packs for offline reuse after first download
- [ ] Document a generic adapter boundary so manifest hosting can be backed by static hosting, Supabase Storage, GitHub Releases, or another simple file host without app-layer vendor lock-in
- [ ] Settings or developer-visible diagnostics show active reference-pack versions and last update time
- [ ] App can start and function normally when remote update checks fail or no network is available
- [ ] Document how barcode catalog packs from issue 199 are packaged and delivered through this system
- [ ] Document how future categories, locations, and other app-managed lists can adopt the same mechanism without custom app-update logic
- [ ] Unit/integration tests added or updated for manifest parsing, precedence rules, pack validation, activation, rollback, and offline cache reuse
- [ ] Telemetry events documented for pack check, download, activation success/failure, and rollback outcome
- [ ] Offline-first behavior verified (bundled defaults still work when remote updates are unavailable)
- [ ] Accessibility basics covered for any user-visible update status or diagnostics UI

## Out of scope
- Full cloud sync of inventory or user data
- Per-user targeting or A/B testing for reference-data packs
- Real-time streaming updates while the app is open
- Editing downloaded reference packs directly in the app
- Remote updates for executable code or native libraries

## Implementation notes
- Keep the update mechanism generic; do not couple reference-data delivery to Firebase Remote Config values beyond optional manifest discovery
- Prefer static signed artifacts over custom backend logic for the first version of the system
- Separate manifest fetch from pack activation so validation and rollback remain testable
- Treat downloaded reference packs as replaceable caches, not as the source of truth for user-entered customizations
- Initial implementation can be internal-only or developer-enabled first, then exposed more broadly once pack quality is proven
- The hybrid barcode flow from issue 197 should not block on this system; it must still work with empty bundled data and learned local mappings only

## Test plan
**Automated:**
- Unit test: manifest parser rejects unsupported schema versions and missing required fields
- Unit test: precedence rules return user-defined data over downloaded pack data and downloaded pack data over bundled defaults
- Unit test: invalid checksum or incompatible minimum app version prevents activation
- Integration test: previously active pack remains in place after a failed activation attempt
- Integration test: downloaded pack remains usable offline after successful cache and activation

**Manual:**
1. Start the app with bundled defaults only and verify reference data still works without any remote packs
2. Point the app at a test manifest with a valid categories or barcode pack and verify it downloads and activates successfully
3. Replace the manifest with a bad checksum pack and verify the app rejects it and preserves the previous active version
4. Disconnect network after a successful download and restart the app; verify the cached pack remains active offline
5. Inspect diagnostics UI or logs and verify active version, last update time, and failure reason are visible

## Dependencies
- M3/130 feature flags framework (adapter and precedence patterns)
- M3/360 Firebase integration if Remote Config is used only as manifest discovery
- M3/197 hybrid packaged-item fast add (initial consumer)
- M3/199 Canada seed barcode catalog curation and packaging