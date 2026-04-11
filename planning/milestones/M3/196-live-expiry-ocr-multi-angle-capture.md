## Context
Issue 142 delivered the first free-tier expiry OCR path, but it still depends on a single still photo and falls back too often when labels are angled, glossy, or printed near manufacture dates. Users now need a more reliable mobile capture workflow that guides them through several viewpoints, detects expiry text live, and reduces manual retries on real packaging.

## Goal
Deliver a reusable live expiry OCR capture flow that can run inside the add-item experience or a dedicated fallback flow, scan up to five package angles, optionally auto-capture when a valid expiry date is detected, and provide haptic feedback when recognition is confident enough for review.

## Expected behavior
- Add-item expiry OCR can run inside a shared add-item camera panel or, when needed, a dedicated fallback camera experience instead of the original single-shot camera picker
- User can capture up to 5 photos for the same item to improve detection across glare, curved packaging, and crowded labels
- Auto-capture is enabled by default and captures a frame once OCR detects an expiry-labelled date that remains stable long enough to be considered reliable; user can switch auto-capture off and take photos manually
- Device provides haptic feedback when a likely expiry date is detected in the live preview so the user knows the scan is working before capture completes
- Live OCR guidance and detected-text status are shown in a dedicated status panel outside the camera viewport so the scan target remains visible
- The workflow prefers expiry-labelled dates over manufacture or packed-on dates when multiple dates are visible
- After capture, the best detected expiry date is returned to the add-item form and remains editable before saving; embedded flows can then pause or collapse the camera to conserve resources
- Works fully offline using on-device text recognition only
- Telemetry distinguishes camera opens, auto-captures, manual captures, haptic detections, and successful date handoff back into the form

## Acceptance criteria (Definition of Done)
- [ ] Replace the single-shot expiry OCR flow with a reusable live camera-based expiry capture experience for supported mobile platforms
- [ ] Embedded or fallback live camera UI shows capture guidance, current progress, and a visible auto-capture toggle in a status card above or below the preview rather than over the live scan target
- [ ] Auto-capture is on by default, persisted locally, and can be turned off without leaving the flow
- [ ] Live OCR detection triggers haptic feedback with debounce so repeated detections do not spam vibration
- [ ] Auto-capture requires the same expiry value to remain stable for a short confidence window before locking the result
- [ ] User can capture a maximum of 5 photos per item; UI clearly communicates the remaining capture count
- [ ] Manual capture remains available even when auto-capture is enabled
- [ ] Detection logic favors expiry-labelled dates over manufacture / packed-on / produced-on dates when both appear in view
- [ ] Best detected date across the capture session pre-fills the expiry field in both add-item entry flows
- [ ] Telemetry events emitted for `expiry_date_scan_opened`, `expiry_date_scan_capture`, and `expiry_date_scanned` with properties covering auto/manual mode, photo count, and detection outcome
- [ ] Camera permission denial, unavailable camera, or zero detections all return the user safely to manual entry
- [ ] Unit/widget/integration tests added or updated for session logic, launcher wiring, and result handoff
- [ ] Offline-first behavior verified (no network dependency)
- [ ] Accessibility basics covered: guidance text readable, controls reachable, haptic feedback paired with visible status, and result announcement preserved

## Out of scope
- Full package OCR extraction for name, quantity, price, or batch fields (tracked separately in M3/195)
- Barcode/product lookup orchestration for packaged-item fast add (tracked separately in M3/197)
- Cloud OCR APIs or server-side post-processing
- Background batch scanning for multiple distinct items in one session
- Advanced camera overlays such as polygon detection or AR alignment guides

## Implementation notes
- Keep the flow behind the existing `expiry_date_ocr` feature flag; this is still a free-tier entry acceleration path
- Use a camera preview stream on mobile with throttled OCR analysis; maintain a separate still-image pass for captured photos when needed
- Keep recognized-text summaries and scan-status messaging outside the preview bounds; reserve the preview for framing guides and capture controls only
- Persist the auto-capture toggle locally so the next scan reuses the user’s last preference
- Model capture-session behavior in pure Dart to keep auto-capture cooldowns, haptic debounce, and 5-photo limits testable without device plugins
- Separate OCR session logic from screen routing so the same expiry-detection behavior can be embedded in the add-item form or hosted in a dedicated fallback camera surface
- Rank candidate dates using nearby keyword context so labels like `EXP`, `Best By`, and `Use By` beat manufacture-oriented labels
- Capture telemetry granularly enough to compare auto-capture success rates against manual capture fallback
- Continue returning an editable `ExpiryDateOcrScanResult` back into existing item-entry forms rather than saving directly from the camera flow

## Test plan
**Automated:**
- Unit test: capture-session logic respects auto-capture toggle, 5-photo cap, and haptic debounce windows
- Unit test: parser prefers expiry-labelled dates over manufacture-labelled dates in mixed OCR text
- Widget test: add-item expiry scan button opens guidance, launches the live capture flow, and pre-fills the returned expiry date
- Widget test: scan-status text renders outside the camera viewport and does not cover the framed target region
- Widget test: unsupported platforms or disabled feature flag hide the live scan entry point
- Integration test: mocked live detection session returns an expiry date into the add-item form without network access

**Manual:**
1. Open add item on Android and iOS, tap the expiry scan button, and verify the live camera screen opens instead of the single-shot picker
2. Hold a label near the framing area and verify live status text updates in the separate status panel without blocking the camera target region
3. Scan a package with glare from one angle, then tilt to a second angle; verify auto-capture can collect multiple photos and stops at 5
4. Turn auto-capture off, manually take photos, and verify the toggle choice persists on the next scan
5. Use packaging with both manufacture and expiry dates visible; verify the returned date matches the expiry label
6. Confirm the device vibrates once when a valid expiry date is detected live and does not continuously vibrate while the same date remains on screen
7. Deny camera permission or revoke it in settings; verify graceful fallback messaging and manual entry remains usable
8. Complete the scan, return to the add-item flow, and verify the detected expiry date is announced and editable before save

## Dependencies
- M2/142 expiry date OCR foundation
- M3/130 feature flags framework
- M3/205 date format preference
- Add-item entry surfaces in the main inventory add flow and full item form
