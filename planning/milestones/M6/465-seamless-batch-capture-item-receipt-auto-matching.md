# 465: Seamless Batch Capture — Item + Receipt Auto-Matching (Signature Feature)

**Epic:** Pro Tier — Computer Vision + Intelligent Automation  
**Milestone:** M6 (Pro Tier Features)  
**Priority:** P0 (Signature Differentiator)  
**Size:** L  
**Dependencies:** 430 (batch item detection), 440 (OCR spike), 450 (receipt parsing), 460 (receipt review UI)

---

## Context

**Problem:** Manual inventory entry is high-friction. Users spend 5–10 minutes after grocery shopping entering items one by one, making the app feel like a chore.

**Existing Workarounds:**
- 430: Batch item detection (photo of items → detect names)
- 440/450: Receipt OCR (photo of receipt → extract line items + prices)

**Gap:** These are **separate workflows**. User must:
1. Photo items → detect → review
2. Photo receipt → OCR → review
3. Manually match items to prices (cognitive overhead)

**Vision:** **Single photo of items + receipt → automatic matching → bulk confirm** (30 seconds total).

This is the **"wow" feature** that makes users never want to go back to manual entry. It's the reason to upgrade to Pro.

---

## Goal

Deliver a unified batch capture experience that:
1. Detects items from photo (computer vision)
2. Extracts receipt text (OCR)
3. **Automatically matches items to receipt line items** using fuzzy name matching + spatial proximity + confidence scoring
4. Presents unified review UI with items + matched prices
5. Bulk confirms → all items added to inventory with cost tracking

---

## Expected behavior

### 1. Unified Capture Mode

**Entry Point:** Inventory screen → "Batch Add (PRO)" button

**Capture Flow:**
```
┌─────────────────────────────────┐
│   Camera View (Batch Mode)      │
├─────────────────────────────────┤
│                                 │
│  [ Live camera preview ]        │
│                                 │
│  💡 Tip: Place items + receipt  │
│     on flat surface, capture    │
│     both in one photo.          │
│                                 │
│  [📷 Capture]  [Cancel]         │
└─────────────────────────────────┘
```

**Capture Options:**
- **Option A (Recommended):** Single photo with both items + receipt visible
- **Option B:** Photo items first, then photo receipt (system links by session)
- **Option C:** Import existing photo from gallery

**Processing Flow:**
1. User taps "Capture" → photo saved locally
2. System shows loading spinner: "Detecting items and scanning receipt..."
3. Runs parallel processing:
   - **Computer vision pipeline:** Detect item bounding boxes + labels
   - **OCR pipeline:** Extract receipt text → parse line items
4. Runs **smart matching algorithm** (see below)
5. Displays unified review UI

---

### 2. Smart Matching Algorithm

**Goal:** Pair detected items with receipt line items using multi-factor scoring.

**Inputs:**
- Detected items: `[{name: "Milk", bbox: [x,y,w,h], confidence: 0.89}, ...]`
- Receipt line items: `[{name: "2% MILK 1L", price: 4.99, quantity: 1}, ...]`

**Matching Factors:**

1. **Name Similarity (70% weight):**
   - Fuzzy string matching (Levenshtein distance, case-insensitive)
   - Synonym mapping ("Milk" → "2% Milk", "Bread" → "Whole Wheat Bread")
   - Token overlap ("Organic Eggs" matches "EGGS ORG 12CT")
   - Score: 0.0 (no match) to 1.0 (exact match)

2. **Spatial Proximity (20% weight):**
   - If receipt visible in photo, calculate distance between item bbox center and receipt line position
   - Items near top of receipt should match top receipt lines
   - Score: 1.0 (same region) to 0.0 (opposite sides)

3. **Confidence Score (10% weight):**
   - Higher item detection confidence → more reliable match
   - Higher receipt OCR confidence → more reliable match
   - Score: Average of item confidence + receipt line confidence

**Combined Match Score:**
```
match_score = (0.7 × name_similarity) + (0.2 × spatial_proximity) + (0.1 × avg_confidence)
```

**Matching Rules:**
- **Auto-match threshold:** ≥0.80 score (high confidence)
- **Suggest match:** 0.60–0.79 score (user confirms)
- **No match:** <0.60 score (user manually selects or skips)
- **1:1 constraint:** Each item matches at most one receipt line
- **Greedy algorithm:** Match highest-scoring pairs first, then descend

