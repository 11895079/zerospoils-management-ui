# 201: Receipt Line Item Extraction with AR Overlay

**Epic:** OCR & Scanning  
**Milestone:** M3 (MVP Quality & Shopping)  
**Priority:** P1  
**Size:** L  
**Dependencies:** 198 (shopping batch receipt capture), 195 (package OCR multi-field extraction), 360 (Firebase integration)

---

## Context

Issue 198 (shopping batch receipt capture) stores receipt photos and supports on-device text recognition for candidate line items. However, the raw OCR output mixes genuine purchased items with non-product lines such as HST/GST totals, subtotals, card numbers, cashier IDs, and store-header text. Users end up reviewing a noisy list that requires manual cleanup before any items can be saved. In addition, the current camera overlay obscures the live preview with text guidance rendered on top of the viewfinder, making it difficult to frame the receipt correctly before capture.

This issue delivers two tightly coupled improvements: a post-capture line-item classification pipeline that discards non-item lines automatically, and a live augmented-reality (AR) bounding-box overlay that draws coloured rectangles around recognised purchase lines while the receipt is still in view — so users can confirm coverage before they commit to a capture.

---

## Goal

Deliver receipt line-item extraction with automatic exclusion of tax, total, and card-related lines, paired with a live AR bounding-box overlay in the camera viewfinder that highlights detected purchase items in real time and moves all instructional/status text to a dedicated panel outside the camera view so the full receipt is always visible.

---

## Expected behavior

- When the receipt camera is open, the live viewfinder shows coloured bounding boxes drawn directly on the detected receipt text regions; boxes use distinct colours to indicate: confirmed purchase item (green), ambiguous/review (amber), excluded line (dim/grey); each box is also labelled with a short semantic tag ("Item", "Review", "Excluded") visible to screen readers and in non-colour rendering so that colour is never the sole means of conveying status
- Instructional copy, capture progress, and status messages appear in a dedicated text panel **below** the camera view rather than overlaid on the viewfinder; the camera surface itself is kept clean except for the AR bounding boxes
- Auto-capture (when enabled) fires only after the system detects a minimum number of confirmed purchase-item lines and the bounding boxes have been stable for a short confidence window
- After capture, the classification pipeline processes the extracted text blocks:
  - **Kept as purchase items**: lines with a product name and price-like token, ranked by on-screen position
  - **Filtered — payment / card lines**: lines containing card-number fragments (masked or partial), payment method labels (VISA, MASTERCARD, INTERAC, DEBIT, CREDIT), and transaction approval codes
  - **Filtered — store header / footer noise**: store name, address, phone, website, loyalty-program headers, cashier or terminal IDs, and date-time stamps
  - **Extracted as receipt summary values** (dollar amount parsed and stored, line not shown in purchase item list):
    - Tax lines (HST, GST, PST, QST and variants) → `receipt_tax_amount`
    - Subtotal / total / balance lines → `receipt_total_amount`
    - Price reduction / savings lines ("MEMBER SAVINGS", "YOU SAVED", "SAVINGS", loyalty discounts) → `receipt_savings_amount`; negative amounts are stored as positive savings values
- The review screen shows a collapsible receipt summary footer beneath the item list with: Subtotal (inferred = total − tax), Tax amount, Savings / price reductions applied, Total amount paid; values are shown only when extracted with reasonable confidence; individual fields are omitted if not found
- Confirmed purchase item lines are ranked by their on-screen position (top-to-bottom, left-to-right) and presented to the user in the review step in reading order
- Users can still promote an excluded line back to a purchase item and demote a purchase item to excluded in the review step
- The classification pipeline runs fully on-device without any network dependency
- The feature is gated behind the existing `batch_photo_capture` feature flag and is off by default on web (web shows "not available on web yet" in the batch capture flow)
- Telemetry captures the number of lines detected, lines kept, lines excluded, and any manual user overrides in the review step

---

## Acceptance criteria (Definition of Done)

- [x] Live camera viewfinder renders AR bounding boxes on detected text regions with green (item), amber (review), and grey (excluded) colour coding
- [x] All instructional and status text in the receipt capture flow appears in a panel below the camera surface, not overlaid on the viewfinder
  - `ReceiptLiveScanScreen` text panel is outside the camera viewport
