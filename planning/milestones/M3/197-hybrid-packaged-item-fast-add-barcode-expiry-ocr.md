## Context
Free users can now scan expiry dates more reliably, but packaged-item entry is still too slow because product identity often has to be typed manually. Barcode scanning is strong for product identification, while expiry OCR is still needed because expiry dates are rarely encoded in the barcode itself. The roadmap currently splits package OCR and expiry OCR into separate follow-ups, but it does not yet define a single sub-10-second packaged-item add flow for the free tier.

## Goal
Deliver a hybrid packaged-item fast-add flow that uses barcode scanning for product identity, learned local mappings plus optional bundled or downloaded reference catalogs for lookup, live expiry OCR for date capture, and a compact confirmation step so common packaged items can be added in under 10 seconds on a warm path.

## Expected behavior
- Add-item entry can show a camera-assisted packaged-item mode on supported mobile platforms within the same add-item view rather than forcing a separate scanner screen
- When camera-assisted add is enabled, a single camera panel appears at the top of the add-item surface and starts barcode detection immediately
- Stage 1 guidance tells the user to scan a barcode first if one exists on the package
- When a barcode is recognized, the app looks up the code locally using learned mappings first and then any available bundled or downloaded reference catalog, and pre-fills any known product fields such as name, brand, category, and quantity/unit hints
- Inline feedback below or beside the camera panel shows what product information was extracted before the user moves on
- The same camera panel then shifts to expiry capture guidance without forcing navigation away from the add-item form
- Stage 2 guidance tells the user to point the package at the expiry label; once a likely expiry date is held clearly for a short stability window, the app auto-captures the date and stops or collapses the camera panel to conserve resources
- If the barcode is unknown, the flow shows a quick "Not found" state and falls back to compact manual entry plus optional expiry OCR instead of blocking the user
- When the user confirms the item, the app stores or updates the confirmed barcode-to-product mapping locally so the next scan works offline and can override stale bundled metadata
- Free users can complete a known packaged item with visible expiry in under 10 seconds on the happy path; this flow complements, rather than replaces, the separate free-tier shopping batch capture path
- Telemetry captures barcode hit/miss rates, expiry-prefill usage, fallback frequency, and end-to-end add duration
- Works offline without a required remote product catalog lookup

## Acceptance criteria (Definition of Done)
- [ ] Add a packaged-item fast-add entry point to the inventory add flow and full item form on supported mobile platforms
- [ ] Add a user setting that enables or disables camera-assisted add-item capture on supported mobile platforms
- [ ] Camera-assisted mode uses a single embedded top-of-form camera panel rather than separate barcode and expiry scanner screens
- [ ] Barcode scanning starts immediately on fast-add open and detects common UPC/EAN/GTIN formats on-device
- [ ] Implement lookup precedence of `learned local mappings -> available reference catalog -> manual fallback`, with no remote dependency required for save
- [ ] Initial release path supports an empty reference catalog so the feature can ship before curated data packs are ready
- [ ] Implement a local barcode lookup store that can return and persist confirmed product metadata: `name`, `brand`, `category`, `quantity_hint`, `unit_hint`, `region`, `source`, and `last_confirmed_at`
- [ ] Camera panel presents staged guidance: barcode first, expiry second
- [ ] Barcode hit path shows inline extraction feedback for product identity before expiry capture begins
- [ ] Barcode hit path pre-fills the compact confirmation sheet without requiring the full manual form for the common case
- [ ] Barcode miss path shows a clear "Product not found" state within the same flow and allows manual entry plus optional expiry OCR without losing progress
- [ ] Fast-add can launch or continue the existing live expiry OCR flow in the same packaged-item session
- [ ] Expiry capture auto-locks only after the detected expiry value remains stable for a short confidence window, then the camera panel pauses, collapses, or closes to conserve device resources
- [ ] Saving a confirmed item learns or updates the local barcode mapping for future offline scans and overrides bundled seed values when user-confirmed data differs
- [ ] Compact confirmation sheet keeps the number of required manual inputs to the minimum necessary for save
- [ ] Telemetry events emitted for `packaged_item_fast_add_opened`, `barcode_lookup_completed`, `packaged_item_fast_add_saved`, and `barcode_mapping_learned` with properties covering lookup source (`learned` | `seed` | `manual`), hit/miss, expiry prefill, stage transitions, camera-assist enabled state, and duration
- [ ] Manual validation confirms a known barcode + visible expiry happy path can be completed in under 10 seconds on a reference Android device
- [ ] Unknown-barcode flow remains usable offline and never traps the user in the scanner
- [ ] Packaged-item fast add remains a focused single-item flow and does not depend on the separate shopping batch capture path to succeed
- [ ] If a bundled or downloaded reference catalog is used, packaging keeps install size and storage growth within an acceptable range for MVP by shipping curated subsets instead of raw dumps
- [ ] Unit/widget/integration tests added or updated for barcode lookup, miss fallback, expiry handoff, and learned barcode reuse
- [ ] Telemetry added/updated with event names and key properties documented
- [ ] Offline-first behavior verified (barcode lookup and learned mappings usable with no network access)
- [ ] Accessibility basics covered: scanner guidance readable, controls reachable, success/failure states announced, and compact confirmation fields labeled