**Example:**

| Detected Item | Receipt Line Item | Name Sim | Spatial | Confidence | **Total** | **Action** |
|---------------|-------------------|----------|---------|------------|-----------|------------|
| Milk (0.89)   | 2% MILK 1L $4.99  | 0.92     | 0.85    | 0.885      | **0.89**  | ✅ Auto-match |
| Eggs (0.87)   | EGGS 12CT $5.49   | 0.95     | 0.80    | 0.880      | **0.88**  | ✅ Auto-match |
| Bread (0.72)  | WHT BREAD $3.99   | 0.78     | 0.75    | 0.735      | **0.76**  | ⚠️ Suggest (user confirms) |
| Yogurt (0.65) | (no match)        | 0.35     | 0.00    | 0.325      | **0.25**  | ❌ No match (manual) |

---

### 3. Unified Review UI

**Review Screen Layout:**

```
┌─────────────────────────────────────────┐
│  Batch Capture Review                   │
├─────────────────────────────────────────┤
│                                         │
│  Auto-Matched (3 items)                 │
│  ┌─────────────────────────────────┐   │
│  │ ✅ Milk (2% 1L)       $4.99  ✓  │   │
│  │    Qty: 1  Category: Dairy      │   │
│  │    Expiry: [Add date]  [Edit]   │   │
│  ├─────────────────────────────────┤   │
│  │ ✅ Eggs (Dozen)       $5.49  ✓  │   │
│  │    Qty: 1  Category: Dairy      │   │
│  │    Expiry: [Add date]  [Edit]   │   │
│  ├─────────────────────────────────┤   │
│  │ ⚠️ Bread (Whole Wheat) $3.99  ? │   │
│  │    Qty: 1  Category: Grains     │   │
│  │    Expiry: [Add date]  [Edit]   │   │
│  │    [Confirm Match]              │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Needs Review (1 item)                  │
│  ┌─────────────────────────────────┐   │
│  │ ❓ Yogurt             [No price] │   │
│  │    Match to receipt line:       │   │
│  │    ▼ [Select or Skip]           │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [Select All] [Add 4 Items] [Cancel]   │
└─────────────────────────────────────────┘
```

**Key Features:**

1. **Visual Confidence Indicators:**
   - ✅ Green checkmark: Auto-matched (≥80% confidence)
   - ⚠️ Yellow warning: Suggested match (60–79%, needs confirmation)
   - ❓ Gray question: No match (<60%, manual selection)

2. **Item Cards:**
   - Item name (editable)
   - Matched price (if available)
   - Quantity (default 1, editable)
   - Category (auto-suggested, editable)
   - Expiry date (optional, picker)
   - [Edit] button → opens full item editor

3. **Match Actions:**
   - **Auto-matched items:** "✓" badge, tap to edit details
   - **Suggested matches:** "Confirm Match" button (tap to accept)
   - **No match items:** Dropdown to manually select receipt line or "Skip"

4. **Bulk Actions:**
   - [Select All] → check/uncheck all items
   - [Add X Items] → bulk confirm and add to inventory
   - [Cancel] → discard capture session

5. **Receipt Reference:**
   - "View Receipt" button → opens modal with full receipt image + OCR text
   - Highlight matched lines in receipt (colored overlay)

---

### 4. Post-Confirmation

**After user taps "Add X Items":**

1. Create inventory items with:
   - Name, quantity, category, location (default "Fridge")
   - **Cost tracking:** `purchase_price`, `purchase_date` (today)
   - Expiry date (if set by user)
   - Source metadata: `added_via: "batch_capture_auto_match"`

2. Store receipt metadata:
   - Receipt image (retained for 30 days, then auto-deleted)
   - OCR text + parsed line items
   - Match confidence scores (for analytics)

3. Show success toast: "✅ 4 items added to inventory (saved ~5 minutes!)"

4. Navigate back to Inventory screen with new items highlighted

5. Emit telemetry (see below)

---

## Acceptance criteria (Definition of Done)

### Core Functionality