- [x] Classification pipeline extracts tax amount (dollar value) from HST/GST/PST/QST lines and stores in `ReceiptParseResult.taxAmount`; tax lines are not shown in the purchase item list
- [x] Classification pipeline extracts total/subtotal amount from matching lines and stores in `ReceiptParseResult.totalAmount`; these lines are not shown in the purchase item list
- [x] Classification pipeline extracts savings/price-reduction amount (MEMBER SAVINGS, YOU SAVED, loyalty discounts, negative-value lines) and stores in `ReceiptParseResult.savingsAmount`; savings lines are not shown in the purchase item list
- [x] Classification pipeline excludes payment/card lines (card fragments, VISA/MASTERCARD/INTERAC/DEBIT/CREDIT labels, approval codes) from the review list
  - `ReceiptRowClassification.payment` handled in `_classifyRow()`
- [x] Classification pipeline excludes store header/footer noise (address, phone, cashier ID, terminal ID, loyalty headers, timestamps) from the review list
  - `ReceiptRowClassification.storeInfo`, `.department`, `.loyalty` handled; exclusion patterns applied
- [x] Review screen shows only confirmed purchase items in receipt reading order; excluded lines visible in a collapsed "hidden lines" section with reason labels
- [x] Review screen shows a collapsible receipt summary footer with extracted Savings, Tax, and Total amounts; fields omitted when not found with sufficient confidence
- [x] User can promote any excluded line to a purchase item and demote any purchase item to excluded in the review step
- [x] Classification pipeline is fully on-device; no network dependency
- [x] Web platform shows "not available on web yet" and skips the AR overlay
- [x] Telemetry events: `receipt_scan_lines_detected {total, kept, excluded, user_promoted, user_demoted}` emitted on review confirm
- [x] Unit/widget/integration tests added or updated (see test plan)
- [x] Offline-first behavior verified (no network dependency)
  - `offline_first_verification_test.dart` covers receipt parser (pure Dart)
- [x] Accessibility basics: bounding-box colour coding supplemented with labelled semantics; text panel readable by screen reader; review list announces item count and excluded count

---

## Out of scope

- Cloud OCR or server-side receipt parsing (Pro tier scope, deferred)
- Price and quantity extraction from line items (tracked separately in M3/195 package OCR)
- Multi-currency or multi-language receipt support (English/CAD only for MVP)
- Loyalty-card point extraction
- Receipt de-duplication across batches
- Receipt sharing or export as PDF

---

## Implementation notes

**Status as of June 2026 (reconciled with code):**
- `ReceiptLiveScanScreen` renders tri-color AR boxes with classification-aware tones and semantics labels for item/review/excluded statuses.
- `ReceiptParser` extracts `subtotalAmount`, `taxAmount`, `totalAmount`, and `savingsAmount` from classified lines and returns them in `ReceiptParseResult`.
- `ReceiptBatchReviewScreen` ships hidden-lines promote/demote interactions, telemetry counters (`user_promoted`, `user_demoted`), and a receipt summary footer.
- Accessibility coverage includes non-color semantic labels on overlay rows and review count announcements (included vs hidden lines).

- AR overlay: use the camera preview stream already established in M3/196 (live expiry OCR); throttle bounding-box refresh to ~10 fps — this rate is sufficient for smooth visual feedback (human perception threshold ~8–12 fps for positional updates) while avoiding GPU overdraw on mid-range Android devices; validate with a widget performance test that the overlay does not drop the camera preview below 30 fps on a reference device; draw rectangles using a `CustomPainter` layered on top of the camera preview widget; pair each coloured rectangle with an accessibility label (`Semantics` widget) so screen readers and colour-blind users receive status information through text, not only colour
- Move all text overlays (guidance copy, capture count, auto-capture toggle, status messages) into a `Column` widget placed below the camera widget rather than using a `Stack` with overlaid children; this frees the camera surface for AR content only
- Classification pipeline order of operations:
  1. Split recognised text into lines preserving bounding-box coordinates
  2. Apply exclusion rules in priority order: card/payment → tax → total/subtotal → header/footer → remainder kept as candidate items
  3. Score each candidate with a simple keyword + position heuristic (price-pattern match boosts confidence; no price-pattern and short token count lowers it)
  4. Return a `ReceiptLine` list with `status` enum: `kept | excluded_tax | excluded_total | excluded_card | excluded_noise | review`
