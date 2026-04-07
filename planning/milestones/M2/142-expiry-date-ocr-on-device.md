## Context
Manual date entry is tedious and error-prone. On-device OCR for expiry dates reduces friction and improves data quality.

## Goal
Enable users to scan product labels with device camera and auto-extract expiry dates using Google ML Kit (offline, privacy-first). This is a free-tier acceleration path for manual item entry, not a Pro feature.

## Expected behavior
- Camera icon button next to expiry date field in Add Item form
- Tap button → open camera view → capture product label
- ML Kit Text Recognition extracts text → parse for date patterns
- Pre-fill expiry date field with extracted date (user can edit if incorrect)
- Graceful fallback to manual entry if OCR fails or unavailable

## Acceptance criteria (Definition of Done)
- [x] Feature available to free users via `expiry_date_ocr` feature flag; no Pro entitlement required
- [x] Camera permission requested on first tap; denial returns user to manual entry and allows retry
- [x] Camera button appears next to expiry date field when `expiry_date_ocr` is enabled on supported mobile platforms
- [x] Camera capture guidance shown before opening the camera ("Point camera at expiry date")
- [x] Date parsing supports formats: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, and labels ("Best By", "Use By", "Exp")
- [x] Extracted date pre-fills expiry field and remains editable
- [x] OCR failure shows toast and returns to manual entry
- [x] Unsupported platforms hide the OCR button (no crash)
- [x] Telemetry event `expiry_date_scanned` emitted with properties { success, format_detected }
- [x] Offline-first verified (no network required)
- [x] Accessibility basics: camera button labeled; successful OCR result announced

- [x] Google ML Kit Text Recognition integrated for supported mobile platforms
- [ ] Unit/widget/integration tests added or updated

## Out of scope
- Full receipt OCR (deferred to M6 Pro tier)
- Full package OCR extracting name/category/quantity/price (handled by M3/195)
- Barcode scanning for product lookup
- Cloud-based OCR (Google Vision API)
- Multi-item batch scanning

## Implementation notes
- Use Google ML Kit Text Recognition v2 (on-device, free); keep behind feature flag for kill-switch control, but not Pro gating
- iOS: `GoogleMLKit/TextRecognition` pod
- Android: `com.google.mlkit:text-recognition` Maven
- Date parsing regex: capture common patterns, prioritize dates within next 2 years (avoid false positives)
- Camera UI: current implementation shows a guidance dialog before native camera capture; a custom in-camera overlay remains optional follow-up work if accuracy testing shows it is needed
- Permission handling: Request camera on first tap; graceful denial handling
- Keep manual entry as primary method; OCR is optional enhancement
- Feature flag from M3/130; default should remain enabled because this is offline and free-tier

## Test plan
**Automated:**
- Unit test: Date parsing logic with various formats ("01/15/2026", "Best By Jan 15 2026", "EXP 15-01-26")
- Unit test: False positive rejection (dates >2 years away, invalid dates)
- [x] Widget test: Camera button appears, shows guidance, and can pre-fill the detected date via mocked OCR service
- [ ] Integration test: Mock ML Kit response → verify date pre-filled

**Manual:**
1. Tap camera button in Add Item form (verify permission prompt on first use)
2. Capture product label with clear expiry date (verify date extracted and pre-filled)
3. Capture label with multiple dates (verify most relevant date selected)
4. Capture label with poor lighting or blur (verify error toast, fallback to manual)
5. Test on device without ML Kit support (verify camera button hidden)
6. Edit extracted date manually (verify edit persists)
7. VoiceOver/TalkBack announces OCR result: "Expiry date detected: January 15, 2026"

## Dependencies
- Issue 145 (onboarding) must include camera permission flow
- Issue 140 (Add Item screen) must be implemented first