- [ ] **Unified capture mode:** Single photo captures both items + receipt
- [ ] **Parallel processing:** CV + OCR run simultaneously (2-5 sec total latency)
- [ ] **Smart matching algorithm:** Combines name similarity + spatial proximity + confidence
- [ ] **Match score computation:** Scores 0.0–1.0 for each item-receipt pair
- [ ] **Auto-match threshold:** ≥0.80 score auto-matched, 0.60–0.79 suggested, <0.60 manual
- [ ] **1:1 constraint:** Each item matches at most one receipt line (greedy algorithm)
- [ ] **Unified review UI:** Single screen shows all items with match status + prices

### UI/UX

- [ ] **Capture screen:** Camera view with instructional overlay ("Place items + receipt on table")
- [ ] **Processing indicator:** Loading spinner with progress message ("Detecting items... 50%")
- [ ] **Review screen:** Three sections: Auto-Matched, Suggested Matches, Needs Review
- [ ] **Visual confidence indicators:** ✅ (auto), ⚠️ (suggest), ❓ (manual)
- [ ] **Inline editing:** Tap item card to edit name, qty, category, expiry without leaving review
- [ ] **Receipt reference modal:** View full receipt image with matched lines highlighted
- [ ] **Bulk confirm:** "Add X Items" button with count badge
- [ ] **Empty states:**
   - No items detected: "No items found. Try retaking photo."
   - No receipt detected: "Receipt not found. Prices won't be matched."
   - No matches: "Unable to auto-match. Review items manually."

### Matching Intelligence

