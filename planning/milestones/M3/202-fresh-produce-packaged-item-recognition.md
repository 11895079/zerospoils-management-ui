# 202: Fresh Produce Recognition — Packaged Fish and Meat Scanning

**Epic:** OCR & Scanning  
**Milestone:** M3 (MVP Quality & Shopping)  
**Priority:** P1  
**Size:** M  
**Dependencies:** 195 (package OCR multi-field extraction), 197 (hybrid packaged-item fast add), 196 (live expiry OCR)

---

## Context

Issue 195 (package OCR) handles common packaged goods (boxed, canned, dairy). Issue 197 (hybrid fast add) covers barcode-led identification for shelf-stable packaged items. Neither issue specifically addresses fresh packaged produce — items like fish fillets, chicken thighs, beef cuts, or fresh seafood — that are pre-packaged at a butcher counter or by a store's own packing operation. These packages typically lack a standard UPC barcode, have hand-applied or thermal-printed sticker labels, and mix product name, weight, price-per-kg, total price, and pack date / best-before date on the same sticker in variable formats.

The current scanning flow requires users to type these items manually because OCR models trained for shelf-product text fail to extract the relevant fields reliably from butcher/deli sticker layouts. This issue extends the package recognition pipeline to handle fresh packaged produce without interrupting the main scanning flow — users should experience a seamless handoff from the existing "Scan Package" entry point.

---

## Goal

Extend the on-device package recognition pipeline to correctly identify and extract fields from fresh packaged fish and meat labels (store-applied sticker format), pre-fill the item form with name, weight, price, and best-before date, and route into the existing add-item confirmation flow without adding a separate scanner mode.

---

## Expected behavior

- The existing "Scan Package" entry point and camera panel (M3/195) handles fresh produce sticker labels without requiring a separate button or flow
- When the pipeline detects a store-applied fresh produce label (identified by the presence of weight-per-kg price patterns and absence of a UPC barcode), it activates a specialised fresh-produce extraction mode transparently
- Fresh produce extraction mode extracts: product description (e.g., "Atlantic Salmon Fillet"), net weight (in kg or g), price per kg, total price, pack date, and best-before / use-by date
- The system infers a category from the product description: fish/seafood (salmon, tilapia, shrimp, cod, halibut, tuna, …), meat/poultry (beef, chicken, pork, lamb, turkey, …), or deli/prepared (if not clearly fish or meat)
- After capture, the confirmation screen pre-fills all detected fields; low-confidence fields are flagged for review using the same confidence indicator pattern as M3/195
- If the sticker layout is unrecognised or extraction yields fewer than two fields, the pipeline falls back to generic package OCR (M3/195) and shows the standard partial-extraction message
- The feature does not require network access; all inference is on-device
- Users do not need to indicate that they are scanning a fresh produce item before scanning — the pipeline detects the format automatically
- Works within the existing camera session; no separate scanner screen is opened

---

## Acceptance criteria (Definition of Done)

- [x] Pipeline detects store-applied fresh produce sticker format automatically (weight-per-kg price pattern + no UPC barcode) and activates fresh-produce extraction mode without user input
  - `FreshProduceOcrParser.shouldUseFreshProduceMode()` heuristic: price-per-weight pattern + no barcode
- [x] Fresh-produce extraction extracts: product_description, net_weight (value + unit), price_per_kg, total_price, pack_date, best_before_date from thermal/sticker label layouts
  - All fields extracted in `FreshProduceOcrParser.parseLabel()`; returns `FreshProduceOcrParseResult`
- [x] Category inference maps extracted product description to `fish_seafood`, `meat_poultry`, or `deli_prepared`; falls back to `other` if uncertain
  - `FreshProduceClassification` enum: `fishSeafood, meatPoultry, deliPrepared, other`
- [ ] Confirmation screen pre-fills all detected fresh-produce fields; confidence indicators shown per field (checkmark=high, warning=low)
  - **Not verified**: `PackagedItemFastAddScreen` calls `_freshProduceParser.parseLabel()` and pre-fills fields; per-field confidence indicator UI not confirmed
- [x] If fewer than 2 fields extracted, pipeline falls back to generic package OCR (M3/195) with no additional error shown to user beyond the standard partial-extraction message
  - `FreshProduceOcrParseResult.shouldFallbackToGenericOcr` set when `extractedFieldCount < 2`
- [x] Feature is gated behind the existing `package_ocr` feature flag — no separate flag required
- [x] Fully offline — no network calls during or after extraction
- [ ] Telemetry events: `package_ocr_attempted {tier, label_type: 'fresh_produce'}`, `package_ocr_success {fields_extracted, label_type: 'fresh_produce'}`, `package_ocr_field_edited {field_name}` emitted using the same schema as M3/195
  - **Not verified**: fresh-produce-specific telemetry events not confirmed
- [x] Unit/widget/integration tests added or updated (see test plan)
  - `FreshProduceOcrParser` unit tests present; parser tested for all field types and fallback
- [ ] Accessibility basics: confirmation form fields are labelled; confidence indicators announced for screen reader users
  - **Not verified**

---

## Out of scope

- Loose produce (unpackaged fruits, vegetables) without a sticker label
- Multi-language sticker labels (English/French bilingual stickers are in scope; other languages deferred)
- Cloud-side model training or improved OCR accuracy via server-side processing
- Price history tracking or price-per-unit comparison features
- Expiry date extraction improvements beyond re-using M3/196 live expiry OCR for best-before dates

---

## Implementation notes

