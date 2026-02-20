## Context
Manual date entry is tedious and error-prone. On-device OCR for expiry dates reduces friction and improves data quality.

## Goal
Enable users (Pro tier) to scan product labels with device camera and auto-extract expiry dates using Google ML Kit (offline, privacy-first). Free tier keeps manual entry and basic photos only.

## Expected behavior
- Camera icon button next to expiry date field in Add Item form
- Tap button → open camera view → capture product label
- ML Kit Text Recognition extracts text → parse for date patterns
- Pre-fill expiry date field with extracted date (user can edit if incorrect)
- Graceful fallback to manual entry if OCR fails or unavailable

## Acceptance criteria (Definition of Done)
- [ ] Pro gating: OCR only runs for Pro users with feature flag `expiry_date_ocr` enabled
- [ ] Free tier: camera/OCR controls hidden; manual entry remains
- [ ] Camera permission requested on first tap; denial shows guidance and allows retry
- [ ] Camera button appears next to expiry date field when Pro + flag enabled
- [ ] Camera capture UI with focus guidance ("Point camera at expiry date")
- [ ] Date parsing supports formats: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, and labels ("Best By", "Use By", "Exp")
- [ ] Extracted date pre-fills expiry field and remains editable
- [ ] OCR failure shows toast and returns to manual entry
- [ ] ML Kit unavailable → camera button hidden (no crash)
- [ ] Telemetry event `expiry_date_scanned` emitted with properties { success, format_detected }
- [ ] Offline-first verified (no network required)
- [ ] Accessibility basics (camera button labeled; OCR result announced)

- [ ] Google ML Kit Text Recognition integrated (iOS + Android) and gated by Pro
- [ ] Unit/widget/integration tests added or updated

## Out of scope
- Full receipt OCR (deferred to M6 Pro tier)
- Barcode scanning for product lookup
- Cloud-based OCR (Google Vision API)
- Multi-item batch scanning

## Implementation notes
- Use Google ML Kit Text Recognition v2 (on-device, free); gate behind Pro entitlement + feature flag
- iOS: `GoogleMLKit/TextRecognition` pod
- Android: `com.google.mlkit:text-recognition` Maven
- Date parsing regex: capture common patterns, prioritize dates within next 2 years (avoid false positives)
- Camera UI: Show crosshair/focus box overlay
- Permission handling: Request camera on first tap; graceful denial handling
- Keep manual entry as primary method; OCR is optional enhancement
- Feature flag from M3/130; entitlement check from Pro subscription (M6/410/420)

## Test plan
**Automated:**
- Unit test: Date parsing logic with various formats ("01/15/2026", "Best By Jan 15 2026", "EXP 15-01-26")
- Unit test: False positive rejection (dates >2 years away, invalid dates)
- Widget test: Camera button appears and is tappable
- Integration test: Mock ML Kit response → verify date pre-filled

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