- [ ] **Fuzzy name matching:** Levenshtein distance + token overlap (case-insensitive)
- [ ] **Synonym mapping:** Common food synonyms ("Milk" ≈ "2% Milk", "Eggs" ≈ "Dozen Eggs")
- [ ] **Spatial proximity scoring:** Calculate bbox-to-receipt-line distance if receipt visible
- [ ] **Confidence weighting:** Factor in CV confidence + OCR confidence
- [ ] **Fallback gracefully:** If matching fails, degrade to manual review (don't block workflow)

### Data Persistence

- [ ] **Receipt storage:** Encrypt and store receipt image locally for 30 days, then auto-delete
- [ ] **Match metadata:** Store match scores for analytics (`item_id`, `receipt_line_id`, `match_score`)
- [ ] **Cost tracking:** Inventory items include `purchase_price`, `purchase_date`, `source: "batch_capture"`
- [ ] **Undo/redo:** User can delete batch-added items from Inventory with "Undo Batch" action (24-hour window)

### Privacy & Security

- [ ] **Consent flow:** Show disclosure on first use: "Camera and OCR process images locally. Receipt images deleted after 30 days."
- [ ] **Settings toggle:** "Store Receipt Images" (default ON, user can disable)
- [ ] **Local processing:** CV and OCR run on-device or via cloud API with encrypted transmission
- [ ] **Data deletion compliance:** User can manually delete receipt images via Settings → Privacy → Delete Receipt History

### Telemetry

- [ ] `batch_capture_started` event:
  - Properties: `capture_mode` (single_photo / multi_photo), `user_tier` (pro)

- [ ] `batch_capture_processed` event:
  - Properties: `items_detected`, `receipt_lines_parsed`, `processing_time_sec`, `cv_confidence_avg`, `ocr_confidence_avg`

- [ ] `batch_capture_matched` event:
  - Properties: `auto_matched_count`, `suggested_matched_count`, `no_match_count`, `match_algorithm_version`

- [ ] `batch_capture_review_action` event:
  - Properties: `action` (confirm / edit / skip), `item_name`, `match_score`, `user_edited_price`

- [ ] `batch_capture_confirmed` event:
  - Properties: `items_added_count`, `total_value_usd`, `time_saved_sec` (estimated vs manual entry)

- [ ] `batch_capture_failed` event:
  - Properties: `failure_reason` (no_items_detected / no_receipt_detected / ocr_failed / cv_failed)

### Performance

- [ ] **Latency:** Total processing time ≤5 sec for typical capture (3–5 items, single receipt)
- [ ] **Accuracy targets:**
  - Item detection: ≥85% precision (labeled test set of 100 images)
  - Receipt OCR: ≥90% line item extraction accuracy (50 test receipts)
  - Matching: ≥80% auto-match rate (items correctly paired with receipt lines)
- [ ] **Optimization:** Use on-device ML models (TensorFlow Lite) for CV if available; fallback to cloud API

### Testing

**Automated Tests (Unit):**

- Test matching algorithm:
  - High similarity ("Milk" → "2% MILK 1L"): score ≥0.80 ✓
  - Moderate similarity ("Bread" → "WHT BREAD"): score 0.60–0.79 ✓
  - Low similarity ("Yogurt" → "EGGS"): score <0.60 ✓

- Test spatial proximity:
  - Item near top of photo + receipt line near top: high proximity score ✓
  - Item bottom + receipt line top: low proximity score ✓

- Test greedy matching:
  - 3 items, 5 receipt lines → highest-scoring pairs matched first ✓
  - No duplicate matches (1:1 constraint enforced) ✓

- Test edge cases:
  - No items detected → gracefully show empty state ✓
  - No receipt detected → items shown with "[No price]" ✓
  - Receipt OCR fails → items detected but no matching attempted ✓

**Widget Tests (UI):**

- Render review screen with 3 auto-matched items, 1 suggested match, 1 no-match
- Verify visual indicators (✅, ⚠️, ❓) render correctly
- Tap "Confirm Match" on suggested item → moves to auto-matched section
- Tap "Edit" on item → inline editor opens, user edits name → saves
- Tap "Add 4 Items" → success toast shown, navigate to Inventory
- Tap "Cancel" → confirmation dialog shown, discard session

**Integration Tests:**

- End-to-end: Capture photo → detect items + OCR receipt → match → review → confirm → items in inventory
- Undo flow: Batch add 3 items → tap "Undo Batch" → items removed from inventory
- Receipt retention: Capture receipt → wait 31 days → receipt image auto-deleted

**Manual Smoke Tests:**

1. **Scenario: Perfect Capture (Ideal Conditions)**
   - Place 5 items + receipt on table under good lighting
   - Capture single photo
   - Verify 4–5 items auto-matched (≥80% score)
   - Bulk confirm → all items in inventory with correct prices
   - ✅ Pass

2. **Scenario: Partial Match (Mixed Confidence)**
   - 3 items + receipt, but 1 item partially obscured
   - Verify 2 items auto-matched, 1 suggested match (user confirms)
   - Edit suggested item name → verify match score recalculated
   - ✅ Pass

3. **Scenario: No Receipt (Items Only)**
   - Capture photo with items but no receipt visible
   - Verify items detected, all show "[No price]"
   - User can still add to inventory (price optional)
   - ✅ Pass

4. **Scenario: Poor Lighting (Edge Case)**
   - Capture photo in dim lighting
   - Verify detection confidence lower, more items in "Needs Review"
   - User manually selects receipt lines for unmatched items
   - ✅ Pass

5. **Scenario: Receipt Without Items (Receipt Only)**
   - Capture photo with receipt but no items visible
   - Verify OCR extracts line items, but no items to match
   - Prompt user: "No items detected. Capture items separately or try again."
   - ✅ Pass

6. **Scenario: Multi-Photo Mode (Fallback)**
   - Capture items photo first, then receipt photo
   - Verify system links by session, runs matching as normal
   - ✅ Pass

7. **Scenario: Privacy Controls**
   - Disable "Store Receipt Images" in Settings
   - Capture batch → verify receipt processed but not persisted
   - Re-enable setting → verify next capture persists receipt
   - ✅ Pass

---

## Out of scope

- **Real-time streaming detection:** Single-shot capture only (not live camera feed)
- **Barcode scanning integration:** Separate feature (defer to future)
- **Multi-language OCR:** English-only for MVP (defer to M7)
- **Cloud receipt storage:** Local storage only (30-day retention)
- **Receipt history/archive:** View past receipts (defer to future)
- **Price comparison:** Cross-store price analytics (defer to future)
- **Automatic expiry prediction:** Expiry date manual entry only (defer to M7)
- **Loyalty card integration:** Import receipts from retailer APIs (defer to future)
- **Fine-tuning on user data:** ML model ships pre-trained only (no on-device learning)

---

## Implementation notes

### Architecture

**Layers:**

1. **Domain Layer:**
   - `BatchCaptureService`: Orchestrates CV + OCR + matching
   - `ItemDetector`: Computer vision pipeline (TensorFlow Lite or cloud API)
   - `ReceiptOcrService`: OCR pipeline (Google Cloud Vision API, AWS Textract, or Tesseract)
   - `MatchingAlgorithm`: Score and pair items with receipt lines

2. **Data Layer:**
   - `BatchCaptureRepository`: Persist capture sessions, match metadata, receipt images
   - `ReceiptImageStore`: Encrypted local storage with 30-day auto-deletion
   - `ItemRepository`: Create inventory items from confirmed matches

3. **Presentation Layer:**
   - `BatchCaptureScreen`: Camera view with capture instructions
   - `BatchReviewScreen`: Unified review UI with match status
   - `ItemEditModal`: Inline editor for item details
   - `ReceiptViewModal`: Full receipt image viewer

### Technology Stack

**Computer Vision (Item Detection):**

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **TensorFlow Lite (On-Device)** | Fast, private, offline | Requires pre-trained model, lower accuracy | ✅ **Preferred** for Free/Pro tiers |
| **Google Cloud Vision API** | High accuracy, easy integration | Cost per request, requires internet | Use for Pro+ tier or fallback |
| **AWS Rekognition** | High accuracy, scalable | Cost per request, AWS lock-in | Alternative to Cloud Vision |
| **Custom YOLO Model** | Best accuracy with fine-tuning | Requires labeled dataset + training | Defer to M7 (advanced ML) |

**OCR (Receipt Parsing):**

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| **Google Cloud Vision API** | Best accuracy for receipts | $1.50/1000 requests | ✅ **Preferred** for Pro tier |
| **AWS Textract** | Good accuracy, invoice parsing | $1.50/1000 requests | Alternative to Cloud Vision |
| **Tesseract (On-Device)** | Free, private, offline | Lower accuracy on receipts | Use as fallback or Free tier |
| **Mindee Receipt OCR API** | Receipt-specialized | $0.50/request (higher cost) | Consider for Pro+ tier |

**Recommended Stack for MVP:**
- **CV:** TensorFlow Lite with MobileNet SSD (on-device, free)
- **OCR:** Google Cloud Vision API (pay-per-use, gated behind Pro tier)
- **Matching:** Local algorithm (no external API)

### Matching Algorithm Pseudocode

```python
def match_items_to_receipt(detected_items, receipt_lines):
    """
    Match detected items to receipt line items using multi-factor scoring.
    Returns list of (item, receipt_line, score) tuples.
    """
    matches = []
    
    # Compute all pairwise scores
    scores = []
    for item in detected_items:
        for line in receipt_lines:
            name_sim = compute_name_similarity(item.name, line.name)
            spatial = compute_spatial_proximity(item.bbox, line.position)
            confidence = (item.confidence + line.confidence) / 2
            
            score = (0.7 * name_sim) + (0.2 * spatial) + (0.1 * confidence)
            scores.append((item, line, score))
    
    # Sort by score descending
    scores.sort(key=lambda x: x[2], reverse=True)
    
    # Greedy matching (1:1 constraint)
    used_items = set()
    used_lines = set()
    
    for item, line, score in scores:
        if item in used_items or line in used_lines:
            continue  # Already matched
        
        if score >= 0.80:
            matches.append((item, line, score, "auto"))
        elif score >= 0.60:
            matches.append((item, line, score, "suggested"))
        # else: no match (user must manually select)
        
        used_items.add(item)
        used_lines.add(line)
    
    # Add unmatched items
    for item in detected_items:
        if item not in used_items:
            matches.append((item, None, 0.0, "manual"))
    
    return matches


def compute_name_similarity(name1, name2):
    """Fuzzy string matching using Levenshtein + token overlap."""
    # Normalize
    n1 = name1.lower().strip()
    n2 = name2.lower().strip()
    
    # Exact match
    if n1 == n2:
        return 1.0
    
    # Token overlap
    tokens1 = set(n1.split())
    tokens2 = set(n2.split())
    overlap = len(tokens1 & tokens2) / max(len(tokens1), len(tokens2))
    
    # Levenshtein distance
    lev_distance = levenshtein(n1, n2)
    max_len = max(len(n1), len(n2))
    lev_sim = 1.0 - (lev_distance / max_len)
    
    # Combine (weighted average)
    return (0.6 * lev_sim) + (0.4 * overlap)


def compute_spatial_proximity(item_bbox, receipt_line_position):
    """
    Calculate spatial proximity between item and receipt line.
    Returns 1.0 if close, 0.0 if far apart.
    """
    if receipt_line_position is None:
        return 0.0  # Receipt not visible
    
    item_center_y = item_bbox.y + (item_bbox.height / 2)
    line_y = receipt_line_position.y
    
    # Distance in pixels
    distance = abs(item_center_y - line_y)
    
    # Normalize by image height (assume 1000px height)
    normalized_distance = distance / 1000.0
    
    # Inverse relationship (closer = higher score)
    proximity = max(0.0, 1.0 - normalized_distance)
    return proximity
```

### Cost Estimates (Per Batch Capture)

**Assuming Pro tier with Google Cloud Vision API:**

| Service | Cost per Request | Requests per Capture | Cost per Capture |
|---------|------------------|----------------------|------------------|
| **Object Detection (CV)** | $1.50/1000 | 1 | $0.0015 |
| **OCR (Receipt)** | $1.50/1000 | 1 | $0.0015 |
| **Total per Capture** | — | 2 | **$0.003** |

**Monthly costs for Pro user (10 batch captures/month):**
- 10 captures × $0.003 = **$0.03/month**

**Margin analysis (if Pro = $4.99/mo):**
- Gross margin: $4.99 - $0.03 = **$4.96/mo** (99.4% margin) ✅

**Optimization:** Use on-device TensorFlow Lite for CV → reduces cost to $0.0015/capture (OCR only).

### Privacy & Data Handling

**Principles:**
1. **Local-first:** All processing happens on-device or via encrypted API calls
2. **Ephemeral receipts:** Stored locally for 30 days, then auto-deleted
3. **User control:** Opt-out toggle in Settings ("Store Receipt Images")
4. **No cloud storage:** Receipt images never leave device (unless user explicitly exports backup)
5. **GDPR/CCPA compliance:** User can delete all receipt history via Settings → Privacy → Delete Receipt History

**Receipt Image Encryption:**
- Use `flutter_secure_storage` to encrypt images at rest
- Encryption key stored in device keychain (iOS) or Keystore (Android)
- Images inaccessible to other apps or backup services

### Future Enhancements (M7+)

- **Real-time streaming detection:** Live camera feed with bounding boxes (like AR)
- **Multi-language OCR:** Support receipts in Spanish, French, Chinese, etc.
- **Automatic expiry prediction:** ML model predicts expiry date from item type + purchase date
- **Receipt history:** Archive and search past receipts
- **Price comparison:** "Milk is $0.50 cheaper at Store B last month"
- **Loyalty card integration:** Import receipts directly from retailer APIs (Instacart, Walmart, Amazon Fresh)
- **Fine-tuning on user data:** Personalized item detection based on user's purchase history
- **Barcode fallback:** If CV fails, suggest barcode scan

---

## Dependencies

**Hard Dependencies (Must Complete First):**
- **430:** Batch item detection POC (CV pipeline)
- **440:** OCR integration spike (provider selection + accuracy baseline)
- **450:** Receipt parsing with normalized line items
- **460:** Receipt review UI (base components for unified review)

**Soft Dependencies (Can Run in Parallel):**
- **130:** Feature flags (gate behind Pro tier + feature flag for gradual rollout)
- **410:** Subscription strategy (ensure Pro tier billing active)
- **500:** Consent model (privacy disclosure for image processing)

**Integration Points:**
- **Item Repository:** Create inventory items with cost tracking
- **Telemetry Service:** Emit batch capture events
- **Settings:** Privacy toggles for receipt storage

---

## Rollout Strategy

**Phase 1: Internal Alpha (M6 Early)**
- Enable for internal team only (feature flag)
- Test with 20–30 batch captures across different stores/lighting conditions
- Collect accuracy metrics and failure modes
- Iterate on matching algorithm thresholds

**Phase 2: Pro Beta (M6 Mid)**
- Enable for Pro tier subscribers (opt-in via Settings)
- Limit to 5 batch captures/week (throttle API costs)
- Collect telemetry: `auto_match_rate`, `user_edit_rate`, `time_saved_vs_manual`
- Monitor API costs and latency

**Phase 3: Pro GA (M6 Launch)**
- Enable for all Pro tier users
- Remove weekly capture limit
- Promote in app: "New: Batch Capture with Auto-Matching!"
- Measure conversion: Free → Pro upgrades driven by batch capture

**Phase 4: Optimization (M7)**
- Analyze telemetry to improve matching algorithm
- Add synonym dictionary from real user data
- Optimize on-device models for faster inference
- Expand to Free tier with limited captures (2/month)

---

## Success Metrics

**Adoption:**
- % of Pro users who use batch capture at least once (target: 80%)
- Average batch captures per Pro user per month (target: 8–10)

**Accuracy:**
- Auto-match rate (% of items matched with ≥80% confidence, target: 70%)
- User edit rate (% of auto-matched items user manually edits, target: <15%)
- Capture success rate (% of captures that result in ≥1 item added, target: 95%)

**Efficiency:**
- Time saved vs manual entry (target: 5 minutes → 30 seconds = 10x faster)
- Items added per capture (target: 4–6 items average)

**Retention:**
- Pro tier churn rate for users who use batch capture vs those who don't (expect -30% churn)
- NPS score for batch capture feature (target: ≥50)

**Revenue:**
- Free → Pro conversion rate driven by batch capture CTAs (track in-app prompts)
- Pro ARPU increase from users who discover batch capture

---

## Risk Mitigation

**Risk 1: Low Matching Accuracy**
- **Mitigation:** Set conservative auto-match threshold (≥80%), fallback to manual review
- **Contingency:** If <50% auto-match rate, disable feature and iterate on algorithm

**Risk 2: High API Costs**
- **Mitigation:** Use on-device TF Lite for CV; OCR gated behind Pro tier
- **Contingency:** Implement weekly capture limits (10/user/week) + throttling

**Risk 3: Privacy Concerns**
- **Mitigation:** Clear consent flow, local-only storage, 30-day auto-deletion
- **Contingency:** Add opt-out toggle + "Delete Receipt History" action

**Risk 4: Poor Performance (Latency)**
- **Mitigation:** Run CV + OCR in parallel, optimize model inference
- **Contingency:** Show progress spinner with steps ("Detecting items... Scanning receipt...")

**Risk 5: User Frustration (Low Detection Rate)**
- **Mitigation:** Instructional overlay in capture view ("Place items on flat surface, good lighting")
- **Contingency:** Provide "Retake Photo" and "Add Manually" fallbacks

---

## Competitive Analysis

**Existing Apps (as of March 2026):**

| App | Batch Capture? | Receipt OCR? | Auto-Matching? | Price |
|-----|----------------|--------------|----------------|-------|
| **NoWaste** | ✅ Yes | ✅ Yes | ❌ No | $4.99/mo |
| **FridgePal** | ❌ No | ✅ Yes | ❌ No | Free |
| **Grocy** | ❌ No | ❌ No | ❌ No | Free |
| **SaveTheFood** | ❌ No | ❌ No | ❌ No | Free |
| **ZeroSpoils (This)** | ✅ Yes | ✅ Yes | **✅ Yes** | $4.99/mo |

**Competitive Moat:** ZeroSpoils is the **first app to auto-match items to receipt prices**. This is a 2–3 year lead if executed well.

---

## Notes for Implementation

> **This is the signature feature.** Invest engineering time to get matching accuracy ≥70%. Users will tolerate some manual corrections if the workflow is still 10x faster than manual entry.
>
> **Prioritize UX polish:**
> - Smooth animations (loading spinner, item card reveal)
> - Clear visual indicators (match confidence)
> - Delightful success feedback ("✅ 5 items added — saved ~7 minutes!")
>
> **Measure everything:**
> - Track auto-match rate per user, per store, per lighting condition
> - A/B test match thresholds (70% vs 80% for auto-match)
> - Monitor API costs daily (set budget alerts at $50/day)
>
> **Marketing angle:** "Grocery shopping just got 10x easier. Snap a photo, we do the rest."

---

**This is your competitive moat. Build it well, and users will never switch.**