- Exclusion patterns (regex, case-insensitive):
  - Tax: `\b(HST|GST|PST|QST|TAX|TAXE)\b`
  - Total: `\b(SUBTOTAL|SUB-TOTAL|TOTAL|BALANCE DUE|AMOUNT DUE|GRAND TOTAL)\b`
  - Card: `\b(VISA|MASTERCARD|MASTER CARD|INTERAC|DEBIT|CREDIT|AMEX|DISCOVER)\b` or masked card patterns `[\*Xx]{4,}[\s\-]?\d{4}`
  - Approval code: `\b(APPROVAL|AUTH|REFERENCE)\b`
  - Header/footer noise: lines with no price-like token and containing `\b(TEL|PHONE|WWW|HTTP|@|CASHIER|TERMINAL|STORE#|LOYALTY|POINTS|THANK YOU)\b`
- Amount extraction from classified lines: use a regex `\$?\d{1,4}[.,]\d{2}` to find the rightmost price-like token on a tax/total/savings line; for savings lines a leading `-` or negative amount should be stored as a positive savings value; store extracted amounts in `ReceiptParseResult` fields: `taxAmount`, `totalAmount`, `savingsAmount` (all `double?`, null when not found or low confidence)
- Costco-specific patterns to handle: `MEMBER SAVINGS`, `KIRKLAND SIGNATURE` prefix on item lines, membership fee lines (exclude as noise), bulk-pack pricing with `/`, Canadian tax label `HST` without a `%` sign, `E` suffix on price (indicates tax-exempt item — keep as item)
- Store the `ReceiptLine` list (with statuses) in `ShoppingBatch.receipt_lines` so the review step can re-render without re-running OCR
- Keep bounding-box coordinates in normalised device-independent units so the overlay scales correctly across screen sizes and orientations

---

## Test plan

**Automated:**
- Unit test: classification pipeline correctly marks HST/GST/PST lines as `excluded_tax` AND extracts the dollar amount into `taxAmount`; verified with sample Costco receipt text blocks
- Unit test: savings lines ("MEMBER SAVINGS -$5.00", "YOU SAVED $3.00") are classified as `savings`, not shown in item list, and `savingsAmount` is populated with positive dollar value
- Unit test: total line extracts dollar amount into `totalAmount`
- Unit test: classification pipeline correctly marks TOTAL / SUBTOTAL / BALANCE DUE lines as `excluded_total`
- Unit test: classification pipeline correctly marks VISA, INTERAC, and masked card number lines as `excluded_card`
- Unit test: classification pipeline correctly marks store phone/address/cashier lines as `excluded_noise`
- Unit test: purchase item lines with price tokens pass through with `kept` status and preserve receipt reading order
- Unit test: user promotion moves an `excluded_tax` line to `kept` status; user demotion moves a `kept` line to `excluded_noise`
- Widget test: camera surface contains zero text overlay children when AR overlay is enabled; guidance text panel is rendered below the camera widget
- Widget test: review screen shows purchase items count and a collapsed "hidden lines" section with correct excluded line count
- Widget test: tapping a hidden line promotes it and increments the purchase items count
- Integration test: end-to-end flow with mocked OCR output (20 lines: 10 items, 1 savings, 1 tax, 2 total, 2 card, 3 noise) produces exactly 10 items in the review list, with `savingsAmount`, `taxAmount`, and `totalAmount` populated in `ReceiptParseResult`

**Manual:**
1. Open batch receipt capture; verify the camera viewfinder is clean (no text overlaid); verify guidance and progress appear in the panel below the camera
2. Point camera at a real grocery receipt; verify green bounding boxes appear around purchased items in real time; verify tax/total lines show grey boxes
3. Auto-capture a receipt; open review screen; verify HST/GST lines, TOTAL, and card lines are not present in the main item list
4. Open the "hidden lines" section; verify excluded lines are listed with reason labels (Tax, Total, Savings, Payment, Noise)
5. Verify the receipt summary footer shows Tax, Savings, and Total amounts extracted from the receipt
6. Promote an HST line to a purchase item; verify it moves into the main list and the Tax amount in the summary footer updates
6. Demote a purchase item to excluded; verify it moves to the hidden section
7. Deny camera permission; verify graceful fallback and manual entry remains available
8. Web platform: verify "not available on web" message shown; AR overlay and receipt capture hidden
9. Screen reader: verify camera guidance panel is announced; verify item count and excluded count are announced in review screen

---

## Dependencies

- M3/198 shopping batch receipt capture (receipt photo capture flow and `ShoppingBatch` entity)
- M3/195 package OCR multi-field extraction (on-device ML Kit / Vision text recognition setup)
- M3/196 live expiry OCR (live camera preview stream with bounding-box drawing patterns)
- M3/130 feature flags framework (`batch_photo_capture` flag)