**Status as of May 2026 (code audit):**
- `FreshProduceOcrParser` (`fresh_produce_ocr_parser.dart`): fully implemented. `shouldUseFreshProduceMode()` uses price-per-weight heuristic + no-barcode check. `parseLabel()` extracts all 6 fields (productDescription, netWeight, pricePerWeight, totalPrice, packDate, bestBeforeDate). `FreshProduceClassification` enum: `fishSeafood, meatPoultry, deliPrepared, other`. Fallback when `extractedFieldCount < 2`. Unit tests present and passing.
- `PackagedItemFastAddScreen` (`packaged_item_fast_add_screen.dart`): `packageLabelScan` stage exists in `_FastAddStage` enum. `_freshProduceParser.parseLabel()` called on scan result. Classification checked for category routing.
- **Remaining work**: (1) verify per-field confidence indicator UI on the confirmation stage, (2) confirm fresh-produce-specific telemetry events (`label_type: 'fresh_produce'`) are being fired.

- Fresh produce sticker detection heuristic (no network required):
  - Heuristic A (primary trigger): price-per-weight pattern present (e.g., `$X.XX/kg`, `X.XX $/KG`, `$X.XX/LB`) AND no UPC barcode detected in the same frame
  - Heuristic B (confidence booster — used when Heuristic A alone scores below threshold): product description keyword match (fish/meat/seafood/poultry keyword list) AND sticker layout (single-column dense text); Heuristic B increases confidence and helps ranking/review hints, but it does not override the minimum extracted-field threshold and does not independently trigger fresh-produce mode
- Field extraction patterns for sticker format:
  - Product description: largest or topmost text block (before weight/price lines); strip store name prefix if present
  - Net weight: `\d+\.?\d*\s*(KG|G|LB|LBS|OZ)` (case-insensitive)
  - Price per kg: `\$\d+\.\d{2}\s*/\s*(KG|LB|100G)` or equivalent
  - Total price: last price-pattern match near the bottom of the sticker; or field labelled `TOTAL` / `PRICE`
  - Pack date / best-before: `(PACKED ON|PACK DATE|BEST BEFORE|BB|USE BY|BEST BY)\s*[:\-]?\s*\d{1,2}[\/-]\d{1,2}[\/-]\d{2,4}` — re-use M3/196 date parsing logic
- Category keyword lists (maintain in a dedicated JSON configuration file — e.g., `assets/config/fresh_produce_categories.json` — so additions and regional variations can be updated without code changes; for no-release updates, distribute refreshed keyword data through downloadable update packs in M3/206; load at app startup and cache in memory):
  - `fish_seafood`: salmon, halibut, tilapia, cod, tuna, shrimp, lobster, crab, scallop, trout, bass, snapper, mahi, swordfish, squid, clam, oyster, mussel
  - `meat_poultry`: beef, chicken, pork, lamb, turkey, bison, veal, duck, goose, venison, steak, roast, ribs, chop, tenderloin, ground, mince, sausage, bacon, ham
  - `deli_prepared`: prosciutto, salami, pepperoni, pastrami, mortadella, bologna, liverwurst
- Keep fresh-produce parsing logic in a dedicated `FreshProduceOcrParser` class so it is independently testable and does not modify the existing `PackageOcrParser`
- Transition between general and fresh-produce modes is handled inside the existing `PackageOcrService` without routing changes; the camera session stays open throughout

---

## Test plan

**Automated:**
- Unit test: `FreshProduceOcrParser` extracts product_description, net_weight, price_per_kg, total_price, and best_before_date from representative mock sticker text blocks (Atlantic salmon, chicken thighs, beef sirloin)
- Unit test: detection heuristic triggers fresh-produce mode when price-per-kg pattern is present and no barcode detected; does NOT trigger for shelf-product labels
- Unit test: category inference maps "Atlantic Salmon Fillet" → `fish_seafood`, "Lean Ground Beef" → `meat_poultry`, "Black Forest Ham" → `deli_prepared`, "Mystery Item" → `other`
- Unit test: bilingual label (English + French) extracts fields from the English portion correctly
- Unit test: fewer than 2 fields extracted triggers fallback to `PackageOcrParser` (generic mode)
- Widget test: confirmation screen shows fresh-produce fields (weight, price/kg, pack date, best-before) pre-filled; high-confidence fields have checkmarks; low-confidence fields show warning icons
- Widget test: `package_ocr` feature flag disabled hides the "Scan Package" entry point entirely (unchanged from M3/195 tests)
- Integration test: end-to-end mock camera capture of a sticker label produces a saved Item with correct category, weight, and best-before date

**Manual:**
1. Open add-item; tap "Scan Package"; point at a store-packaged chicken tray label; verify fresh-produce mode activates (no extra step required) and pre-fills product description, weight, price/kg, and best-before date
2. Scan a packaged salmon fillet; verify category = fish/seafood; verify best-before date extracted correctly
3. Scan a shelf-stable boxed cereal with UPC barcode; verify fresh-produce mode does NOT activate; normal package OCR runs
4. Scan a bilingual (EN/FR) pork chop label; verify English fields extracted; French redundant fields ignored
5. Scan a poorly printed or blurry sticker; verify fallback to generic OCR with partial extraction message (no crash)
6. Disable `package_ocr` feature flag; verify "Scan Package" button hidden; fresh-produce path inaccessible
7. Complete fresh-produce scan offline (airplane mode); verify no network requests made; item saves successfully
8. Screen reader: open confirmation form; verify weight, price/kg, pack date, and best-before fields are announced with labels

---

## Dependencies

- M3/195 package OCR multi-field extraction (`PackageOcrService`, `PackageOcrParser`, camera panel, confirmation screen)
- M3/197 hybrid packaged-item fast add (barcode detection to distinguish fresh produce from shelf products)
- M3/196 live expiry OCR (date parsing logic for best-before extraction)
- M3/130 feature flags framework (`package_ocr` flag)
