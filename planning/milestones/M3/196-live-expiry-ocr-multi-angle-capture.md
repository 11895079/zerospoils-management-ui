## Context
Issue 142 delivered the first free-tier expiry OCR path, but it still depends on a single still photo and falls back too often when labels are angled, glossy, or printed near manufacture dates. Users now need a more reliable mobile capture workflow that guides them through several viewpoints, detects expiry text live, and reduces manual retries on real packaging.

## Goal
Deliver a dedicated live expiry OCR capture flow that can scan up to five package angles, optionally auto-capture when a valid expiry date is detected, and provide haptic feedback when recognition is confident enough for review.

## Expected behavior
- Add-item expiry OCR opens a dedicated live camera experience instead of a single-shot camera picker
- User can capture up to 5 photos for the same item to improve detection across glare, curved packaging, and crowded labels
- Auto-capture is enabled by default and captures a frame once OCR detects an expiry-labelled date; user can switch auto-capture off and take photos manually
- Device provides haptic feedback when a likely expiry date is detected in the live preview so the user knows the scan is working before capture completes
- The workflow prefers expiry-labelled dates over manufacture or packed-on dates when multiple dates are visible
- After capture, the best detected expiry date is returned to the add-item form and remains editable before saving
- Works fully offline using on-device text recognition only
- Telemetry distinguishes camera opens, auto-captures, manual captures, haptic detections, and successful date handoff back into the form

## Acceptance criteria (Definition of Done)
- [ ] Replace the single-shot expiry OCR flow with a dedicated live camera screen for supported mobile platforms
- [ ] Live screen shows capture guidance, current progress, and a visible auto-capture toggle
- [ ] Auto-capture is on by default, persisted locally, and can be turned off without leaving the flow
- [ ] Live OCR detection triggers haptic feedback with debounce so repeated detections do not spam vibration
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
- Barcode scanning or product lookup
- Cloud OCR APIs or server-side post-processing
- Background batch scanning for multiple distinct items in one session
- Advanced camera overlays such as polygon detection or AR alignment guides

## Implementation notes
- Keep the flow behind the existing `expiry_date_ocr` feature flag; this is still a free-tier entry acceleration path
- Use a camera preview stream on mobile with throttled OCR analysis; maintain a separate still-image pass for captured photos when needed
- Persist the auto-capture toggle locally so the next scan reuses the user’s last preference
- Model capture-session behavior in pure Dart to keep auto-capture cooldowns, haptic debounce, and 5-photo limits testable without device plugins
- Rank candidate dates using nearby keyword context so labels like `EXP`, `Best By`, and `Use By` beat manufacture-oriented labels
- Capture telemetry granularly enough to compare auto-capture success rates against manual capture fallback
- Continue returning an editable `ExpiryDateOcrScanResult` back into existing item-entry forms rather than saving directly from the camera flow

## Test plan
**Automated:**
- Unit test: capture-session logic respects auto-capture toggle, 5-photo cap, and haptic debounce windows
- Unit test: parser prefers expiry-labelled dates over manufacture-labelled dates in mixed OCR text
- Widget test: add-item expiry scan button opens guidance, launches the live capture flow, and pre-fills the returned expiry date
- Widget test: unsupported platforms or disabled feature flag hide the live scan entry point
- Integration test: mocked live detection session returns an expiry date into the add-item form without network access

**Manual:**
1. Open add item on Android and iOS, tap the expiry scan button, and verify the live camera screen opens instead of the single-shot picker
2. Scan a package with glare from one angle, then tilt to a second angle; verify auto-capture can collect multiple photos and stops at 5
3. Turn auto-capture off, manually take photos, and verify the toggle choice persists on the next scan
4. Use packaging with both manufacture and expiry dates visible; verify the returned date matches the expiry label
5. Confirm the device vibrates once when a valid expiry date is detected live and does not continuously vibrate while the same date remains on screen
6. Deny camera permission or revoke it in settings; verify graceful fallback messaging and manual entry remains usable
7. Complete the scan, return to the add-item flow, and verify the detected expiry date is announced and editable before save

## Dependencies
- M2/142 expiry date OCR foundation
- M3/130 feature flags framework
- M3/205 date format preference
- Add-item entry surfaces in the main inventory add flow and full item form