## Out of scope
- Mandatory online lookup or cloud-synced product catalog for MVP save flow
- Receipt OCR or multi-item batch ingestion inside this specific fast-add story
- Barcode-only save with no confirmation step
- Cloud sync of learned barcode mappings across devices
- Advanced nutrition/product enrichment from third-party APIs
- Non-mobile platforms for the scanner entry point

## Implementation notes
- Treat barcode scan as the primary product-identity signal for packaged goods; use expiry OCR as the paired date-capture step, not as a replacement for barcode identity
- Keep the flow privacy-first and offline-first by making local lookup the default behavior; if no local match exists, continue with manual confirmation instead of requiring network
- Prefer one camera panel with an internal state machine over two separate camera views:
	- `barcode_scan`
	- `barcode_result`
	- `expiry_scan`
	- `expiry_locked`
	- `edit_confirm`
- Use a layered local catalog strategy:
	- writable learned local catalog for user-confirmed additions and corrections
	- optional bundled or downloaded reference catalog for curated packaged-product hints
- Lookup precedence should be: learned local mapping first, available reference catalog second, then manual fallback
- Seed the learned barcode lookup store from user-confirmed saves so the app gets faster over time and user-confirmed data can supersede any bundled or downloaded reference entries
- Reuse the existing live expiry OCR session logic, but adapt the add-item UX so expiry scanning can run inside the shared camera panel instead of requiring a dedicated navigation step
- Keep barcode and expiry guidance visually explicit so users know what the camera is looking for at each stage
- Prefer a compact confirmation surface optimized for one-handed completion rather than sending every scan through the full add-item form
- Record duration from fast-add open to save so the team can measure whether the sub-10-second target is actually being met
- Keep this story focused on fast single packaged-item entry; shopping batch capture can coexist as a separate free-tier entry path, while receipt OCR remains deferred
- If barcode lookup returns stale or partial metadata, prefill what is known and let the user correct it before save; corrected values should update the stored mapping
- Start with an empty reference catalog if needed for initial release, then add Canada-first curated packs later without redesigning the feature flow
- If third-party open data such as OpenFoodFacts is used to build a bundled or downloadable catalog pack, document license, attribution, and refresh process before release

## Test plan
**Automated:**
- Unit test: lookup precedence returns learned mapping before bundled seed data for the same UPC/EAN/GTIN
- Unit test: available reference catalog returns product metadata for a known barcode and reports miss for unknown code
- Unit test: saving a confirmed packaged item learns a new barcode mapping and updates an existing mapping when fields change
- Widget test: packaged-item fast-add entry point and camera-assisted setting behave correctly on supported mobile platforms and are hidden on unsupported platforms or when the feature flag is disabled
- Widget test: embedded camera panel shows barcode-first guidance, then expiry guidance after a barcode hit
- Widget test: barcode hit path shows inline extracted product details and can continue into expiry OCR handoff without leaving the add-item screen
- Widget test: barcode miss path shows "Product not found" and still allows manual name entry plus expiry OCR
- Widget test: expiry value must remain stable for the configured confidence window before auto-locking and collapsing the camera panel
- Widget test: corrected prefilled values persist back into the learned barcode lookup store for future scans
- Integration test: known barcode + mocked expiry OCR result completes save without opening the full manual form
- Integration test: unknown barcode path falls back safely, saves item, and makes the next identical barcode scan return the learned mapping offline
- Integration test: feature still works with an empty reference catalog and learns the scanned barcode after manual confirmation

**Manual:**
1. Open fast add on Android with an empty reference catalog and verify an unknown barcode falls back cleanly to manual confirmation plus learning
2. Enable camera-assisted add in settings, open add item, and verify the camera panel appears at the top of the same add-item screen
3. Scan a package barcode and verify extracted product details appear inline before expiry guidance begins
4. Continue into expiry OCR, hold a visible expiry label steady, and verify the camera panel auto-locks the date after the stability window and then pauses or collapses
5. Save the item and verify the full known-barcode path can be completed in under 10 seconds on a warm run
6. Scan an unknown barcode and verify the flow shows "Product not found" without leaving the add-item screen or losing the ability to continue manually
7. Manually enter the product name for the unknown barcode, save, then scan the same barcode again offline and verify the learned mapping now pre-fills the product
8. Scan a product with incorrect stored metadata, edit the name or category before save, and verify the next scan returns the corrected values
9. Disable network connectivity and repeat a known-barcode scan; verify local lookup and expiry OCR still function
10. Verify packaged-item fast add still behaves as a focused single-item flow and does not regress the separate shopping batch capture entry path
11. Use TalkBack or VoiceOver and verify scanner guidance, hit/miss states, stage changes, and compact confirmation fields are announced clearly

## Dependencies
- M2/140 add-item screen manual entry foundation
- M2/142 expiry date OCR foundation
- M3/130 feature flags framework
- M3/196 live expiry OCR multi-angle capture
- M3/199 Canada seed barcode catalog curation and packaging (optional follow-up for cold-start catalog coverage)
- M3/206 downloadable reference-data update packs (optional follow-up for post-release catalog/list updates)
- M1/080 data model support for barcode-backed packaged items