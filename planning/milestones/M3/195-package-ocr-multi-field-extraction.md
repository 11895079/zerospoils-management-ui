## Context
Current M2/142 OCR is limited to expiry date extraction only. Users want to point phone at food package and extract all relevant information: product name, category, weight/quantity, cost, expiry date, batch/lot code. This reduces manual entry friction and improves data accuracy for packaged goods.

## Goal
Deliver full package OCR feature that extracts multiple fields from product packaging using on-device ML, with confirmation/edit flow and Pro tier gating.

## Expected behavior
- Add-item screen shows "Scan Package" button (camera icon); tap opens camera viewfinder with OCR overlay
- Point camera at food package; on-device ML detects and extracts: product name, category (inferred), weight/quantity + unit, price, expiry date, batch/lot code
- After capture, show confirmation screen with extracted fields pre-filled in add-item form; user reviews/edits before saving
- OCR confidence indicators: high-confidence fields auto-filled; low-confidence fields flagged with warning icon for manual review
- Works offline (on-device ML); no cloud API calls required for MVP
- Gated to Pro tier; free tier users see upgrade prompt when tapping "Scan Package"
- Supports common package types: boxed goods, canned items, dairy labels, meat/poultry labels, frozen packages
- Telemetry: `package_ocr_attempted`, `package_ocr_success`, `package_ocr_field_edited` events with field-level accuracy tracking
- Offline-first: all ML inference local; no network dependency

## Acceptance criteria (Definition of Done)
- [ ] Add "Scan Package" button to add-item screen (camera icon + label); Pro tier only (show upgrade prompt for free users)
- [ ] Camera viewfinder with OCR overlay: guide user to center package text; real-time text detection feedback
- [ ] On-device ML model extracts: product_name, category_hint, quantity+unit, price, expiry_date, batch_code from captured image
- [ ] Confirmation screen: pre-fill add-item form with extracted fields; show confidence indicators (checkmark=high, warning=low)
- [ ] Category inference: map detected product text to built-in category (e.g., "milk" → dairy); fallback to "other" if uncertain
- [ ] User can edit any extracted field before saving; track which fields edited in telemetry
- [ ] OCR engine: use ML Kit Text Recognition v2 (Android) and Vision framework (iOS); on-device models only
- [ ] Support common date formats: MM/DD/YYYY, DD/MM/YYYY, YYYY-MM-DD, "Best By MM/DD", "Exp: MM/DD"
- [ ] Handle partial extraction gracefully: if only 2/6 fields detected, pre-fill those and leave others blank for manual entry
- [ ] Telemetry events: `package_ocr_attempted {tier}`, `package_ocr_success {fields_extracted, confidence_scores}`, `package_ocr_field_edited {field_name, was_correct}`
- [ ] Unit/widget/integration tests added or updated (ML inference mocking, confirmation flow, field validation)
- [ ] Telemetry added/updated (event names + key properties documented)
- [ ] Offline-first behavior verified (no network dependency; on-device inference only)
- [ ] Accessibility basics (camera viewfinder guidance voiceover, confirmation form labels, confidence indicators announced)

## Out of scope
- Cloud-based OCR API (Azure/Google Vision) for higher accuracy (defer to M6)
- Multi-language support (English only for MVP)
- Barcode scanning integration (separate M6 feature)
- Receipt OCR for line items (handled by M3/190 batch feature)
- Real-time continuous OCR (single capture only; no video stream processing)
- OCR model training/customization (use pre-trained ML Kit/Vision models)

## Implementation notes
- Use ML Kit Text Recognition V2 (Android) and Vision Text Recognition (iOS) for on-device inference
- OCR extraction pipeline: detect text blocks → classify by position/format → extract fields:
  - Product name: largest text block at top of image (heuristic)
  - Quantity/unit: regex match patterns like "1.5 LB", "500 ML", "12 oz"
  - Price: regex match $X.XX or X.XX (near bottom/right edge)
  - Expiry date: keywords "EXP", "BEST BY", "USE BY" + date pattern
  - Batch code: keywords "LOT", "BATCH" + alphanumeric string
  - Category: keyword matching (e.g., "MILK" → dairy, "CHICKEN" → meat_poultry)
- Confidence scoring: ML Kit returns per-word confidence; compute field-level average; threshold high ≥ 0.8, low < 0.6
- Confirmation screen: use read-only text fields for high-confidence; editable fields with warning icon for low-confidence
- Pro tier check: query feature flag or subscription status; show upgrade dialog with "Unlock OCR" CTA for free users
- Telemetry: emit `package_ocr_attempted` on camera open; `package_ocr_success` on confirmation save; include array of extracted fields and confidence scores
- Fallback: if OCR extracts nothing, show empty form with message "No text detected. Please enter manually."

## Test plan
**Automated:**
- Widget test: "Scan Package" button visible for Pro users; tapping opens camera viewfinder
- Widget test: free tier users tap "Scan Package"; verify upgrade prompt shown
- Unit test: OCR extraction logic with mock text blocks; verify correct field mapping (name, category, quantity, expiry, batch)
- Unit test: date parsing supports MM/DD/YYYY, DD/MM/YYYY, "Best By MM/DD" formats
- Unit test: quantity parsing extracts "1.5 LB" → quantity=1.5, unit=lbs; "500 ML" → quantity=500, unit=ml
- Widget test: confirmation screen pre-fills fields with extracted data; confidence indicators shown
- Widget test: user edits low-confidence field; telemetry event `package_ocr_field_edited` fired
- Integration test: end-to-end OCR flow (mock camera → extraction → confirmation → save item)

**Manual:**
1. (Pro user) Open add-item; tap "Scan Package"; verify camera opens with OCR overlay guide
2. Point camera at milk carton; capture image; verify extracted fields: name="Whole Milk", category=dairy, quantity=1, unit=gallon, expiry=MM/DD
3. Review confirmation screen; verify high-confidence fields have checkmark; low-confidence have warning
4. Edit product name from "Whole Milk" to "Organic Milk"; save item; verify telemetry tracks edit
5. Test with various packages: cereal box, canned soup, meat label, frozen pizza; verify extraction quality
6. Test with poor lighting/blurry image; verify graceful fallback (partial extraction or empty fields)
7. (Free user) Tap "Scan Package"; verify upgrade prompt with "Unlock OCR" CTA; dismiss and use manual entry
8. Test date formats: "Best By 12/31/2025", "EXP: 01/15/26", "Use By 2026-02-10"; verify all parsed correctly
9. Screen reader: verify camera guidance voiceover, confirmation form announces confidence levels

## Dependencies
- M2/142 expiry date OCR foundation (ML Kit/Vision setup)
- M1/080 data model (Item fields: name, category, quantity/unit, cost, expiry, batch_code)
- M2/140 add-item screen (integrate "Scan Package" button and confirmation flow)
- Pro tier feature flag system (subscription check for gating)
